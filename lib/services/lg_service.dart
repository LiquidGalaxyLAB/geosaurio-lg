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

  Future<void> _initializeLiquidGalaxyContent() async {
    if (_initializingAfterConnection || !_isConnected || _client == null) {
      return;
    }

    _initializingAfterConnection = true;

    try {
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('Sending logo');
      final logoSent = await sendLogo();
      debugPrint('Logo result: $logoSent');

      debugPrint('Starting all dinosaur markers');
      await showAllDinosaurMarkers();

      debugPrint('Connection initialization completed');
    } catch (e, stackTrace) {
      debugPrint('Error initializing Liquid Galaxy content: $e');
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
        debugPrint('Cannot upload $fileName: SSH is not connected');
        return false;
      }

      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(bytes.buffer.asUint8List());

      final sftp = await _client!.sftp();

      final remoteFile = await sftp.open(
        '/var/www/html/$fileName',
        mode:
        SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(
        Stream.value(Uint8List.fromList(await file.readAsBytes())),
      );

      await remoteFile.close();

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error uploading $assetPath as $fileName: $e');
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

  Future<bool> showDinosaurAboutBalloon(Dinosaur dinosaur) async {
    try {
      if (dinosaur.latitude == 0 || dinosaur.longitude == 0) {
        debugPrint('Cannot show balloon: invalid dinosaur coordinates');
        return false;
      }

      final cleanName = cleanDinosaurImageName(dinosaur.name);

      final assetPath = await getExistingImagePath(
        'assets/images/dinosaurs/${cleanName}_normal',
      );

      String imageHtml = '';

      if (assetPath != null) {
        final extension = assetPath.split('.').last;
        final imageFileName = '${cleanName}_normal.$extension';

        final uploadedImage = await uploadAssetToLG(
          assetPath: assetPath,
          fileName: imageFileName,
        );

        if (uploadedImage) {
          imageHtml = '''
<img
  src="http://lg1:81/$imageFileName"
  style="
    display: block;
    width: 100%;
    max-height: 280px;
    object-fit: contain;
    margin: 0 auto 18px auto;
  "
/>
''';
        }
      }

      final name = _escapeHtml(dinosaur.name);
      final period = _escapeHtml(dinosaur.periodName);
      final time1 = _escapeHtml(dinosaur.time1);
      final time2 = _escapeHtml(dinosaur.time2);
      final diet = _escapeHtml(dinosaur.diet);
      final length = _escapeHtml(dinosaur.length);
      final weight = _escapeHtml(dinosaur.weight);
      final country = _escapeHtml(dinosaur.country);
      final region = _escapeHtml(dinosaur.region);
      final formation = _escapeHtml(dinosaur.formation);
      final habitat = _escapeHtml(dinosaur.habitat);
      final description = _escapeHtml(dinosaur.generalInfo);

      final balloonKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Selected Dinosaur Balloon</name>

    <Style id="selectedDinosaurStyle">
      <IconStyle>
        <scale>0</scale>
      </IconStyle>

      <LabelStyle>
        <scale>0</scale>
      </LabelStyle>

      <BalloonStyle>
        <bgColor>fff7f4ef</bgColor>
        <textColor>ff111111</textColor>

        <text><![CDATA[
          <div style="
            width: 520px;
            padding: 20px;
            box-sizing: border-box;
            font-family: Arial, sans-serif;
            color: #111111;
          ">
            <h1 style="
              margin: 0;
              font-size: 30px;
              text-align: center;
            ">
              $name
            </h1>

            <p style="
              margin: 7px 0 18px 0;
              text-align: center;
              font-size: 16px;
              color: #666666;
            ">
              $period · $time1 - $time2
            </p>

            $imageHtml

            <table style="
              width: 100%;
              border-collapse: collapse;
              font-size: 16px;
            ">
              <tr>
                <td style="
                  padding: 8px;
                  font-weight: bold;
                  border-bottom: 1px solid #dddddd;
                ">
                  Diet
                </td>

                <td style="
                  padding: 8px;
                  border-bottom: 1px solid #dddddd;
                ">
                  $diet
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 8px;
                  font-weight: bold;
                  border-bottom: 1px solid #dddddd;
                ">
                  Length
                </td>

                <td style="
                  padding: 8px;
                  border-bottom: 1px solid #dddddd;
                ">
                  $length
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 8px;
                  font-weight: bold;
                  border-bottom: 1px solid #dddddd;
                ">
                  Weight
                </td>

                <td style="
                  padding: 8px;
                  border-bottom: 1px solid #dddddd;
                ">
                  $weight
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 8px;
                  font-weight: bold;
                  border-bottom: 1px solid #dddddd;
                ">
                  Country
                </td>

                <td style="
                  padding: 8px;
                  border-bottom: 1px solid #dddddd;
                ">
                  $country
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 8px;
                  font-weight: bold;
                  border-bottom: 1px solid #dddddd;
                ">
                  Region
                </td>

                <td style="
                  padding: 8px;
                  border-bottom: 1px solid #dddddd;
                ">
                  $region
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 8px;
                  font-weight: bold;
                  border-bottom: 1px solid #dddddd;
                ">
                  Formation
                </td>

                <td style="
                  padding: 8px;
                  border-bottom: 1px solid #dddddd;
                ">
                  $formation
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 8px;
                  font-weight: bold;
                ">
                  Habitat
                </td>

                <td style="padding: 8px;">
                  $habitat
                </td>
              </tr>
            </table>

            <p style="
              margin: 20px 0 0 0;
              font-size: 16px;
              line-height: 1.45;
              text-align: justify;
            ">
              $description
            </p>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>

    <Placemark id="selectedDinosaur">
      <name>$name</name>
      <styleUrl>#selectedDinosaurStyle</styleUrl>

      <Point>
        <altitudeMode>clampToGround</altitudeMode>
        <coordinates>${dinosaur.longitude},${dinosaur.latitude},0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final balloonFileName = 'selected_dinosaur_$timestamp.kml';

      final uploadedKml = await uploadBytesToLG(
        bytes: Uint8List.fromList(balloonKml.codeUnits),
        fileName: balloonFileName,
      );

      if (!uploadedKml) {
        debugPrint('Could not upload dinosaur balloon KML');
        return false;
      }

      final loadResult = await execute(
        "echo 'http://lg1:81/$balloonFileName' > /var/www/html/kmls.txt",
        'Dinosaur balloon KML loaded',
      );

      if (loadResult == null) {
        return false;
      }

      await Future.delayed(const Duration(seconds: 1));

      final balloonResult = await execute(
        "echo 'balloon=selectedDinosaur' > /tmp/query.txt",
        'Dinosaur balloon opened',
      );

      return balloonResult != null;
    } catch (e, stackTrace) {
      debugPrint('Error showing dinosaur balloon: $e');
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
      final dinosaurs = await DinosaurService.loadDinosaurs();
      await showDinosaurMarkers(dinosaurs);
    } catch (e) {
      debugPrint('Error showing all dinosaur markers: $e');
    }
  }

  Future<bool> showDinosaurMarkers(List<Dinosaur> dinosaurs) async {
    try {
      debugPrint('1. showDinosaurMarkers started');
      debugPrint('Dinosaurs received: ${dinosaurs.length}');

      final validDinosaurs = dinosaurs.where((dinosaur) {
        return dinosaur.latitude != 0 && dinosaur.longitude != 0;
      }).toList();

      debugPrint('2. Valid dinosaurs: ${validDinosaurs.length}');

      if (validDinosaurs.isEmpty) {
        debugPrint('No valid dinosaur coordinates');
        return false;
      }

      final markerUploaded = await uploadAssetToLG(
        assetPath: 'assets/images/markers/dino_marker.png',
        fileName: 'dino_marker.png',
      );

      debugPrint('3. Marker image uploaded: $markerUploaded');

      if (!markerUploaded) {
        debugPrint('Could not upload dino marker');
        return false;
      }

      final placemarks = validDinosaurs.map((dinosaur) {
        final name = _cleanText(dinosaur.name);
        final country = _cleanText(dinosaur.country);
        final region = _cleanText(dinosaur.region);

        debugPrint(
          'Creating marker: ${dinosaur.name} '
              'lat=${dinosaur.latitude}, lon=${dinosaur.longitude}',
        );

        return '''
<Placemark>
  <name>$name</name>
  <description>$country - $region</description>
  <Style>
    <IconStyle>
      <scale>1.5</scale>
      <Icon>
        <href>http://lg1:81/dino_marker.png</href>
      </Icon>
      <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
    </IconStyle>
    <LabelStyle>
      <scale>0.8</scale>
    </LabelStyle>
  </Style>
  <Point>
    <altitudeMode>clampToGround</altitudeMode>
    <coordinates>${dinosaur.longitude},${dinosaur.latitude},0</coordinates>
  </Point>
</Placemark>
''';
      }).join('\n');

      debugPrint('4. Placemarks generated');

      final markersKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>GeoSaurio Dinosaur Markers</name>
    $placemarks
  </Document>
</kml>''';

      final markersUploaded = await uploadBytesToLG(
        bytes: Uint8List.fromList(markersKml.codeUnits),
        fileName: 'geosaurio_markers.kml',
      );

      debugPrint('5. Marker KML uploaded: $markersUploaded');

      if (!markersUploaded) {
        debugPrint('KML upload failed');
        return false;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final networkLinkKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>GeoSaurio Markers Loader</name>
    <NetworkLink>
      <name>Dinosaur Markers</name>
      <open>1</open>
      <Link>
        <href>http://lg1:81/geosaurio_markers.kml?v=$timestamp</href>
        <refreshMode>onInterval</refreshMode>
        <refreshInterval>2</refreshInterval>
        <viewRefreshMode>never</viewRefreshMode>
      </Link>
    </NetworkLink>
  </Document>
</kml>''';

      final loaderUploaded = await uploadBytesToLG(
        bytes: Uint8List.fromList(networkLinkKml.codeUnits),
        fileName: 'kml/slave_1.kml',
      );

      debugPrint('6. NetworkLink loader uploaded: $loaderUploaded');

      if (!loaderUploaded) {
        debugPrint('Could not write NetworkLink to slave_1.kml');
        return false;
      }

      debugPrint('7. showDinosaurMarkers finished');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error showing dinosaur markers: $e');
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
