import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dinosaur.dart';

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

  Future<bool?> connectToLG() async {
    if (_currentConnectionAttempts >= _maxConnectionAttempts) {
      _currentConnectionAttempts = 0;
      notifyListeners();
      return false;
    }

    try {
      final socket = await SSHSocket.connect(
        _lgConnectionModel.ip,
        _lgConnectionModel.port,
      ).timeout(_connectionTimeout);

      _client = SSHClient(
        socket,
        username: _lgConnectionModel.username,
        onPasswordRequest: () => _lgConnectionModel.password,
        keepAliveInterval: const Duration(seconds: 10),
      );

      _isConnected = true;
      _currentConnectionAttempts = 0;
      notifyListeners();

      Future.delayed(const Duration(seconds: 2), () async {
        await sendLogo();
      });

      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      _currentConnectionAttempts++;
    }

    notifyListeners();
    return false;
  }

  void disconnect() {
    _client?.close();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<dynamic> execute(String command, String successMessage) async {
    if (_client == null) {
      debugPrint('SSH client not connected');
      return null;
    }

    try {
      final result = await _client!.execute(command);
      debugPrint(successMessage);
      return result;
    } catch (e) {
      debugPrint('Command error: $e');
      return null;
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

  Future<String?> getExistingImagePath(String basePath) async {
    final extensions = ['.png', '.jpg', '.jpeg'];

    final variants = <String>{
      basePath,
      basePath.toLowerCase(),
    };

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
      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(bytes.buffer.asUint8List());

      final sftp = await _client!.sftp();

      final remoteFile = await sftp.open(
        '/var/www/html/$fileName',
        mode: SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(
        Stream.value(Uint8List.fromList(await file.readAsBytes())),
      );

      await remoteFile.close();

      return true;
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return false;
    }
  }

  Future<bool> uploadBytesToLG({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final sftp = await _client!.sftp();

      final remoteFile = await sftp.open(
        '/var/www/html/$fileName',
        mode: SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(
        Stream.value(bytes),
      );

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

  Future<Uint8List?> createDinosaurInfoImage(Dinosaur dinosaur) async {
    try {
      const double width = 900;
      const double height = 620;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xEEFFFFFF);

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(0, 0, width, height),
          const ui.Radius.circular(26),
        ),
        backgroundPaint,
      );

      final titleStyle = ui.TextStyle(
        color: const ui.Color(0xFF111111),
        fontSize: 42,
        fontWeight: ui.FontWeight.bold,
      );

      final bodyStyle = ui.TextStyle(
        color: const ui.Color(0xFF111111),
        fontSize: 28,
      );

      final titleBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          maxLines: 2,
          textAlign: ui.TextAlign.left,
        ),
      )
        ..pushStyle(titleStyle)
        ..addText(_cleanText(dinosaur.name));

      final titleParagraph = titleBuilder.build()
        ..layout(
          const ui.ParagraphConstraints(width: width - 60),
        );

      canvas.drawParagraph(
        titleParagraph,
        const ui.Offset(30, 28),
      );

      final info = '''
Period: ${_cleanText(dinosaur.periodName)}
Time: ${_cleanText(dinosaur.time1)} - ${_cleanText(dinosaur.time2)}
Diet: ${_cleanText(dinosaur.diet)}
Length: ${_cleanText(dinosaur.length)}
Weight: ${_cleanText(dinosaur.weight)}
Country: ${_cleanText(dinosaur.country)}
Region: ${_cleanText(dinosaur.region)}
Formation: ${_cleanText(dinosaur.formation)}
Habitat: ${_cleanText(dinosaur.habitat)}

${_cleanText(dinosaur.generalInfo)}
''';

      final bodyBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          maxLines: 14,
          textAlign: ui.TextAlign.left,
        ),
      )
        ..pushStyle(bodyStyle)
        ..addText(info);

      final bodyParagraph = bodyBuilder.build()
        ..layout(
          const ui.ParagraphConstraints(width: width - 60),
        );

      canvas.drawParagraph(
        bodyParagraph,
        const ui.Offset(30, 125),
      );

      final picture = recorder.endRecording();

      final image = await picture.toImage(
        width.toInt(),
        height.toInt(),
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating dinosaur info image: $e');
      return null;
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

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
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

  Future<bool> showDinosaurAboutKml(Dinosaur dinosaur) async {
    try {
      final screen = calculateRightMostScreen(_lgConnectionModel.screens);
      final cleanName = cleanDinosaurImageName(dinosaur.name);

      final assetPath = await getExistingImagePath(
        'assets/images/dinosaurs/${cleanName}_normal',
      );

      String? imageFileName;

      if (assetPath != null) {
        final extension = assetPath
            .split('.')
            .last;
        imageFileName = '${cleanName}_normal.$extension';

        await uploadAssetToLG(
          assetPath: assetPath,
          fileName: imageFileName,
        );
      }

      final infoBytes = await createDinosaurInfoImage(dinosaur);
      if (infoBytes == null) return false;

      final infoFileName = '${cleanName}_info.png';

      final uploadedInfo = await uploadBytesToLG(
        bytes: infoBytes,
        fileName: infoFileName,
      );

      if (!uploadedInfo) return false;

      final imageOverlay = imageFileName == null
          ? ''
          : '''
    <ScreenOverlay>
      <name>Dinosaur Image</name>
      <Icon>
        <href>http://lg1:81/$imageFileName</href>
      </Icon>
      <overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.5" y="0.72" xunits="fraction" yunits="fraction"/>
      <size x="620" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
''';

      final textY = imageFileName == null ? '0.50' : '0.30';
      final textSize = imageFileName == null ? '900' : '760';

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
$imageOverlay
    <ScreenOverlay>
      <name>Dinosaur Info</name>
      <Icon>
        <href>http://lg1:81/$infoFileName</href>
      </Icon>
      <overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.5" y="$textY" xunits="fraction" yunits="fraction"/>
      <size x="$textSize" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';

      await cleanRightScreenKml();

      final result = await execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Dinosaur about KML sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error showing dinosaur about KML: $e');
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

  Future<bool> showDinosaurAboutBalloon(Dinosaur dinosaur) async {
    return await showDinosaurAboutKml(dinosaur);
  }

  Future<bool> showDinosaurNormalOverlay(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);

    final assetPath = await getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_normal',
    );

    if (assetPath == null) return false;

    final extension = assetPath
        .split('.')
        .last;

    return await showRightScreenImage(
      assetPath: assetPath,
      fileName: '${cleanName}_normal.$extension',
    );
  }

  Future<bool> showDinosaurSkeletonImage(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);

    final assetPath = await getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_skeleton',
    );

    if (assetPath == null) return false;

    final extension = assetPath
        .split('.')
        .last;
    final imageFileName = '${cleanName}_skeleton.$extension';

    final uploadedImage = await uploadAssetToLG(
      assetPath: assetPath,
      fileName: imageFileName,
    );

    if (!uploadedImage) return false;

    final uploadedHtml = await uploadHtmlToLG(
      htmlFileName: 'skeleton.html',
      imageFileName: imageFileName,
      title: '${dinosaur.name} Skeleton',
      imageHeight: 67,
    );

    if (!uploadedHtml) return false;

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

    final extension = assetPath
        .split('.')
        .last;
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

    return await openChromiumOnAllScreens(
      'http://lg1:81/comparison.html',
    );
  }

  Future<bool> openChromiumOnAllScreens(String url) async {
    try {
      for (var i = 1; i <= _lgConnectionModel.screens; i++) {
        final fullUrl = '$url?screen=$i&total=${_lgConnectionModel.screens}';

        final command = '''
sshpass -p ${_lgConnectionModel
            .password} ssh -t lg$i "DISPLAY=:0 chromium-browser --kiosk --no-first-run --disable-infobars '$fullUrl' > /dev/null 2>&1 &"
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
        final command = '''
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

  Future<bool> uploadHtmlToLG({
    required String htmlFileName,
    required String imageFileName,
    required String title,
    double imageHeight = 95,
  }) async {
    try {
      final html = '''
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
        mode: SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(
        Stream.value(
          Uint8List.fromList(html.codeUnits),
        ),
      );

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

      final logoScreen = calculateLeftMostScreen(
        _lgConnectionModel.screens,
      );

      for (var i = 1; i <= _lgConnectionModel.screens; i++) {
        if (i == logoScreen) {
          continue;
        }

        await execute(
          "echo '$blankKml' > /var/www/html/kml/slave_$i.kml",
          'Cleaned screen $i',
        );
      }

      await execute(
        "echo 'exittour=true' > /tmp/query.txt",
        'Stop tour',
      );

      await execute(
        "echo '' > /tmp/query.txt",
        'Clean query',
      );

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
          'sshpass -p ${_lgConnectionModel
              .password} ssh -t lg$i "echo ${_lgConnectionModel
              .password} | sudo -S reboot"',
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
          'sshpass -p ${_lgConnectionModel
              .password} ssh -t lg$i "echo ${_lgConnectionModel
              .password} | sudo -S poweroff"',
          'Shutdown sent to lg$i',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error shutting down LG: $e');
      return false;
    }
  }

  Future<bool> relaunchLG() async {
    final relaunchCmd = '''
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

    final result = await execute(
      relaunchCmd,
      'Liquid Galaxy relaunched',
    );

    return result != null;
  }
}