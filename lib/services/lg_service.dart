import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
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

// Dinosaur orbit.

  bool _isDinosaurOrbiting = false;

  bool get isDinosaurOrbiting =>
      _isDinosaurOrbiting;

// Prevents two SSH authentication attempts from running at the same time.
  Future<bool?>? _connectionInProgress;

// Prevents the automatic logo/marker setup from recursively starting again
// when execute() has to reconnect.
  bool _initializingAfterConnection = false;

  static const int _maxConnectionAttempts = 5;
  static const Duration _connectionTimeout = Duration(seconds: 10);

  final Map<String, List<double>> _continentViews = {
    'Africa': [
      20.0,       // longitude
      2.0,        // latitude
      9000000.0,  // range
    ],
    'Asia': [
      100.0,
      34.0,
      11000000.0,
    ],
    'Europe': [
      15.0,
      54.0,
      6500000.0,
    ],
    'North America': [
      -100.0,
      45.0,
      9000000.0,
    ],
    'South America': [
      -60.0,
      -15.0,
      9000000.0,
    ],
    'Oceania': [
      135.0,
      -25.0,
      8000000.0,
    ],
    'Antarctica': [
      0.0,
      -82.0,
      9000000.0,
    ],
  };

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
     _isDinosaurOrbiting = false;

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
      const double height = 2600;
      const double padding = 60;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // --------------------------------------------------
      // COLORS
      // --------------------------------------------------

      const backgroundColor =
      ui.Color(0xFF102F33);

      const cardColor =
      ui.Color(0xFF1A464A);

      const secondaryCardColor =
      ui.Color(0xFF24575B);

      const accentColor =
      ui.Color(0xFFE9C46A);

      const titleColor =
      ui.Color(0xFFFFFFFF);

      const labelColor =
      ui.Color(0xFFB8CFCC);

      const textColor =
      ui.Color(0xFFF4F7F6);

      // --------------------------------------------------
      // BACKGROUND
      // --------------------------------------------------

      final backgroundPaint = ui.Paint()
        ..color = backgroundColor;

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(
            0,
            0,
            width,
            height,
          ),
          const ui.Radius.circular(45),
        ),
        backgroundPaint,
      );

      double currentY = 55;

      // --------------------------------------------------
      // TEXT HELPER
      // --------------------------------------------------

      double drawText({
        required String text,
        required double fontSize,
        required double y,
        double x = padding,
        ui.FontWeight fontWeight =
            ui.FontWeight.normal,
        ui.Color color = textColor,
        double maxWidth =
            width - (padding * 2),
        double lineHeight = 1.25,
        ui.TextAlign textAlign =
            ui.TextAlign.left,
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
            x,
            y,
          ),
        );

        return paragraph.height;
      }

      // --------------------------------------------------
      // CARD HELPER
      // --------------------------------------------------

      void drawCard({
        required double x,
        required double y,
        required double cardWidth,
        required double cardHeight,
        ui.Color color = cardColor,
      }) {
        final paint = ui.Paint()
          ..color = color;

        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(
              x,
              y,
              cardWidth,
              cardHeight,
            ),
            const ui.Radius.circular(28),
          ),
          paint,
        );
      }

      // --------------------------------------------------
      // SMALL INFO CARD HELPER
      // --------------------------------------------------

      void drawInfoCard({
        required String label,
        required String value,
        required double x,
        required double y,
        required double cardWidth,
        double cardHeight = 135,
      }) {
        drawCard(
          x: x,
          y: y,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
        );

        drawText(
          text: label,
          fontSize: 27,
          y: y + 20,
          x: x + 22,
          maxWidth: cardWidth - 44,
          fontWeight: ui.FontWeight.bold,
          color: accentColor,
        );

        drawText(
          text: value.trim().isEmpty
              ? 'Unknown'
              : value,
          fontSize: 32,
          y: y + 60,
          x: x + 22,
          maxWidth: cardWidth - 44,
          color: textColor,
        );
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
        color: titleColor,
      );

      currentY += 16;

      currentY += drawText(
        text: dinosaur.periodName.toUpperCase(),
        fontSize: 28,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        textAlign: ui.TextAlign.center,
        color: accentColor,
      );

      currentY += 28;

      final separatorPaint = ui.Paint()
        ..color = accentColor
        ..strokeWidth = 4;

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
      // DINOSAUR IMAGE
      // --------------------------------------------------

      final cleanName =
      cleanDinosaurImageName(
        dinosaur.name,
      );

      final dinosaurImagePath =
      await getExistingImagePath(
        'assets/images/dinosaurs/'
            '${cleanName}_normal',
      );

      ui.Image? dinosaurImage;

      if (dinosaurImagePath != null) {
        try {
          final data = await rootBundle.load(
            dinosaurImagePath,
          );

          final bytes =
          data.buffer.asUint8List();

          final codec =
          await ui.instantiateImageCodec(
            bytes,
          );

          final frame =
          await codec.getNextFrame();

          dinosaurImage = frame.image;

          debugPrint(
            'Dinosaur image added to info column: '
                '$dinosaurImagePath',
          );
        } catch (e) {
          debugPrint(
            'Could not load dinosaur image '
                'for column: $e',
          );
        }
      }

      if (dinosaurImage != null) {
        const double maxImageWidth = 780;
        const double maxImageHeight = 390;

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

        // Background card behind image.
        drawCard(
          x: imageX - 18,
          y: currentY - 18,
          cardWidth: imageWidth + 36,
          cardHeight: imageHeight + 36,
          color: secondaryCardColor,
        );

        final sourceRect =
        ui.Rect.fromLTWH(
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

        currentY += imageHeight + 55;
      }

      // --------------------------------------------------
      // MAIN INFORMATION TITLE
      // --------------------------------------------------

      currentY += drawText(
        text: 'Overview',
        fontSize: 38,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );

      currentY += 18;

      const double gap = 18;

      final double cardWidth =
          (width -
              (padding * 2) -
              gap) /
              2;

      // --------------------------------------------------
      // PERIOD / YEAR
      // --------------------------------------------------

      drawInfoCard(
        label: 'Period',
        value: dinosaur.periodName,
        x: padding,
        y: currentY,
        cardWidth: cardWidth,
      );

      drawInfoCard(
        label: 'Year',
        value: dinosaur.year,
        x: padding + cardWidth + gap,
        y: currentY,
        cardWidth: cardWidth,
      );

      currentY += 153;

      // --------------------------------------------------
      // DIET / HABITAT
      // --------------------------------------------------

      drawInfoCard(
        label: 'Diet',
        value: dinosaur.diet,
        x: padding,
        y: currentY,
        cardWidth: cardWidth,
      );

      drawInfoCard(
        label: 'Habitat',
        value: dinosaur.habitat,
        x: padding + cardWidth + gap,
        y: currentY,
        cardWidth: cardWidth,
      );

      currentY += 153;

      // --------------------------------------------------
      // LENGTH / WEIGHT
      // --------------------------------------------------

      drawInfoCard(
        label: 'Length',
        value: dinosaur.length,
        x: padding,
        y: currentY,
        cardWidth: cardWidth,
      );

      drawInfoCard(
        label: 'Weight',
        value: dinosaur.weight,
        x: padding + cardWidth + gap,
        y: currentY,
        cardWidth: cardWidth,
      );

      currentY += 170;

      // --------------------------------------------------
      // LOCATION
      // --------------------------------------------------

      final location = [
        dinosaur.region,
        dinosaur.country,
      ]
          .where(
            (value) =>
        value.trim().isNotEmpty,
      )
          .join(', ');

      drawCard(
        x: padding,
        y: currentY,
        cardWidth:
        width - (padding * 2),
        cardHeight: 125,
      );

      drawText(
        text: 'Location',
        fontSize: 27,
        y: currentY + 18,
        x: padding + 22,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );

      drawText(
        text: location.isEmpty
            ? 'Unknown'
            : location,
        fontSize: 32,
        y: currentY + 58,
        x: padding + 22,
        maxWidth:
        width -
            (padding * 2) -
            44,
      );

      currentY += 165;

      // --------------------------------------------------
      // SCIENTIFIC INFORMATION
      // --------------------------------------------------

      currentY += drawText(
        text: 'Scientific Information',
        fontSize: 40,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );

      currentY += 18;

      const double scientificHeight = 390;

      drawCard(
        x: padding,
        y: currentY,
        cardWidth:
        width - (padding * 2),
        cardHeight: scientificHeight,
        color: secondaryCardColor,
      );

      double scientificY =
          currentY + 25;

      // STATUS

      drawText(
        text: 'Status',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );

      scientificY += 38;

      scientificY += drawText(
        text: dinosaur.status.isEmpty
            ? 'Unknown'
            : dinosaur.status,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth:
        width -
            (padding * 2) -
            56,
      );

      scientificY += 14;

      // AUTHOR

      drawText(
        text: 'Author',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );

      scientificY += 38;

      scientificY += drawText(
        text: dinosaur.author.isEmpty
            ? 'Unknown'
            : dinosaur.author,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth:
        width -
            (padding * 2) -
            56,
      );

      scientificY += 14;

      // FORMATION

      drawText(
        text: 'Formation',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );

      scientificY += 38;

      scientificY += drawText(
        text:
        dinosaur.formation.isEmpty
            ? 'Unknown'
            : dinosaur.formation,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth:
        width -
            (padding * 2) -
            56,
      );

      scientificY += 14;

      // TIME

      drawText(
        text: 'Time',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );

      scientificY += 38;

      final timeRange = [
        dinosaur.time1,
        dinosaur.time2,
      ]
          .where(
            (value) =>
        value.trim().isNotEmpty,
      )
          .join(' – ');

      drawText(
        text: timeRange.isEmpty
            ? 'Unknown'
            : timeRange,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth:
        width -
            (padding * 2) -
            56,
      );

      currentY += scientificHeight + 45;

      // --------------------------------------------------
      // ABOUT
      // --------------------------------------------------

      currentY += drawText(
        text: 'About',
        fontSize: 40,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );

      currentY += 18;

      final aboutText =
      dinosaur.generalInfo.isEmpty
          ? 'No additional information available.'
          : dinosaur.generalInfo;

      // Calculate paragraph first so card can fit text.
      final aboutBuilder =
      ui.ParagraphBuilder(
         ui.ParagraphStyle(
          fontSize: 30,
          height: 1.4,
        ),
      )
        ..pushStyle(
           ui.TextStyle(
            color: textColor,
            fontSize: 30,
          ),
        )
        ..addText(aboutText);

      final aboutParagraph =
      aboutBuilder.build();

      aboutParagraph.layout(
        ui.ParagraphConstraints(
          width:
          width -
              (padding * 2) -
              56,
        ),
      );

      final aboutCardHeight =
          aboutParagraph.height + 56;

      drawCard(
        x: padding,
        y: currentY,
        cardWidth:
        width - (padding * 2),
        cardHeight: aboutCardHeight,
      );

      canvas.drawParagraph(
        aboutParagraph,
        ui.Offset(
          padding + 28,
          currentY + 28,
        ),
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
          'Could not generate dinosaur '
              'info column image',
        );
        return false;
      }

      final bytes =
      byteData.buffer.asUint8List();

      // --------------------------------------------------
      // UPLOAD
      // --------------------------------------------------

      final uploaded =
      await uploadBytesToLG(
        bytes: bytes,
        fileName: fileName,
      );

      if (!uploaded) {
        debugPrint(
          'Could not upload dinosaur '
              'info column',
        );
        return false;
      }

      debugPrint(
        'Dinosaur info column created '
            'and uploaded: $fileName',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error creating dinosaur '
            'info column: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<bool> showDinosaurSelectionMarkers(
      List<Dinosaur> dinosaurs,
      ) async {
    try {
      if (_client == null || !_isConnected) {
        debugPrint(
          'Cannot show dinosaur markers: '
              'Liquid Galaxy is not connected',
        );
        return false;
      }

      // --------------------------------------------------
      // 1. FILTRAR DINOSAURIOS CON COORDENADAS VÁLIDAS
      // --------------------------------------------------

      final validDinosaurs = dinosaurs.where((dinosaur) {
        return dinosaur.latitude != 0 &&
            dinosaur.longitude != 0;
      }).toList();

      if (validDinosaurs.isEmpty) {
        debugPrint(
          'No dinosaurs with valid coordinates '
              'were found for this selection',
        );
        return false;
      }

      debugPrint(
        'Showing ${validDinosaurs.length} '
            'dinosaur selection markers',
      );

      // --------------------------------------------------
      // 2. SUBIR ICONO DEL MARCADOR
      // --------------------------------------------------

      final markerUploaded = await uploadAssetToLG(
        assetPath:
        'assets/images/markers/dino_marker.png',
        fileName: 'dino_marker.png',
      );

      if (!markerUploaded) {
        debugPrint(
          'Could not upload dino_marker.png',
        );
        return false;
      }

      debugPrint(
        'Marker image uploaded successfully',
      );

      // --------------------------------------------------
      // 3. CREAR LOS PLACEMARKS
      // --------------------------------------------------

      final placemarks =
      validDinosaurs.map((dinosaur) {
        final name =
        _cleanText(dinosaur.name);

        final country =
        _cleanText(dinosaur.country);

        final region =
        _cleanText(dinosaur.region);

        debugPrint(
          'Creating marker for ${dinosaur.name}: '
              'lat=${dinosaur.latitude}, '
              'lon=${dinosaur.longitude}',
        );

        return '''
<Placemark>
  <name>$name</name>

  <description>
    $country - $region
  </description>

  <Style>
    <IconStyle>

      <scale>3.5</scale>

      <Icon>
        <href>http://lg1:81/kml/dino_marker.png</href>
      </Icon>

      <hotSpot
        x="0.5"
        y="0"
        xunits="fraction"
        yunits="fraction"
      />

    </IconStyle>

    <LabelStyle>
      <scale>0</scale>
    </LabelStyle>

  </Style>

  <Point>
    <altitudeMode>clampToGround</altitudeMode>

    <coordinates>
      ${dinosaur.longitude},${dinosaur.latitude},0
    </coordinates>
  </Point>

</Placemark>
''';
      }).join('\n');

      // --------------------------------------------------
      // 4. CREAR KML COMPLETO
      // --------------------------------------------------

      final markersKml = '''
<?xml version="1.0" encoding="UTF-8"?>

<kml xmlns="http://www.opengis.net/kml/2.2">

  <Document>

    <name>
      GeoSaurio Selection Markers
    </name>

    $placemarks

  </Document>

</kml>
''';

      // --------------------------------------------------
      // 5. GUARDAR KML EN LIQUID GALAXY
      // --------------------------------------------------

      final writeResult = await execute(
        '''
cat > /var/www/html/kml/dinosaur_selection_markers.kml << 'EOFKML'
$markersKml
EOFKML
''',
        'Dinosaur selection markers KML written',
      );

      if (writeResult == null) {
        debugPrint(
          'Could not write dinosaur markers KML',
        );
        return false;
      }

      // --------------------------------------------------
      // 6. ELIMINAR REFERENCIA ANTERIOR
      // --------------------------------------------------

      await execute(
        '''
sed -i '\\|dinosaur_selection_markers.kml|d' /var/www/html/kmls.txt
''',
        'Old dinosaur marker reference removed',
      );

      // --------------------------------------------------
      // 7. REGISTRAR EL NUEVO KML
      // --------------------------------------------------

      final registerResult = await execute(
        '''
echo "http://lg1:81/kml/dinosaur_selection_markers.kml" >> /var/www/html/kmls.txt
''',
        'Dinosaur selection markers registered',
      );

      if (registerResult == null) {
        debugPrint(
          'Could not register dinosaur markers KML',
        );
        return false;
      }

      // --------------------------------------------------
      // 8. FORZAR GOOGLE EARTH A RECARGAR LOS KML
      // --------------------------------------------------

      final refreshResult = await execute(
        '''
echo "search=http://lg1:81/kmls.txt" > /tmp/query.txt
''',
        'Dinosaur selection markers sent to Google Earth',
      );

      if (refreshResult == null) {
        debugPrint(
          'Could not refresh Google Earth markers',
        );
        return false;
      }

      // --------------------------------------------------
      // DEBUG
      // --------------------------------------------------

      debugPrint(
        'MARKERS: KML created for '
            '${validDinosaurs.length} dinosaurs',
      );

      debugPrint(
        'MARKERS: icon URL = '
            'http://lg1:81/kml/dino_marker.png',
      );

      debugPrint(
        'MARKERS: KML URL = '
            'http://lg1:81/kml/dinosaur_selection_markers.kml',
      );

      debugPrint(
        '${validDinosaurs.length} dinosaur markers '
            'displayed successfully',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error showing dinosaur selection markers: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<bool> cleanDinosaurSelectionMarkers() async {
    try {
      if (_client == null || !_isConnected) {
        return false;
      }

      // Quitar únicamente el KML de marcadores
      // de la lista que carga Google Earth.
      await execute(
        '''
sed -i '\\|dinosaur_selection_markers.kml|d' /var/www/html/kmls.txt
''',
        'Dinosaur selection marker reference removed',
      );

      // Vaciar el archivo por seguridad.
      const emptyKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
  </Document>
</kml>
''';

      await execute(
        '''
cat > /var/www/html/kml/dinosaur_selection_markers.kml << 'EOFKML'
$emptyKml
EOFKML
''',
        'Dinosaur selection markers cleaned',
      );

      // Recargar los KML restantes.
      final result = await execute(
        '''
echo "search=http://lg1:81/kmls.txt" > /tmp/query.txt
''',
        'Google Earth refreshed after marker cleanup',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint(
        'Error cleaning dinosaur selection markers: $e',
      );
      debugPrint('$stackTrace');

      return false;
    }
  }

  String _buildDinosaurOrbitKml(
      Dinosaur dinosaur,
      ) {
    final cubePosition =
    _calculateCubePosition(dinosaur);

    final double cubeLatitude =
    cubePosition['latitude']!;

    final double cubeLongitude =
    cubePosition['longitude']!;

    /*
   * IMPORTANTE:
   * exactamente la misma vista que flyToDinosaur().
   *
   * Si has cambiado la cámara a 602,
   * mantenemos 602 también aquí.
   */
    const double orbitAltitude = 160.0;
    const double orbitRange = 610.0;
    const double orbitTilt = 72.0;

    /*
   * 36 pasos × 10 grados = 360 grados.
   *
   * duration controla la velocidad.
   * 0.7 = bastante fluida.
   */
    const double degreesPerStep = 10.0;
    const double durationPerStep = 0.7;

    final StringBuffer steps = StringBuffer();

    double heading = dinosaur.heading;

    for (int step = 0; step <= 36; step++) {
      if (heading >= 360.0) {
        heading -= 360.0;
      }

      steps.write(
        '''
      <gx:FlyTo>
        <gx:duration>$durationPerStep</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>

        <LookAt>
          <longitude>$cubeLongitude</longitude>
          <latitude>$cubeLatitude</latitude>
          <altitude>$orbitAltitude</altitude>
          <heading>$heading</heading>
          <tilt>$orbitTilt</tilt>
          <range>$orbitRange</range>
          <gx:fovy>60</gx:fovy>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        </LookAt>

      </gx:FlyTo>
''',
      );

      heading += degreesPerStep;
    }

    return '''
<?xml version="1.0" encoding="UTF-8"?>

<kml
  xmlns="http://www.opengis.net/kml/2.2"
  xmlns:gx="http://www.google.com/kml/ext/2.2"
  xmlns:kml="http://www.opengis.net/kml/2.2"
  xmlns:atom="http://www.w3.org/2005/Atom"
>

  <gx:Tour>
    <name>DinosaurOrbit</name>

    <gx:Playlist>
      ${steps.toString()}
    </gx:Playlist>

  </gx:Tour>

</kml>
''';
  }

  String _buildDinosaurOrbitLookAt({
    required double latitude,
    required double longitude,
    required double heading,
  }) {
    return '<LookAt>'
        '<longitude>$longitude</longitude>'
        '<latitude>$latitude</latitude>'

    // El cubo mide 30 m.
    // Miramos aproximadamente a su centro vertical.
        '<altitude>15</altitude>'

        '<heading>$heading</heading>'

    // Misma inclinación que la vista normal.
        '<tilt>72</tilt>'

    // Misma distancia que flyToDinosaur().
        '<range>610</range>'

        '<altitudeMode>relativeToGround</altitudeMode>'
        '</LookAt>';
  }

  Future<bool> startDinosaurOrbit(
      Dinosaur dinosaur,
      ) async {
    try {
      if (_client == null || !_isConnected) {
        debugPrint(
          'Cannot start dinosaur orbit: '
              'Liquid Galaxy is not connected',
        );
        return false;
      }

      if (_isDinosaurOrbiting) {
        debugPrint(
          'Dinosaur orbit is already running',
        );
        return false;
      }

      /*
     * El punto que NO se mueve.
     *
     * Como queremos orbitar alrededor del cubo,
     * usamos exactamente el centro horizontal
     * del cubo como LookAt.
     */
      final cubePosition =
      _calculateCubePosition(dinosaur);

      final double latitude =
      cubePosition['latitude']!;

      final double longitude =
      cubePosition['longitude']!;

      /*
     * Igual que el código de tu amiga:
     * partimos del heading actual.
     */
      double heading = dinosaur.heading;

      _isDinosaurOrbiting = true;

      notifyListeners();

      debugPrint(
        'Orbit started around cube: '
            'lat=$latitude, lon=$longitude',
      );

      /*
     * EXACTAMENTE el enfoque de tu amiga.
     *
     * Mientras Orbit siga activo:
     *
     * heading + 10
     * enviar flytoview
     * esperar 500 ms
     * repetir
     */
      while (_isDinosaurOrbiting) {
        heading =
            (heading + 10.0) % 360.0;

        final lookAt =
        _buildDinosaurOrbitLookAt(
          latitude: latitude,
          longitude: longitude,
          heading: heading,
        );

        debugPrint(
          'Orbit heading: $heading',
        );

        /*
       * Mandamos directamente la nueva vista.
       */
        final result = await execute(
          'echo "flytoview=$lookAt" '
              '> /tmp/query.txt',
          'Orbit view sent',
        );

        if (result == null) {
          debugPrint(
            'Could not send orbit view',
          );
        }

        /*
       * Tu amiga usa 500 ms.
       *
       * No toquemos esto hasta comprobar
       * primero que la órbita funciona.
       */
        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );
      }

      debugPrint(
        'Orbit loop finished',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error during dinosaur orbit: $e',
      );

      debugPrint('$stackTrace');

      _isDinosaurOrbiting = false;

      notifyListeners();

      return false;
    }
  }

  Future<void> stopDinosaurOrbit() async {
    _isDinosaurOrbiting = false;

    notifyListeners();

    debugPrint(
      'Dinosaur orbit stopped',
    );
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
      if (_client == null || !_isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      if (dinosaur.latitude == 0 ||
          dinosaur.longitude == 0) {
        debugPrint(
          'Invalid coordinates for ${dinosaur.name}: '
              '${dinosaur.latitude}, ${dinosaur.longitude}',
        );
        return false;
      }

      /*
     * El cubo no está en las coordenadas originales
     * del dinosaurio. Por eso la cámara debe mirar
     * directamente al centro del cubo.
     */
      final cubePosition =
      _calculateCubePosition(dinosaur);

      final double cubeLatitude =
      cubePosition['latitude']!;

      final double cubeLongitude =
      cubePosition['longitude']!;

      /*
     * El cubo mide 250 metros de alto.
     * Miramos aproximadamente a su centro vertical.
     */
      const double targetAltitude = 160.0;
      const double fixedTilt = 72.0;
      const double fixedRange = 610.0;

      final lookAt =
          '<LookAt>'
          '<longitude>$cubeLongitude</longitude>'
          '<latitude>$cubeLatitude</latitude>'
          '<altitude>$targetAltitude</altitude>'
          '<heading>${dinosaur.heading}</heading>'
          '<tilt>$fixedTilt</tilt>'
          '<range>$fixedRange</range>'
          '<altitudeMode>relativeToGround</altitudeMode>'
          '</LookAt>';

      debugPrint(
        'FlyTo cube for ${dinosaur.name}: '
            'cubeLat=$cubeLatitude, '
            'cubeLon=$cubeLongitude, '
            'altitude=$targetAltitude, '
            'tilt=$fixedTilt, '
            'range=$fixedRange, '
            'heading=${dinosaur.heading}',
      );

      final result = await execute(
        'echo "flytoview=$lookAt" > /tmp/query.txt',
        'FlyTo dinosaur cube sent',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint('Error flying to dinosaur cube: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> flyToContinent(String continent) async {
    try {
      if (_client == null || !_isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      final view = _continentViews[continent];

      if (view == null) {
        debugPrint('Unknown continent: $continent');
        return false;
      }

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
        'echo "flytoview=$lookAt" > /tmp/query.txt',
        'FlyTo continent sent: $continent',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint('Error flying to continent: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> flyToCountry(
      String country,
      List<Dinosaur> dinosaurs,
      ) async {
    try {
      if (_client == null || !_isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      final validDinosaurs = dinosaurs.where((dinosaur) {
        return dinosaur.latitude != 0 &&
            dinosaur.longitude != 0;
      }).toList();

      if (validDinosaurs.isEmpty) {
        debugPrint(
          'No valid dinosaur coordinates found for $country',
        );
        return false;
      }

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

      final range =
      validDinosaurs.length <= 1
          ? 250000.0
          : 900000.0;

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

      debugPrint(
        'Sending FlyTo country $country: '
            'lat=$latitude, lon=$longitude, range=$range',
      );

      final result = await execute(
        'echo "flytoview=$lookAt" > /tmp/query.txt',
        'FlyTo country sent: $country',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint('Error flying to country: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Map<String, double> _calculateCubePosition(
      Dinosaur dinosaur,
      ) {
    /*
   * Distancia a la que queremos colocar el cubo
   * delante de la cámara.
   */
    const double offset = 0.012;

    final heading =
        dinosaur.heading * math.pi / 180.0;

    return {
      'latitude':
      dinosaur.latitude +
          math.cos(heading) * offset,

      'longitude':
      dinosaur.longitude +
          math.sin(heading) * offset,
    };
  }

  Future<bool> showSelectedDinosaurCube(
      Dinosaur dinosaur,
      ) async {
    try {
      if (_client == null) {
        debugPrint('SSH client is not connected');
        return false;
      }

      if (dinosaur.latitude == 0 ||
          dinosaur.longitude == 0) {
        debugPrint(
          'Invalid coordinates for ${dinosaur.name}',
        );
        return false;
      }

      const double radius = 0.0025;
      const double altitude = 30.0;

      final cubePosition =
      _calculateCubePosition(dinosaur);

      final double latitude =
      cubePosition['latitude']!;

      final double longitude =
      cubePosition['longitude']!;

      final double north = latitude + radius;
      final double south = latitude - radius;
      final double east = longitude + radius;
      final double west = longitude - radius;

      final safeName =
      _cleanText(dinosaur.name);

      final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>

  <Style id="cube">
    <LineStyle>
      <color>cc00ffff</color>
      <width>3</width>
    </LineStyle>

    <PolyStyle>
      <color>4400ffff</color>
      <fill>1</fill>
      <outline>1</outline>
    </PolyStyle>
  </Style>

  <Placemark>
    <name>$safeName</name>
    <styleUrl>#cube</styleUrl>

    <MultiGeometry>

      <!-- Pared norte -->
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>

        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
$west,$north,0
$east,$north,0
$east,$north,$altitude
$west,$north,$altitude
$west,$north,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>

      <!-- Pared sur -->
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>

        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
$east,$south,0
$west,$south,0
$west,$south,$altitude
$east,$south,$altitude
$east,$south,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>

      <!-- Pared este -->
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>

        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
$east,$north,0
$east,$south,0
$east,$south,$altitude
$east,$north,$altitude
$east,$north,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>

      <!-- Pared oeste -->
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>

        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
$west,$south,0
$west,$north,0
$west,$north,$altitude
$west,$south,$altitude
$west,$south,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>

    </MultiGeometry>
  </Placemark>

</Document>
</kml>
''';

      final logoScreen =
      calculateLeftMostScreen(
        _lgConnectionModel.screens,
      );

      await execute(
        '> /var/www/html/kmls.txt',
        'Old cube removed',
      );

      await execute(
        '''
cat > /var/www/html/kml/master.kml << 'EOFKML'
$kml
EOFKML
''',
        'Master cube written',
      );

      await execute(
        'echo "http://lg1:81/kml/master.kml" '
            '>> /var/www/html/kmls.txt',
        'Master registered',
      );

      for (
      int screen = 1;
      screen <= _lgConnectionModel.screens;
      screen++
      ) {
        if (screen == logoScreen) {
          continue;
        }

        await execute(
          '''
cat > /var/www/html/kml/slave_$screen.kml << 'EOFKML'
$kml
EOFKML
''',
          'Slave cube written',
        );

        await execute(
          'echo "http://lg1:81/kml/slave_$screen.kml" '
              '>> /var/www/html/kmls.txt',
          'Slave registered',
        );
      }

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      await execute(
        'echo "search=http://lg1:81/kmls.txt" '
            '> /tmp/query.txt',
        'Cube refreshed',
      );

      for (
      int screen = 2;
      screen <= _lgConnectionModel.screens;
      screen++
      ) {
        if (screen == logoScreen) {
          continue;
        }

        await _forceRefresh(screen);
      }

      debugPrint(
        'Open cube shown for ${dinosaur.name}',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error showing selected cube: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }


  Future<bool> cleanDinosaurMarkers() async {
    try {
      if (_client == null) {
        debugPrint('SSH client is not connected');
        return false;
      }

      final int logoScreen =
      calculateLeftMostScreen(
        _lgConnectionModel.screens,
      );

      const String emptyKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty GeoSaurio KML</name>
  </Document>
</kml>
''';

      final String clearMasterCommand = '''
cat > /var/www/html/kml/master.kml << 'EOFKML'
$emptyKml
EOFKML
''';

      final masterResult = await execute(
        clearMasterCommand,
        'master.kml cleaned',
      );

      if (masterResult == null) {
        return false;
      }

      /*
     * Limpiar todos los slaves excepto el que contiene
     * el logo.
     */
      for (
      int screen = 1;
      screen <= _lgConnectionModel.screens;
      screen++
      ) {
        if (screen == logoScreen) {
          debugPrint(
            'Skipping slave_$screen.kml to preserve logo',
          );
          continue;
        }

        final String clearSlaveCommand = '''
cat > /var/www/html/kml/slave_$screen.kml << 'EOFKML'
$emptyKml
EOFKML
''';

        final slaveResult = await execute(
          clearSlaveCommand,
          'slave_$screen.kml cleaned',
        );

        if (slaveResult == null) {
          return false;
        }
      }

      final clearListResult = await execute(
        '> /var/www/html/kmls.txt',
        'KML list cleared',
      );

      if (clearListResult == null) {
        return false;
      }

      final registerMasterResult = await execute(
        'echo "http://lg1:81/kml/master.kml" '
            '>> /var/www/html/kmls.txt',
        'Empty master.kml registered',
      );

      if (registerMasterResult == null) {
        return false;
      }

      /*
     * Registrar únicamente los slaves vacíos.
     * El KML del logo no se añade a esta lista.
     */
      for (
      int screen = 1;
      screen <= _lgConnectionModel.screens;
      screen++
      ) {
        if (screen == logoScreen) {
          continue;
        }

        final registerSlaveResult = await execute(
          'echo "http://lg1:81/kml/slave_$screen.kml" '
              '>> /var/www/html/kmls.txt',
          'Empty slave_$screen.kml registered',
        );

        if (registerSlaveResult == null) {
          return false;
        }
      }

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      final refreshResult = await execute(
        'echo "search=http://lg1:81/kmls.txt" '
            '> /tmp/query.txt',
        'Empty KML loaded on master',
      );

      if (refreshResult == null) {
        return false;
      }

      /*
     * Refrescar todas las pantallas salvo la pantalla
     * del logo.
     */
      for (
      int screen = 2;
      screen <= _lgConnectionModel.screens;
      screen++
      ) {
        if (screen == logoScreen) {
          continue;
        }

        await _forceRefresh(screen);
      }

      /*
     * Restaurar el logo por seguridad, por si Google Earth
     * hubiera descargado temporalmente el overlay.
     */
      final logoSent = await sendLogo();

      if (!logoSent) {
        debugPrint(
          'Markers cleaned, but logo could not be restored',
        );
      }

      debugPrint(
        'Dinosaur cubes cleaned successfully '
            'while preserving logo',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error cleaning dinosaur markers: $e',
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
      imageHeight: 70,
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
      imageHeight: 70,
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
      await stopDinosaurOrbit();
      await closeChromiumOnAllScreens();

      final dinosaurMarkersCleaned =
      await cleanDinosaurMarkers();

      if (!dinosaurMarkersCleaned) {
        debugPrint('Could not clean dinosaur markers');
      }

      const blankKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';

      final logoScreen =
      calculateLeftMostScreen(_lgConnectionModel.screens);

      for (var i = 2; i <= _lgConnectionModel.screens; i++) {
        if (i == logoScreen) {
          continue;
        }

        await execute(
          '''
cat > /var/www/html/kml/slave_$i.kml << 'EOFKML'
$blankKml
EOFKML
''',
          'Cleaned screen $i',
        );

        await _forceRefresh(i);
      }

      await execute(
        "echo 'exittour=true' > /tmp/query.txt",
        'Stop tour',
      );

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      await execute(
        "echo '' > /tmp/query.txt",
        'Clean query',
      );

      await execute(
        'rm -f '
            '/var/www/html/skeleton.html '
            '/var/www/html/comparison.html',
        'Chromium HTML cleaned',
      );

      await sendLogo();

      return dinosaurMarkersCleaned;
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
        'echo "flytoview=$lookAt" > /tmp/query.txt',
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
