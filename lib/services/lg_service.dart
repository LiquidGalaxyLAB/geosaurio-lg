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
    if (_client == null) return null;
    try {
      final result = await _client!.execute(command);
      return result;
    } catch (e) {
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
      return false;
    }
  }

  int calculateLeftMostScreen(int screenCount) => screenCount == 1 ? 1 : (screenCount / 2).floor() + 3;
  int calculateRightMostScreen(int screenCount) => screenCount == 1 ? 1 : (screenCount / 2).floor() + 2;

  String cleanDinosaurImageName(String name) {
    // Elimina espacios extra, espacios especiales NBSP y normaliza para nombres de archivos
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
    
    // Generamos variantes para ser flexibles con mayúsculas y espacios accidentales
    // Por ejemplo, para "Agustinia_ligabuei_normal" probará también con "Agustinia_ligabuei _normal"
    Set<String> variants = {
      basePath,
      basePath.toLowerCase(),
    };

    if (basePath.contains('_')) {
      final lastUnderscore = basePath.lastIndexOf('_');
      final prefix = basePath.substring(0, lastUnderscore);
      final suffix = basePath.substring(lastUnderscore);
      
      // Variante con espacio antes del guion: "Nombre _tipo"
      variants.add('$prefix $suffix');
      variants.add('${prefix.toLowerCase()} $suffix');
      
      // Caso de errata común: "comparison" vs "comparision"
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
          // Intentamos cargar el asset para verificar si existe
          await rootBundle.load(path);
          debugPrint('✅ Encontrado: $path');
          return path;
        } catch (_) {
          // No existe, seguimos buscando
        }
      }
    }
    debugPrint('❌ No se encontró ninguna imagen para: $basePath');
    return null;
  }

  Future<bool> uploadAssetToLG({required String assetPath, required String fileName}) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open('/var/www/html/$fileName', 
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      
      await remoteFile.write(Stream.value(Uint8List.fromList(await file.readAsBytes())));
      await remoteFile.close();
      return true;
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return false;
    }
  }

  Future<bool> sendLogo() async {
    try {
      final screen = calculateLeftMostScreen(_lgConnectionModel.screens);
      final uploaded = await uploadAssetToLG(assetPath: 'assets/images/logos.png', fileName: 'logos.png');
      if (!uploaded) return false;

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"><Document><ScreenOverlay><name>Logo</name><Icon><href>http://lg1:81/logos.png</href></Icon><overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/><screenXY x="0.02" y="0.98" xunits="fraction" yunits="fraction"/><size x="700" y="0" xunits="pixels" yunits="pixels"/></ScreenOverlay></Document></kml>''';
      
      return (await execute("echo '$kml' > /var/www/html/kml/slave_$screen.kml", 'Logo sent')) != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> showRightScreenImage({required String assetPath, required String fileName}) async {
    try {
      final screen = calculateRightMostScreen(_lgConnectionModel.screens);
      final uploaded = await uploadAssetToLG(assetPath: assetPath, fileName: fileName);
      if (!uploaded) return false;

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"><Document><ScreenOverlay><name>Dino Image</name><Icon><href>http://lg1:81/$fileName</href></Icon><overlayXY x="1" y="0.5" xunits="fraction" yunits="fraction"/><screenXY x="0.98" y="0.5" xunits="fraction" yunits="fraction"/><size x="600" y="0" xunits="pixels" yunits="pixels"/></ScreenOverlay></Document></kml>''';
      
      return (await execute("echo '$kml' > /var/www/html/kml/slave_$screen.kml", 'Image sent')) != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> showDinosaurNormalOverlay(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);
    final assetPath = await getExistingImagePath('assets/images/dinosaurs/${cleanName}_normal');
    if (assetPath == null) return false;
    return await showRightScreenImage(assetPath: assetPath, fileName: '${cleanName}_normal.${assetPath.split('.').last}');
  }

  Future<bool> showDinosaurSkeletonImage(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);
    final assetPath = await getExistingImagePath('assets/images/dinosaurs/${cleanName}_skeleton');
    if (assetPath == null) return false;
    return await showRightScreenImage(assetPath: assetPath, fileName: '${cleanName}_skeleton.${assetPath.split('.').last}');
  }

  Future<bool> showDinosaurComparisonImage(Dinosaur dinosaur) async {
    final cleanName = cleanDinosaurImageName(dinosaur.name);
    final assetPath = await getExistingImagePath('assets/images/dinosaurs/${cleanName}_comparison');
    if (assetPath == null) return false;
    return await showRightScreenImage(assetPath: assetPath, fileName: '${cleanName}_comparison.${assetPath.split('.').last}');
  }

  Future<void> cleanLogos() async {
    try {
      final screen = calculateLeftMostScreen(_lgConnectionModel.screens);
      await execute("echo '' > /var/www/html/kml/slave_$screen.kml", 'Logo cleaned');
    } catch (e) {
      debugPrint('Error cleaning logos: $e');
    }
  }

  Future<bool> cleanAll() async {
    try {
      for (var i = 1; i <= _lgConnectionModel.screens; i++) {
        await execute("echo '' > /var/www/html/kml/slave_$i.kml", 'Cleaned screen $i');
      }
      await execute("echo 'exittour=true' > /tmp/query.txt", 'Stop tour');
      await execute("echo '' > /tmp/query.txt", 'Clean query');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reboot() async {
    try {
      for (var i = _lgConnectionModel.screens; i >= 1; i--) {
        await execute(
            'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "echo ${_lgConnectionModel.password} | sudo -S reboot"',
            'Reboot sent to lg$i');
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> shutdown() async {
    try {
      for (var i = _lgConnectionModel.screens; i >= 1; i--) {
        await execute(
            'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "echo ${_lgConnectionModel.password} | sudo -S poweroff"',
            'Shutdown sent to lg$i');
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> relaunchLG() async {
    try {
      for (var i = _lgConnectionModel.screens; i >= 1; i--) {
        final command = """
          sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "DISPLAY=:0 ./bin/lg-relaunch > /dev/null 2>&1 &"
        """;
        await execute(command, 'Relaunch sent to lg$i');
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
