import 'dart:async';
import 'dart:io';

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
    } on TimeoutException {
      _currentConnectionAttempts++;
    } on SocketException {
      _currentConnectionAttempts++;
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
      debugPrint('SSH client NOT connected');
      return null;
    }

    try {
      final result = await _client!.execute(command);
      debugPrint(successMessage);
      return result;
    } catch (e) {
      debugPrint('There was an error executing the command: $e');
      return null;
    }
  }

  Future<bool> query(String content) async {
    final result = await execute(
      'echo "$content" > /tmp/query.txt',
      'Query sent: $content',
    );

    return result != null;
  }

  Future<bool> flyTo(String kmlViewTag) async {
    final command = "echo 'flytoview=$kmlViewTag' > /tmp/query.txt";

    final result = await execute(command, 'FlyTo command sent');

    return result != null;
  }

  Future<bool> flyToDinosaur(Dinosaur dinosaur) async {
    try {
      debugPrint('FLY TO DINOSAUR: ${dinosaur.name}');
      debugPrint('LONG: ${dinosaur.longitude}');
      debugPrint('LAT: ${dinosaur.latitude}');
      debugPrint('RANGE: ${dinosaur.range}');

      if (dinosaur.longitude == 0 || dinosaur.latitude == 0) {
        debugPrint('Invalid dinosaur coordinates');
        return false;
      }

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

      return await flyTo(lookAt);
    } catch (e) {
      debugPrint('Error flying to dinosaur: $e');
      return false;
    }
  }

  int calculateLeftMostScreen(int screenCount) {
    if (screenCount == 1) return 1;
    return (screenCount / 2).floor() + 2;
  }

  int calculateRightMostScreen(int screenCount) {
    if (screenCount == 1) return 1;
    return (screenCount / 2).floor() + 1;
  }

  int calculateCenterScreen(int screenCount) {
    if (screenCount == 1) return 1;
    return (screenCount / 2).ceil();
  }

  String cleanDinosaurImageName(String name) {
    return name
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll('?', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('-', '_')
        .trim();
  }

  Future<String?> getExistingImagePath(String basePath) async {
    final pngPath = '$basePath.png';
    final jpgPath = '$basePath.jpg';

    try {
      await rootBundle.load(pngPath);
      return pngPath;
    } catch (_) {}

    try {
      await rootBundle.load(jpgPath);
      return jpgPath;
    } catch (_) {}

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

      await sftp
          .open(
            '/var/www/html/$fileName',
            mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
          )
          .then((remoteFile) async {
            final fileBytes = await file.readAsBytes();

            await remoteFile.write(Stream.value(Uint8List.fromList(fileBytes)));

            await remoteFile.close();
          });

      return true;
    } catch (e) {
      debugPrint('Error uploading asset to LG: $e');
      return false;
    }
  }

  Future<bool> cleanAll() async {
    try {
      const emptyKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
</Document>
</kml>
''';

      await execute('> /var/www/html/kmls.txt', 'KMLs cleaned');

      for (int i = 1; i <= _lgConnectionModel.screens; i++) {
        await execute(
          "echo '$emptyKml' > /var/www/html/kml/slave_$i.kml",
          'Screen $i cleaned',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error cleaning KMLs: $e');
      return false;
    }
  }

  Future<void> cleanLogos() async {
    final leftMostScreen = calculateLeftMostScreen(_lgConnectionModel.screens);

    const emptyKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
</Document>
</kml>
''';

    await execute(
      "echo '$emptyKml' > /var/www/html/kml/slave_$leftMostScreen.kml",
      'Logo cleaned',
    );
  }

  Future<bool> sendLogo() async {
    try {
      final leftMostScreen = calculateLeftMostScreen(
        _lgConnectionModel.screens,
      );

      final uploaded = await uploadAssetToLG(
        assetPath: 'assets/images/logos.png',
        fileName: 'logos.png',
      );

      if (!uploaded) return false;

      const String kmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>

<ScreenOverlay>
  <name>GeoSaurio Overlay</name>

  <Icon>
    <href>http://lg1:81/logos.png</href>
  </Icon>

  <overlayXY
      x="0"
      y="1"
      xunits="fraction"
      yunits="fraction"/>

  <screenXY
      x="0.02"
      y="0.98"
      xunits="fraction"
      yunits="fraction"/>

  <size
      x="700"
      y="0"
      xunits="pixels"
      yunits="pixels"/>

</ScreenOverlay>

</Document>
</kml>
''';

      final result = await execute(
        "echo '$kmlContent' > /var/www/html/kml/slave_$leftMostScreen.kml",
        'Logo overlay sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error sending logo: $e');
      return false;
    }
  }

  Future<bool> showLeftScreenImage({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final leftScreen = calculateLeftMostScreen(_lgConnectionModel.screens);

      final uploaded = await uploadAssetToLG(
        assetPath: assetPath,
        fileName: fileName,
      );

      if (!uploaded) return false;

      final kml =
          '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>

<ScreenOverlay>
  <name>Dinosaur Image</name>

  <Icon>
    <href>http://lg1:81/$fileName</href>
  </Icon>

  <overlayXY
      x="0"
      y="0.5"
      xunits="fraction"
      yunits="fraction"/>

  <screenXY
      x="0.02"
      y="0.5"
      xunits="fraction"
      yunits="fraction"/>

  <size
      x="600"
      y="0"
      xunits="pixels"
      yunits="pixels"/>

</ScreenOverlay>

</Document>
</kml>
''';

      final result = await execute(
        "echo '$kml' > /var/www/html/kml/slave_$leftScreen.kml",
        'Left image overlay sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error showing left image: $e');
      return false;
    }
  }

  Future<bool> showRightScreenImage({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final rightScreen = calculateRightMostScreen(
        _lgConnectionModel.screens,
      );

      final uploaded = await uploadAssetToLG(
        assetPath: assetPath,
        fileName: fileName,
      );

      if (!uploaded) return false;

      final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>

<ScreenOverlay>
  <name>Dinosaur Image</name>

  <Icon>
    <href>http://lg1:81/$fileName</href>
  </Icon>

  <overlayXY
      x="1"
      y="0.5"
      xunits="fraction"
      yunits="fraction"/>

  <screenXY
      x="0.98"
      y="0.5"
      xunits="fraction"
      yunits="fraction"/>

  <size
      x="600"
      y="0"
      xunits="pixels"
      yunits="pixels"/>

</ScreenOverlay>

</Document>
</kml>
''';

      final result = await execute(
        "echo '$kml' > /var/www/html/kml/slave_$rightScreen.kml",
        'Right image overlay sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error showing right image: $e');
      return false;
    }
  }

  Future<bool> showImageInChromium({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final uploaded = await uploadAssetToLG(
        assetPath: assetPath,
        fileName: fileName,
      );

      if (!uploaded) return false;

      final url = 'http://lg1:81/$fileName';

      final command =
          'DISPLAY=:0 chromium-browser '
          '--noerrdialogs '
          '--disable-infobars '
          '--disable-session-crashed-bubble '
          '--no-sandbox '
          '--kiosk '
          '"$url"';

      final result = await execute(command, 'Chromium image opened');

      return result != null;
    } catch (e) {
      debugPrint('Error showing image in Chromium: $e');
      return false;
    }
  }

  Future<bool> closeChromiumAndRestoreLG() async {
    try {
      await execute(
        'killall chromium-browser || killall chromium || true',
        'Chromium closed',
      );

      await Future.delayed(const Duration(seconds: 1));

      await sendLogo();

      return true;
    } catch (e) {
      debugPrint('Error closing Chromium: $e');
      return false;
    }
  }

  Future<bool> showDinosaurNormalOverlay(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);

    final assetPath = await getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_normal',
    );

    if (assetPath == null) {
      debugPrint('Normal image not found for ${dinosaur.name}');
      return false;
    }

    final extension = assetPath.split('.').last;

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

    if (assetPath == null) {
      debugPrint('Skeleton image not found for ${dinosaur.name}');
      return false;
    }

    final extension = assetPath.split('.').last;

    return await showImageInChromium(
      assetPath: assetPath,
      fileName: '${cleanName}_skeleton.$extension',
    );
  }

  Future<bool> showDinosaurComparisonImage(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);

    final assetPath = await getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_comparison',
    );

    if (assetPath == null) {
      debugPrint('Comparison image not found for ${dinosaur.name}');
      return false;
    }

    final extension = assetPath.split('.').last;

    return await showImageInChromium(
      assetPath: assetPath,
      fileName: '${cleanName}_comparison.$extension',
    );
  }

  Future<bool> reboot() async {
    try {
      for (int i = _lgConnectionModel.screens; i >= 1; i--) {
        final command =
            'sshpass -p ${_lgConnectionModel.password} '
            'ssh -t lg$i '
            '"echo ${_lgConnectionModel.password} | sudo -S reboot"';

        await execute(command, 'Screen $i rebooted');

        await Future.delayed(const Duration(seconds: 2));
      }

      disconnect();

      return true;
    } catch (e) {
      debugPrint('Error rebooting LG: $e');
      return false;
    }
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

  Future<bool> shutdown() async {
    try {
      for (int i = _lgConnectionModel.screens; i >= 1; i--) {
        final command =
            'sshpass -p ${_lgConnectionModel.password} '
            'ssh -t lg$i '
            '"echo ${_lgConnectionModel.password} | sudo -S shutdown now"';

        await execute(command, 'Screen $i shutdown');

        await Future.delayed(const Duration(seconds: 2));
      }

      disconnect();

      return true;
    } catch (e) {
      debugPrint('Error shutting down LG: $e');
      return false;
    }
  }

  Future<bool> showPyramidDemo() async {
    return await flyTo(
      '<LookAt>'
      '<longitude>0.6224</longitude>'
      '<latitude>41.6170</latitude>'
      '<range>8000</range>'
      '<tilt>45</tilt>'
      '<heading>0</heading>'
      '<altitudeMode>relativeToGround</altitudeMode>'
      '</LookAt>',
    );
  }

  int getScreenNumber() {
    return _lgConnectionModel.screens;
  }
}
