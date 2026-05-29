import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Timer? _orbitTimer;
  Timer? _connectionTimer;

  bool _isTrailPlaying = false;
  bool _orbitPlaying = false;
  bool _isConnected = false;
  bool _isCheckingConnection = false;

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

      await sendLogo();

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
    return await query('flytoview=$kmlViewTag');
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

  Future<bool> cleanAll() async {
    try {
      const emptyKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
</Document>
</kml>
''';

      await execute(
        '> /var/www/html/kmls.txt',
        'KMLs cleaned',
      );

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
    final leftMostScreen =
    calculateLeftMostScreen(_lgConnectionModel.screens);

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
    final leftMostScreen =
    calculateLeftMostScreen(_lgConnectionModel.screens);

    const String kmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
    <name>Logo</name>
    <ScreenOverlay>
        <name>Logo</name>
        <Icon>
          <href>https://raw.githubusercontent.com/LiquidGalaxyLAB/liquid-galaxy/main/assets/logo.png</href>
        </Icon>
        <overlayXY x="0" y="0" xunits="fraction" yunits="fraction"/>
        <screenXY x="0.02" y="0.75" xunits="fraction" yunits="fraction"/>
        <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
        <size x="450" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
</Document>
</kml>
''';

    final result = await execute(
      "echo '$kmlContent' > /var/www/html/kml/slave_$leftMostScreen.kml",
      'Logo sent',
    );

    return result != null;
  }

  Future<bool> reboot() async {
    try {
      for (int i = _lgConnectionModel.screens; i >= 1; i--) {
        final command = i == 1
            ? 'echo ${_lgConnectionModel.password} | sudo -S reboot'
            : 'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "echo ${_lgConnectionModel.password} | sudo -S reboot"';

        await execute(command, 'Screen $i rebooted');
      }

      disconnect();
      return true;
    } catch (e) {
      debugPrint('Error rebooting LG: $e');
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

  Future<bool> shutdown() async {
    try {
      for (int i = _lgConnectionModel.screens; i >= 1; i--) {
        final shutdownCommand =
            'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i '
            '"echo ${_lgConnectionModel.password} | sudo -S shutdown now"';

        await execute(
          shutdownCommand,
          'Screen $i shutdown',
        );
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