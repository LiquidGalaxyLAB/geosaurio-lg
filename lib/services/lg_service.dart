import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dinosaur.dart';
import 'dinosaur_service.dart';

class LgConnectionModel {
  String username;
  String ip;
  int port;
  String password;
  int screens;

  static const String _keyUsername = 'lg_username';
  static const String _keyIp = 'lg_ip';
  static const String _keyPort = 'lg_port';
  static const String _keyPassword = 'lg_password';
  static const String _keyScreens = 'lg_screens';

  LgConnectionModel({
    this.username = 'lg',
    this.ip = '',
    this.port = 22,
    this.password = 'lqgalaxy',
    this.screens = 5,
  });

  void updateConnection({
    String? username,
    String? ip,
    int? port,
    String? password,
    int? screens,
  }) {
    this.username = username ?? this.username;
    this.ip = ip ?? this.ip;
    this.port = port ?? this.port;
    this.password = password ?? this.password;
    this.screens = screens ?? this.screens;
  }

  Future<void> saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyIp, ip);
    await prefs.setInt(_keyPort, port);
    await prefs.setString(_keyPassword, password);
    await prefs.setInt(_keyScreens, screens);
  }

  static Future<LgConnectionModel> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return LgConnectionModel(
      username: prefs.getString(_keyUsername) ?? 'lg',
      ip: prefs.getString(_keyIp) ?? '',
      port: prefs.getInt(_keyPort) ?? 22,
      password: prefs.getString(_keyPassword) ?? 'lqgalaxy',
      screens: prefs.getInt(_keyScreens) ?? 5,
    );
  }
}

class LgService extends ChangeNotifier {
  LgService._internal();

  static final LgService _singleton = LgService._internal();

  factory LgService() => _singleton;

  final LgConnectionModel _lgConnectionModel = LgConnectionModel();

  SSHClient? _client;
  bool _isConnected = false;
  int _currentConnectionAttempts = 0;

  // Prevents two SSH authentication attempts from running at the same time.
  Future<bool?>? _connectionInProgress;

  // Prevents the automatic logo/marker setup from recursively starting again
  // when execute() has to reconnect.
  bool _initializingAfterConnection = false;

  static const int _maxConnectionAttempts = 5;
  static const Duration _connectionTimeout = Duration(seconds: 10);

  LgConnectionModel get connectionModel => _lgConnectionModel;

  bool get isConnected => _isConnected;

  void updateConnectionSettings({
    required String ip,
    required int port,
    required String username,
    required String password,
    required int screens,
  }) {
    _lgConnectionModel.updateConnection(
      ip: ip,
      port: port,
      username: username,
      password: password,
      screens: screens,
    );
  }

  Future<void> initializeConnection() async {
    try {
      final savedModel = await LgConnectionModel.loadFromPreferences();

      updateConnectionSettings(
        ip: savedModel.ip,
        port: savedModel.port,
        username: savedModel.username,
        password: savedModel.password,
        screens: savedModel.screens,
      );

      await connectToLG();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<bool?> connectToLG({
    bool initializeAfterConnect = true,
  }) async {
    // Reuse the same pending authentication instead of opening another socket.
    final pendingConnection = _connectionInProgress;
    if (pendingConnection != null) {
      final connected = await pendingConnection;

      if (connected == true &&
          initializeAfterConnect &&
          !_initializingAfterConnection) {
        await _initializeLiquidGalaxyContent();
      }

      return connected;
    }

    if (_client != null && _isConnected) {
      if (initializeAfterConnect && !_initializingAfterConnection) {
        await _initializeLiquidGalaxyContent();
      }

      return true;
    }

    final future = _openSshConnection();
    _connectionInProgress = future;

    try {
      final connected = await future;

      if (connected == true &&
          initializeAfterConnect &&
          !_initializingAfterConnection) {
        await _initializeLiquidGalaxyContent();
      }

      return connected;
    } finally {
      if (identical(_connectionInProgress, future)) {
        _connectionInProgress = null;
      }
    }
  }

  Future<bool?> _openSshConnection() async {
    if (_currentConnectionAttempts >= _maxConnectionAttempts) {
      _currentConnectionAttempts = 0;
      notifyListeners();
      return false;
    }

    SSHClient? newClient;

    try {
      debugPrint('Opening SSH connection...');

      final socket = await SSHSocket.connect(
        _lgConnectionModel.ip,
        _lgConnectionModel.port,
      ).timeout(_connectionTimeout);

      newClient = SSHClient(
        socket,
        username: _lgConnectionModel.username,
        onPasswordRequest: () => _lgConnectionModel.password,
        keepAliveInterval: const Duration(seconds: 10),
      );

      // SSHClient authenticates lazily. Running a harmless command here forces
      // authentication to finish before SFTP, logos or markers are started.
      await newClient.run('true').timeout(_connectionTimeout);

      _client?.close();
      _client = newClient;
      _isConnected = true;
      _currentConnectionAttempts = 0;

      debugPrint('SSH authentication completed');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Connection/authentication error: $e');
      debugPrint('$stackTrace');

      newClient?.close();

      _client = null;
      _isConnected = false;
      _currentConnectionAttempts++;
      notifyListeners();

      return false;
    }
  }

  Future<void> _setRefreshInterval(
      int screenNumber,
      int interval,
      ) async {
    try {
      final search =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>';

      final replace =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>'
          '<refreshMode>onInterval<\\/refreshMode>'
          '<refreshInterval>$interval<\\/refreshInterval>';

      final command =
          'echo ${_lgConnectionModel.password} | sudo -S '
          'sed -i "s|$search|$replace|" '
          '~/earth/kml/slave/myplaces.kml';

      await execute(
        'sshpass -p ${_lgConnectionModel.password} '
            'ssh -t lg$screenNumber \'$command\'',
        'Added refresh interval to screen $screenNumber',
      );
    } catch (e) {
      debugPrint(
        'Error setting refresh interval: $e',
      );
    }
  }

  Future<void> _removeRefreshInterval(
      int screenNumber,
      ) async {
    try {
      final search =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>'
          '<refreshMode>onInterval<\\/refreshMode>'
          '<refreshInterval>[0-9]+<\\/refreshInterval>';

      final replace =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>';

      final command =
          'echo ${_lgConnectionModel.password} | sudo -S '
          'sed -i "s|$search|$replace|" '
          '~/earth/kml/slave/myplaces.kml';

      await execute(
        'sshpass -p ${_lgConnectionModel.password} '
            'ssh -t lg$screenNumber \'$command\'',
        'Removed refresh interval from screen $screenNumber',
      );
    } catch (e) {
      debugPrint(
        'Error removing refresh interval: $e',
      );
    }
  }

  Future<void> _forceRefresh(
      int screenNumber,
      ) async {
    try {
      await _setRefreshInterval(
        screenNumber,
        2,
      );

      await _removeRefreshInterval(
        screenNumber,
      );
    } catch (e) {
      debugPrint(
        'Error during force refresh: $e',
      );
    }
  }

  Future<void> _initializeLiquidGalaxyContent() async {
    if (_initializingAfterConnection ||
        !_isConnected ||
        _client == null) {
      return;
    }

    _initializingAfterConnection = true;

    try {
      await Future.delayed(
        const Duration(seconds: 2),
      );

      debugPrint('Sending logo');

      final logoSent = await sendLogo();

      debugPrint(
        'Logo result: $logoSent',
      );

      debugPrint(
        'Connection initialization completed',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Error initializing Liquid Galaxy content: $e',
      );

      debugPrint('$stackTrace');
    } finally {
      _initializingAfterConnection = false;
    }
  }

  void disconnect() {
    _client?.close();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<dynamic> execute(String command, String successMessage) async {
    if (_client == null || !_isConnected) {
      debugPrint('SSH client not connected. Trying reconnect...');

      final connected = await connectToLG(
        initializeAfterConnect: false,
      );

      if (connected != true || _client == null) {
        debugPrint('Reconnect failed');
        return null;
      }
    }

    try {
      final result = await _client!.execute(command);
      debugPrint(successMessage);
      return result;
    } catch (e, stackTrace) {
      debugPrint('Command error: $e');
      debugPrint('$stackTrace');

      final failedClient = _client;
      _client = null;
      _isConnected = false;
      failedClient?.close();
      notifyListeners();

      debugPrint('Trying reconnect after command error...');

      final connected = await connectToLG(
        initializeAfterConnect: false,
      );

      if (connected != true || _client == null) {
        debugPrint('Reconnect after command error failed');
        return null;
      }

      try {
        final retryResult = await _client!.execute(command);
        debugPrint('$successMessage after reconnect');
        return retryResult;
      } catch (retryError, retryStackTrace) {
        debugPrint('Retry command error: $retryError');
        debugPrint('$retryStackTrace');
        return null;
      }
    }
  }

  int calculateLeftMostScreen(int screenCount) {
    return screenCount == 1 ? 1 : (screenCount / 2).floor() + 2;
  }

  int calculateRightMostScreen(int screenCount) {
    return screenCount == 1 ? 1 : (screenCount / 2).floor() + 1;
  }

  String cleanDinosaurImageName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[ \s\u00A0]+'), '_')
        .replaceAll('.', '')
        .replaceAll('?', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('-', '_')
        .replaceAll('__', '_');
  }

  Future<bool> writeSoloKml(
      int machineNo,
      String kml,
      ) async {
    final result = await execute(
      "echo '$kml' > /var/www/html/kml/slave_$machineNo.kml",
      'Solo KML written to slave_$machineNo.kml',
    );

    return result != null;
  }

  Future<bool> notifySoloKmlChanged(
      int machineNo,
      ) async {
    try {
      await _forceRefresh(machineNo);
      return true;
    } catch (e) {
      debugPrint(
        'Error notifying Solo KML change: $e',
      );
      return false;
    }
  }

  Future<String?> getExistingImagePath(String basePath) async {
    final extensions = ['.png', '.jpg', '.jpeg'];

    final variants = <String>{basePath, basePath.toLowerCase()};

    if (basePath.contains('_')) {
      final lastUnderscore = basePath.lastIndexOf('_');
      final prefix = basePath.substring(0, lastUnderscore);
      final suffix = basePath.substring(lastUnderscore);

      variants.add('$prefix $suffix');
      variants.add('${prefix.toLowerCase()} $suffix');

      if (suffix.contains('comparis')) {
        final otherSuffix = suffix.contains('comparison')
            ? suffix.replaceFirst('comparison', 'comparision')
            : suffix.replaceFirst('comparision', 'comparison');

        variants.add('$prefix$otherSuffix');
        variants.add('${prefix.toLowerCase()}$otherSuffix');
        variants.add('$prefix $otherSuffix');
        variants.add('${prefix.toLowerCase()} $otherSuffix');
      }
    }

    for (final variant in variants) {
      for (final ext in extensions) {
        final path = '$variant$ext';

        try {
          await rootBundle.load(path);
          debugPrint('Found: $path');
          return path;
        } catch (_) {}
      }
    }

    debugPrint('Image not found: $basePath');
    return null;
  }

  Future<bool> uploadAssetToLG({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final connected = await connectToLG(
        initializeAfterConnect: false,
      );

      if (connected != true || _client == null) {
        debugPrint(
          'Cannot upload $fileName: SSH is not connected',
        );
        return false;
      }

      final bytes = await rootBundle.load(assetPath);

      // Local temporary file.
      // We only use the final filename locally so paths such as
      // "kml/dino_marker.png" do not require creating temporary folders.
      final tempDir = await getTemporaryDirectory();

      final localFileName = fileName.split('/').last;

      final file = File(
        '${tempDir.path}/$localFileName',
      );

      await file.writeAsBytes(
        bytes.buffer.asUint8List(),
      );

      final sftp = await _client!.sftp();

      // Remote path CAN contain folders.
      // Example:
      // fileName = kml/dino_marker.png
      // ->
      // /var/www/html/kml/dino_marker.png
      final remotePath = '/var/www/html/$fileName';

      debugPrint(
        'Uploading $assetPath to $remotePath',
      );

      final remoteFile = await sftp.open(
        remotePath,
        mode:
        SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(
        Stream.value(
          Uint8List.fromList(
            await file.readAsBytes(),
          ),
        ),
      );

      await remoteFile.close();

      debugPrint(
        'Asset uploaded successfully to $remotePath',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error uploading $assetPath as $fileName: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<bool> uploadBytesToLG({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final connected = await connectToLG(
        initializeAfterConnect: false,
      );

      if (connected != true || _client == null) {
        debugPrint('Cannot upload $fileName: SSH is not connected');
        return false;
      }

      final sftp = await _client!.sftp();

      final remoteFile = await sftp.open(
        '/var/www/html/$fileName',
        mode:
        SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(Stream.value(bytes));

      await remoteFile.close();

      return true;
    } catch (e) {
      debugPrint('Error uploading bytes: $e');
      return false;
    }
  }

  String _cleanText(String value) {
    return value
        .replaceAll('&', 'and')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .trim();
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .trim();
  }

  Future<bool> createDinosaurInfoColumn(
      Dinosaur dinosaur,
      String fileName,
      ) async {
    try {
      const double width = 1000;
      const double height = 1900;
      const double padding = 70;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Background
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFF181818);

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(
            0,
            0,
            width,
            height,
          ),
          const ui.Radius.circular(40),
        ),
        backgroundPaint,
      );

      double currentY = 60;

      // Helper method for wrapped text
      double drawText({
        required String text,
        required double fontSize,
        required double y,
        ui.FontWeight fontWeight = ui.FontWeight.normal,
        ui.Color color = const ui.Color(0xFFFFFFFF),
        double maxWidth = width - (padding * 2),
        double lineHeight = 1.3,
        ui.TextAlign textAlign = ui.TextAlign.left,
      }) {
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: textAlign,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: lineHeight,
          ),
        )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          )
          ..addText(text);

        final paragraph = builder.build();

        paragraph.layout(
          ui.ParagraphConstraints(
            width: maxWidth,
          ),
        );

        canvas.drawParagraph(
          paragraph,
          ui.Offset(
            padding,
            y,
          ),
        );

        return paragraph.height;
      }

      // --------------------------------------------------
      // DINOSAUR NAME
      // --------------------------------------------------

      currentY += drawText(
        text: dinosaur.name.toUpperCase(),
        fontSize: 60,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        textAlign: ui.TextAlign.center,
      );

      currentY += 30;

      // Separator
      final separatorPaint = ui.Paint()
        ..color = const ui.Color(0xFF8D6E63)
        ..strokeWidth = 5;

      canvas.drawLine(
        ui.Offset(
          padding,
          currentY,
        ),
        ui.Offset(
          width - padding,
          currentY,
        ),
        separatorPaint,
      );

      currentY += 35;

      // --------------------------------------------------
      // OPTIONAL DINOSAUR IMAGE
      // --------------------------------------------------

      final cleanName = cleanDinosaurImageName(
        dinosaur.name,
      );

      final dinosaurImagePath = await getExistingImagePath(
        'assets/images/dinosaurs/${cleanName}_normal',
      );

      ui.Image? dinosaurImage;

      if (dinosaurImagePath != null) {
        try {
          final data = await rootBundle.load(
            dinosaurImagePath,
          );

          final bytes = data.buffer.asUint8List();

          final codec = await ui.instantiateImageCodec(
            bytes,
          );

          final frame = await codec.getNextFrame();

          dinosaurImage = frame.image;

          debugPrint(
            'Dinosaur image added to info column: '
                '$dinosaurImagePath',
          );
        } catch (e) {
          debugPrint(
            'Could not load dinosaur image for column: $e',
          );
        }
      }

      if (dinosaurImage != null) {
        const double maxImageWidth = 760;
        const double maxImageHeight = 430;

        final originalWidth =
        dinosaurImage.width.toDouble();

        final originalHeight =
        dinosaurImage.height.toDouble();

        final scale = math.min(
          maxImageWidth / originalWidth,
          maxImageHeight / originalHeight,
        );

        final imageWidth =
            originalWidth * scale;

        final imageHeight =
            originalHeight * scale;

        final imageX =
            (width - imageWidth) / 2;

        final sourceRect = ui.Rect.fromLTWH(
          0,
          0,
          originalWidth,
          originalHeight,
        );

        final destinationRect =
        ui.Rect.fromLTWH(
          imageX,
          currentY,
          imageWidth,
          imageHeight,
        );

        canvas.drawImageRect(
          dinosaurImage,
          sourceRect,
          destinationRect,
          ui.Paint(),
        );

        currentY += imageHeight + 40;
      }

      // --------------------------------------------------
      // PERIOD
      // --------------------------------------------------

      currentY += drawText(
        text: 'Period',
        fontSize: 32,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: const ui.Color(0xFFD7CCC8),
      );

      currentY += 5;

      currentY += drawText(
        text: dinosaur.periodName,
        fontSize: 38,
        y: currentY,
      );

      currentY += 25;

      // --------------------------------------------------
      // DIET
      // --------------------------------------------------

      currentY += drawText(
        text: 'Diet',
        fontSize: 32,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: const ui.Color(0xFFD7CCC8),
      );

      currentY += 5;

      currentY += drawText(
        text: dinosaur.diet.isEmpty
            ? 'Unknown'
            : dinosaur.diet,
        fontSize: 38,
        y: currentY,
      );

      currentY += 25;

      // --------------------------------------------------
      // LENGTH
      // --------------------------------------------------

      currentY += drawText(
        text: 'Length',
        fontSize: 32,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: const ui.Color(0xFFD7CCC8),
      );

      currentY += 5;

      currentY += drawText(
        text: dinosaur.length.isEmpty
            ? 'Unknown'
            : dinosaur.length,
        fontSize: 38,
        y: currentY,
      );

      currentY += 25;

      // --------------------------------------------------
      // WEIGHT
      // --------------------------------------------------

      currentY += drawText(
        text: 'Weight',
        fontSize: 32,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: const ui.Color(0xFFD7CCC8),
      );

      currentY += 5;

      currentY += drawText(
        text: dinosaur.weight.isEmpty
            ? 'Unknown'
            : dinosaur.weight,
        fontSize: 38,
        y: currentY,
      );

      currentY += 25;

      // --------------------------------------------------
      // HABITAT
      // --------------------------------------------------

      currentY += drawText(
        text: 'Habitat',
        fontSize: 32,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: const ui.Color(0xFFD7CCC8),
      );

      currentY += 5;

      currentY += drawText(
        text: dinosaur.habitat.isEmpty
            ? 'Unknown'
            : dinosaur.habitat,
        fontSize: 36,
        y: currentY,
      );

      currentY += 25;

      // --------------------------------------------------
      // LOCATION
      // --------------------------------------------------

      currentY += drawText(
        text: 'Location',
        fontSize: 32,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: const ui.Color(0xFFD7CCC8),
      );

      currentY += 5;

      final location = [
        dinosaur.region,
        dinosaur.country,
      ]
          .where(
            (value) => value.trim().isNotEmpty,
      )
          .join(', ');

      currentY += drawText(
        text: location.isEmpty
            ? 'Unknown'
            : location,
        fontSize: 36,
        y: currentY,
      );

      currentY += 35;

      // --------------------------------------------------
      // ABOUT SEPARATOR
      // --------------------------------------------------

      canvas.drawLine(
        ui.Offset(
          padding,
          currentY,
        ),
        ui.Offset(
          width - padding,
          currentY,
        ),
        separatorPaint,
      );

      currentY += 35;

      // --------------------------------------------------
      // ABOUT
      // --------------------------------------------------

      currentY += drawText(
        text: 'About',
        fontSize: 38,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: const ui.Color(0xFFD7CCC8),
      );

      currentY += 12;

      drawText(
        text: dinosaur.generalInfo.isEmpty
            ? 'No additional information available.'
            : dinosaur.generalInfo,
        fontSize: 31,
        y: currentY,
        lineHeight: 1.4,
      );

      // --------------------------------------------------
      // CONVERT CANVAS TO PNG
      // --------------------------------------------------

      final picture =
      recorder.endRecording();

      final image =
      await picture.toImage(
        width.toInt(),
        height.toInt(),
      );

      final byteData =
      await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint(
          'Could not generate dinosaur info column image',
        );

        return false;
      }

      final bytes =
      byteData.buffer.asUint8List();

      // --------------------------------------------------
      // UPLOAD PNG TO LIQUID GALAXY
      // --------------------------------------------------

      final uploaded =
      await uploadBytesToLG(
        bytes: bytes,
        fileName: fileName,
      );

      if (!uploaded) {
        debugPrint(
          'Could not upload dinosaur info column',
        );

        return false;
      }

      debugPrint(
        'Dinosaur info column created and uploaded: '
            '$fileName',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error creating dinosaur info column: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }

  Future<bool> showDinosaurAboutColumn(Dinosaur dinosaur) async {
    try {
      final screen = calculateRightMostScreen(
        _lgConnectionModel.screens,
      );

      final imageFileName =
          '${cleanDinosaurImageName(dinosaur.name)}_info.png';

      final created = await createDinosaurInfoColumn(
        dinosaur,
        imageFileName,
      );

      if (!created) {
        debugPrint('Could not create dinosaur information column');
        return false;
      }

      final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>

    <ScreenOverlay>
      <name>${_cleanText(dinosaur.name)} Information</name>

      <Icon>
        <href>http://lg1:81/$imageFileName</href>
      </Icon>

      <overlayXY
        x="0.5"
        y="0.5"
        xunits="fraction"
        yunits="fraction"
      />

      <screenXY
        x="0.5"
        y="0.5"
        xunits="fraction"
        yunits="fraction"
      />

      <size
        x="850"
        y="0"
        xunits="pixels"
        yunits="pixels"
      />

    </ScreenOverlay>

  </Document>
</kml>
''';

      await cleanRightScreenKml();

      final result = await execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Dinosaur information column sent',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint('Error showing dinosaur information column: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> flyToDinosaur(Dinosaur dinosaur) async {
    try {
      if (dinosaur.longitude == 0 || dinosaur.latitude == 0) return false;

      final lookAt =
          '<LookAt>'
          '<longitude>${dinosaur.longitude}</longitude>'
          '<latitude>${dinosaur.latitude}</latitude>'
          '<altitude>${dinosaur.altitude}</altitude>'
          '<heading>${dinosaur.heading}</heading>'
          '<tilt>${dinosaur.tilt}</tilt>'
          '<range>${dinosaur.range == 0 ? 8000 : dinosaur.range}</range>'
          '<altitudeMode>${dinosaur.altitudeMode}</altitudeMode>'
          '</LookAt>';

      final command = "echo 'flytoview=$lookAt' > /tmp/query.txt";
      final result = await execute(command, 'FlyTo sent');

      return result != null;
    } catch (e) {
      debugPrint('Error flying to dinosaur: $e');
      return false;
    }
  }

  final Map<String, List<double>> _continentViews = {
    'Africa': [20.0, 0.0, 7000000],
    'Asia': [95.0, 35.0, 8000000],
    'Europe': [15.0, 50.0, 5000000],
    'North America': [-100.0, 45.0, 7000000],
    'South America': [-60.0, -15.0, 7000000],
    'Oceania': [135.0, -25.0, 6000000],
    'Antarctica': [0.0, -82.0, 6000000],
  };

  Future<bool> flyToContinent(String continent) async {
    try {
      final view = _continentViews[continent];

      if (view == null) return false;

      final lookAt =
          '<LookAt>'
          '<longitude>${view[0]}</longitude>'
          '<latitude>${view[1]}</latitude>'
          '<altitude>0</altitude>'
          '<heading>0</heading>'
          '<tilt>0</tilt>'
          '<range>${view[2]}</range>'
          '<altitudeMode>relativeToGround</altitudeMode>'
          '</LookAt>';

      final result = await execute(
        "echo 'flytoview=$lookAt' > /tmp/query.txt",
        'FlyTo continent sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error flying to continent: $e');
      return false;
    }
  }

  Future<bool> flyToCountry(String country, List<Dinosaur> dinosaurs) async {
    try {
      final validDinosaurs = dinosaurs.where((dinosaur) {
        return dinosaur.latitude != 0 && dinosaur.longitude != 0;
      }).toList();

      if (validDinosaurs.isEmpty) return false;

      final latitude =
          validDinosaurs
              .map((dinosaur) => dinosaur.latitude)
              .reduce((a, b) => a + b) /
              validDinosaurs.length;

      final longitude =
          validDinosaurs
              .map((dinosaur) => dinosaur.longitude)
              .reduce((a, b) => a + b) /
              validDinosaurs.length;

      final range = validDinosaurs.length <= 1 ? 250000 : 900000;

      final lookAt =
          '<LookAt>'
          '<longitude>$longitude</longitude>'
          '<latitude>$latitude</latitude>'
          '<altitude>0</altitude>'
          '<heading>0</heading>'
          '<tilt>0</tilt>'
          '<range>$range</range>'
          '<altitudeMode>relativeToGround</altitudeMode>'
          '</LookAt>';

      final result = await execute(
        "echo 'flytoview=$lookAt' > /tmp/query.txt",
        'FlyTo country sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error flying to country: $e');
      return false;
    }
  }

  Future<bool> showCountryMarkers(List<Dinosaur> dinosaurs) async {
    return showDinosaurMarkers(dinosaurs);
  }

  Future<bool> flyToEarth() async {
    try {
      const lookAt =
          '<LookAt>'
          '<longitude>0</longitude>'
          '<latitude>20</latitude>'
          '<altitude>0</altitude>'
          '<heading>0</heading>'
          '<tilt>0</tilt>'
          '<range>20000000</range>'
          '<altitudeMode>relativeToGround</altitudeMode>'
          '</LookAt>';

      final result = await execute(
        "echo 'flytoview=$lookAt' > /tmp/query.txt",
        'FlyTo Earth sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error flying to Earth: $e');
      return false;
    }
  }

  Future<void> showAllDinosaurMarkers() async {
    try {
      debugPrint('========== SHOW ALL DINOSAUR MARKERS ==========');

      final dinosaurs = await DinosaurService.loadDinosaurs();

      debugPrint(
        'CSV loaded for markers. Dinosaurs: ${dinosaurs.length}',
      );

      final ok = await showDinosaurMarkers(dinosaurs);

      debugPrint(
        'FINAL RESULT showDinosaurMarkers: $ok',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Error showing all dinosaur markers: $e',
      );
      debugPrint('$stackTrace');
    }
  }

  Future<bool> showDinosaurMarkers(List<Dinosaur> dinosaurs) async {
    try {
      final validDinosaurs = dinosaurs.where((dinosaur) {
        return dinosaur.latitude != 0 &&
            dinosaur.longitude != 0;
      }).toList();

      if (validDinosaurs.isEmpty) {
        debugPrint('No valid dinosaur coordinates');
        return false;
      }

      const double radius = 0.01;
      const double altitude = 1500.0;

      final placemarks = validDinosaurs.map((dinosaur) {
        final target = dinosaur.getMarkerCoordinates();

        final lat = target['latitude']!;
        final lon = target['longitude']!;

        final north = lat + radius;
        final south = lat - radius;
        final east = lon + radius;
        final west = lon - radius;

        debugPrint(
          '${dinosaur.name} -> camera: '
              '${dinosaur.latitude},${dinosaur.longitude} '
              'target: $lat,$lon',
        );

        return '''
<Placemark>
  <name>${_cleanText(dinosaur.name)}</name>
  <visibility>1</visibility>

  <Style>
    <PolyStyle>
      <color>cc0000ff</color>
      <fill>1</fill>
      <outline>1</outline>
    </PolyStyle>

    <LineStyle>
      <color>ff0000ff</color>
      <width>5</width>
    </LineStyle>
  </Style>

  <Polygon>
    <extrude>1</extrude>
    <altitudeMode>relativeToGround</altitudeMode>

    <outerBoundaryIs>
      <LinearRing>
        <coordinates>
          $west,$north,$altitude
          $east,$north,$altitude
          $east,$south,$altitude
          $west,$south,$altitude
          $west,$north,$altitude
        </coordinates>
      </LinearRing>
    </outerBoundaryIs>

  </Polygon>
</Placemark>
''';
      }).join('\n');

      final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">

  <Document>
    <name>GeoSaurio 3D Test</name>

    $placemarks

  </Document>

</kml>
''';

      for (int screen = 1;
      screen <= _lgConnectionModel.screens;
      screen++) {

        final result = await execute(
          "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
          '3D test KML sent to LG$screen',
        );

        if (result == null) {
          return false;
        }

        await _forceRefresh(screen);
      }

      debugPrint(
        '${validDinosaurs.length} 3D test objects sent',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error showing 3D test objects: $e',
      );
      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<bool> sendLogo() async {
    try {
      final screen = calculateLeftMostScreen(_lgConnectionModel.screens);

      final uploaded = await uploadAssetToLG(
        assetPath: 'assets/images/logos.png',
        fileName: 'logos.png',
      );

      if (!uploaded) return false;

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>http://lg1:81/logos.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.98" xunits="fraction" yunits="fraction"/>
      <size x="700" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';

      final result = await execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Logo sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error sending logo: $e');
      return false;
    }
  }

  Future<bool> showRightScreenImage({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final screen = calculateRightMostScreen(_lgConnectionModel.screens);

      final uploaded = await uploadAssetToLG(
        assetPath: assetPath,
        fileName: fileName,
      );

      if (!uploaded) return false;

      final kml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay>
      <name>Dino Image</name>
      <Icon>
        <href>http://lg1:81/$fileName</href>
      </Icon>
      <overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <size x="1000" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';

      final result = await execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Image sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return false;
    }
  }



  Future<bool> cleanKmlKeepingLogos() async {
    try {
      final logoScreen = calculateLeftMostScreen(_lgConnectionModel.screens);

      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';

      for (var i = 1; i <= _lgConnectionModel.screens; i++) {
        if (i == 1 || i == logoScreen) continue;

        await execute(
          "echo '$blankKml' > /var/www/html/kml/slave_$i.kml",
          'Cleaned KML screen $i',
        );
      }

      await execute(
        "echo '' > /var/www/html/kmls.txt",
        'Loaded geographic KMLs cleaned',
      );

      await execute(
        "echo '' > /tmp/query.txt",
        'Query cleaned',
      );

      return true;
    } catch (e) {
      debugPrint('Error cleaning KML keeping logos: $e');
      return false;
    }
  }

  Future<bool> cleanRightScreenKml() async {
    try {
      final screen = calculateRightMostScreen(_lgConnectionModel.screens);

      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty Right Screen</name>
  </Document>
</kml>''';

      final result = await execute(
        "echo '$blankKml' > /var/www/html/kml/slave_$screen.kml",
        'Right screen cleaned',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error cleaning right screen: $e');
      return false;
    }
  }

  Future<bool> showDinosaurSkeletonImage(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);

    final assetPath = await getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_skeleton',
    );

    if (assetPath == null) {
      debugPrint(
        'Skeleton image not found for ${dinosaur.name}',
      );
      return false;
    }

    final extension = assetPath.split('.').last;
    final imageFileName = '${cleanName}_skeleton.$extension';

    final uploadedImage = await uploadAssetToLG(
      assetPath: assetPath,
      fileName: imageFileName,
    );

    if (!uploadedImage) {
      return false;
    }

    final uploadedHtml = await uploadHtmlToLG(
      htmlFileName: 'skeleton.html',
      imageFileName: imageFileName,
      title: '${dinosaur.name} Skeleton',
      imageHeight: 95,
    );

    if (!uploadedHtml) {
      return false;
    }

    return await openChromiumOnAllScreens(
      'http://lg1:81/skeleton.html',
    );
  }

  Future<bool> showDinosaurComparisonImage(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);

    final assetPath = await getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_comparison',
    );

    if (assetPath == null) return false;

    final extension = assetPath.split('.').last;
    final imageFileName = '${cleanName}_comparison.$extension';

    final uploadedImage = await uploadAssetToLG(
      assetPath: assetPath,
      fileName: imageFileName,
    );

    if (!uploadedImage) return false;

    final uploadedHtml = await uploadHtmlToLG(
      htmlFileName: 'comparison.html',
      imageFileName: imageFileName,
      title: '${dinosaur.name} Comparison',
      imageHeight: 95,
    );

    if (!uploadedHtml) return false;

    return await openChromiumOnAllScreens('http://lg1:81/comparison.html');
  }

  Future<bool> openChromiumOnAllScreens(String url) async {
    try {
      for (var i = 1; i <= _lgConnectionModel.screens; i++) {
        final fullUrl = '$url?screen=$i&total=${_lgConnectionModel.screens}';

        final command =
        '''
sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "DISPLAY=:0 chromium-browser --kiosk --no-first-run --disable-infobars '$fullUrl' > /dev/null 2>&1 &"
''';

        await execute(command, 'Chromium opened on lg$i');

        await Future.delayed(const Duration(milliseconds: 500));
      }

      return true;
    } catch (e) {
      debugPrint('Error opening Chromium: $e');
      return false;
    }
  }

  Future<bool> closeChromiumOnAllScreens() async {
    try {
      for (var i = 1; i <= _lgConnectionModel.screens; i++) {
        final command =
        '''
sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "
pkill -f chromium-browser || true
pkill -f chromium || true
pkill -f chrome || true
sleep 2

DISPLAY=:0 wmctrl -a 'Google Earth' || true
DISPLAY=:0 xdotool search --name 'Google Earth' windowactivate || true
DISPLAY=:0 xdotool key F11 || true
"
''';

        await execute(command, 'Chromium closed on lg$i');

        await Future.delayed(const Duration(milliseconds: 700));
      }

      await execute(
        "echo 'exittour=true' > /tmp/query.txt",
        'Tour stopped after Chromium close',
      );

      await execute(
        "echo '' > /tmp/query.txt",
        'Query cleaned after Chromium close',
      );

      return true;
    } catch (e) {
      debugPrint('Error closing Chromium: $e');
      return false;
    }
  }

  Future<bool> uploadBytesToKml(String kml, String fileName) async {
    try {
      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        '/var/www/html/$fileName',
        mode: SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );
      await remoteFile.write(Stream.value(Uint8List.fromList(kml.codeUnits)));
      await remoteFile.close();
      return true;
    } catch (e) {
      debugPrint('Error uploading KML: $e');
      return false;
    }
  }

  Future<bool> uploadHtmlToLG({
    required String htmlFileName,
    required String imageFileName,
    required String title,
    double imageHeight = 95,
  }) async {
    try {
      final html =
      '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>$title</title>

<style>
html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: black;
}

#container {
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
}

#dino {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);

  height: ${imageHeight}vh;
  width: auto;

  max-width: none;
  object-fit: contain;
  image-rendering: auto;
}
</style>
</head>

<body>

<div id="container">
  <img id="dino" src="$imageFileName">
</div>

<script>
const params = new URLSearchParams(window.location.search);

const screen = parseInt(params.get("screen") || "1");
const total = parseInt(params.get("total") || "1");

const img = document.getElementById("dino");

/*
 * Orden visual del Liquid Galaxy.
 *
 * Para 5 pantallas:
 * posición visual:  1  2  3  4  5
 * LG lógico:        4  5  1  2  3
 *
 * Para otros tamaños intenta mantener lg1 en el centro
 * y reparte las demás pantallas alrededor.
 */
const leftSide = [];
const rightSide = [];

for (let i = 2; i <= total; i++) {
  if (i <= Math.ceil(total / 2)) {
    rightSide.push(i);
  } else {
    leftSide.push(i);
  }
}

const screenOrder = [...leftSide, 1, ...rightSide];

/*
 * Usamos las 3 pantallas centrales visuales.
 * Con 5 pantallas será: [5, 1, 2]
 */
const imageScreens = total;
const activeScreens = screenOrder;

const localIndex = activeScreens.indexOf(screen);

if (localIndex === -1) {
  img.style.display = "none";
}

img.onload = () => {
  if (localIndex === -1) return;

  const screenWidth = window.innerWidth;
  const wallWidth = screenWidth * imageScreens;
  const imgWidth = img.offsetWidth;

  const startX = (wallWidth - imgWidth) / 2;

  img.style.left =
      (startX - (localIndex * screenWidth)) + "px";
};
</script>

</body>
</html>
''';

      final sftp = await _client!.sftp();

      final remoteFile = await sftp.open(
        '/var/www/html/$htmlFileName',
        mode:
        SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(Stream.value(Uint8List.fromList(html.codeUnits)));

      await remoteFile.close();

      return true;
    } catch (e) {
      debugPrint('Error uploading HTML: $e');
      return false;
    }
  }

  Future<void> cleanLogos() async {
    try {
      final screen = calculateLeftMostScreen(_lgConnectionModel.screens);

      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty Logo</name>
  </Document>
</kml>''';

      await execute(
        "echo '$blankKml' > /var/www/html/kml/slave_$screen.kml",
        'Logo cleaned',
      );
    } catch (e) {
      debugPrint('Error cleaning logos: $e');
    }
  }

  Future<bool> cleanAll() async {
    try {
      await closeChromiumOnAllScreens();

      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';

      final logoScreen = calculateLeftMostScreen(_lgConnectionModel.screens);

      for (var i = 1; i <= _lgConnectionModel.screens; i++) {
        if (i == 1 || i == logoScreen) {
          continue;
        }

        await execute(
          "echo '$blankKml' > /var/www/html/kml/slave_$i.kml",
          'Cleaned screen $i',
        );
      }

      await execute("echo 'exittour=true' > /tmp/query.txt", 'Stop tour');

      await execute("echo '' > /tmp/query.txt", 'Clean query');

      await execute(
        "rm -f /var/www/html/skeleton.html /var/www/html/comparison.html",
        'Chromium HTML cleaned',
      );

      await sendLogo();

      return true;
    } catch (e) {
      debugPrint('Error cleaning all: $e');
      return false;
    }
  }

  Future<bool> reboot() async {
    try {
      for (var i = _lgConnectionModel.screens; i >= 1; i--) {
        await execute(
          'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "echo ${_lgConnectionModel.password} | sudo -S reboot"',
          'Reboot sent to lg$i',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error rebooting LG: $e');
      return false;
    }
  }

  Future<bool> shutdown() async {
    try {
      for (var i = _lgConnectionModel.screens; i >= 1; i--) {
        await execute(
          'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "echo ${_lgConnectionModel.password} | sudo -S poweroff"',
          'Shutdown sent to lg$i',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error shutting down LG: $e');
      return false;
    }
  }

  Future<bool> flyToMapPosition({
    required double latitude,
    required double longitude,
    required double zoom,
    double bearing = 0,
  }) async {
    try {
      final range = _mapZoomToRange(zoom);

      final lookAt =
          '<LookAt>'
          '<longitude>$longitude</longitude>'
          '<latitude>$latitude</latitude>'
          '<altitude>0</altitude>'
          '<heading>$bearing</heading>'
          '<tilt>0</tilt>'
          '<range>$range</range>'
          '<altitudeMode>relativeToGround</altitudeMode>'
          '</LookAt>';

      debugPrint(
        'Sending map position: '
            'lat=$latitude, lon=$longitude, zoom=$zoom, range=$range',
      );

      final result = await execute(
        "echo 'flytoview=$lookAt' > /tmp/query.txt",
        'Map position sent to Liquid Galaxy',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error synchronizing map with Liquid Galaxy: $e');
      return false;
    }
  }

  double _mapZoomToRange(double zoom) {
    final calculatedRange = 40000000.0 / math.pow(2, zoom);

    return calculatedRange.clamp(300.0, 20000000.0).toDouble();
  }

  Future<bool> relaunchLG() async {
    final relaunchCmd =
    '''
RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ];
then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ];
then
  export SERVICE=lightdm
else
  exit 1
fi
if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]];
then
  echo ${_lgConnectionModel.password} | sudo -S service \\\${SERVICE} start
else
  echo ${_lgConnectionModel.password} | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p ${_lgConnectionModel.password} ssh -x -t lg@lg1 "\$RELAUNCH_CMD"
''';

    final result = await execute(relaunchCmd, 'Liquid Galaxy relaunched');

    return result != null;
  }
}
