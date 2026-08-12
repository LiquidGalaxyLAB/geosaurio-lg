import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../models/dinosaur.dart';

import 'lg_orbit_service.dart';
import 'lg_navigation_service.dart';
import 'lg_marker_service.dart';
import 'lg_overlay_service.dart';
import 'lg_media_service.dart';
import 'lg_system_service.dart';

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
  LgService._internal() {
    _orbitService = LgOrbitService(this);
    _navigationService = LgNavigationService(this);
    _markerService = LgMarkerService(this);
    _overlayService = LgOverlayService(this);
    _mediaService = LgMediaService(this);
    _systemService = LgSystemService(this);
  }

  static final LgService _singleton = LgService._internal();

  factory LgService() => _singleton;

  late final LgOrbitService _orbitService;
  late final LgNavigationService _navigationService;
  late final LgMarkerService _markerService;
  late final LgOverlayService _overlayService;
  late final LgMediaService _mediaService;
  late final LgSystemService _systemService;

  final LgConnectionModel _lgConnectionModel = LgConnectionModel();

  SSHClient? _client;
  bool _isConnected = false;
  int _currentConnectionAttempts = 0;

  Future<bool?>? _connectionInProgress;
  bool _initializingAfterConnection = false;

  static const int _maxConnectionAttempts = 5;
  static const Duration _connectionTimeout = Duration(seconds: 10);

  // Getters for status
  LgConnectionModel get connectionModel => _lgConnectionModel;
  bool get isConnected => _isConnected;
  bool get isDinosaurOrbiting => _orbitService.isDinosaurOrbiting;

  // Connection management
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
      debugPrint('Connection initialization completed');
    } catch (e, stackTrace) {
      debugPrint('Error initializing Liquid Galaxy content: $e');
      debugPrint('$stackTrace');
    } finally {
      _initializingAfterConnection = false;
    }
  }

  void disconnect() {
    _orbitService.stopDinosaurOrbit();
    _client?.close();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<dynamic> execute(String command, String successMessage) async {
    if (_client == null || !_isConnected) {
      debugPrint('SSH client not connected. Trying reconnect...');
      final connected = await connectToLG(initializeAfterConnect: false);
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
      final connected = await connectToLG(initializeAfterConnect: false);
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

  // File Transfer Helpers
  Future<bool> uploadAssetToLG({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final connected = await connectToLG(initializeAfterConnect: false);
      if (connected != true || _client == null) {
        debugPrint('Cannot upload $fileName: SSH is not connected');
        return false;
      }
      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final localFileName = fileName.split('/').last;
      final file = File('${tempDir.path}/$localFileName');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      final sftp = await _client!.sftp();
      final remotePath = '/var/www/html/$fileName';
      debugPrint('Uploading $assetPath to $remotePath');

      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.truncate | SftpFileOpenMode.write,
      );
      await remoteFile.write(Stream.value(Uint8List.fromList(await file.readAsBytes())));
      await remoteFile.close();
      debugPrint('Asset uploaded successfully to $remotePath');
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
      final connected = await connectToLG(initializeAfterConnect: false);
      if (connected != true || _client == null) {
        debugPrint('Cannot upload $fileName: SSH is not connected');
        return false;
      }
      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        '/var/www/html/$fileName',
        mode: SftpFileOpenMode.create | SftpFileOpenMode.truncate | SftpFileOpenMode.write,
      );
      await remoteFile.write(Stream.value(bytes));
      await remoteFile.close();
      return true;
    } catch (e) {
      debugPrint('Error uploading bytes: $e');
      return false;
    }
  }

  // Shared Utility Methods
  int calculateLeftMostScreen(int screenCount) => _systemService.calculateLeftMostScreen(screenCount);
  int calculateRightMostScreen(int screenCount) => _systemService.calculateRightMostScreen(screenCount);
  
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
    final extensions = ['.png', '.jpg', '.jpeg', '.jfif', '.PNG', '.JPG', '.JPEG', '.JFIF'];
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
          debugPrint('Found dinosaur image: $path');
          return path;
        } catch (_) {}
      }
    }
    debugPrint('Image not found: $basePath');
    return null;
  }

  Map<String, double> calculateCubePosition(Dinosaur dinosaur) =>
      _navigationService.calculateCubePosition(dinosaur);

  Future<void> forceRefresh(int screenNumber) => _systemService.forceRefresh(screenNumber);
  
  void notify() => notifyListeners();

  // Orbit Wrappers
  Future<bool> startDinosaurOrbit(Dinosaur dinosaur) => _orbitService.startDinosaurOrbit(dinosaur);
  Future<void> stopDinosaurOrbit() => _orbitService.stopDinosaurOrbit();

  // Navigation Wrappers
  Future<bool> flyToDinosaur(Dinosaur dinosaur) => _navigationService.flyToDinosaur(dinosaur);
  Future<bool> flyToContinent(String continent) => _navigationService.flyToContinent(continent);
  Future<bool> flyToCountry(String country, String continent, List<Dinosaur> dinosaurs) =>
      _navigationService.flyToCountry(country, continent, dinosaurs);
  Future<bool> flyToMapPosition({required double latitude, required double longitude, required double zoom, double bearing = 0}) =>
      _navigationService.flyToMapPosition(latitude: latitude, longitude: longitude, zoom: zoom, bearing: bearing);

  // Marker Wrappers
  Future<bool> showDinosaurSelectionMarkers(List<Dinosaur> dinosaurs) =>
      _markerService.showDinosaurSelectionMarkers(dinosaurs);
  Future<bool> cleanDinosaurSelectionMarkers() => _markerService.cleanDinosaurSelectionMarkers();
  Future<bool> showSelectedDinosaurCube(Dinosaur dinosaur) =>
      _markerService.showSelectedDinosaurCube(dinosaur);
  Future<bool> cleanDinosaurMarkers() => _markerService.cleanDinosaurMarkers();

  // Overlay Wrappers
  Future<bool> showDinosaurAboutColumn(Dinosaur dinosaur) => _overlayService.showDinosaurAboutColumn(dinosaur);
  Future<bool> showContinentInfoColumn(String continent) => _overlayService.showContinentInfoColumn(continent);
  Future<bool> showCountryInfoColumn(String country, String continent) =>
      _overlayService.showCountryInfoColumn(country, continent);
  Future<bool> sendLogo() => _overlayService.sendLogo();
  Future<bool> showRightScreenImage({required String assetPath, required String fileName}) =>
      _overlayService.showRightScreenImage(assetPath: assetPath, fileName: fileName);
  Future<bool> cleanRightScreenKml() => _overlayService.cleanRightScreenKml();
  Future<void> cleanLogos() => _overlayService.cleanLogos();

  // Media Wrappers
  Future<bool> showDinosaurSkeletonImage(Dinosaur dinosaur) => _mediaService.showDinosaurSkeletonImage(dinosaur);
  Future<bool> showDinosaurComparisonImage(Dinosaur dinosaur) =>
      _mediaService.showDinosaurComparisonImage(dinosaur);
  Future<bool> openChromiumOnAllScreens(String url) => _mediaService.openChromiumOnAllScreens(url);
  Future<bool> closeChromiumOnAllScreens() => _mediaService.closeChromiumOnAllScreens();

  // System Wrappers
  Future<bool> cleanAll() => _systemService.cleanAll();
  Future<bool> reboot() => _systemService.reboot();
  Future<bool> shutdown() => _systemService.shutdown();
  Future<bool> relaunchLG() => _systemService.relaunchLG();
  Future<bool> writeSoloKml(int machineNo, String kml) => _systemService.writeSoloKml(machineNo, kml);
  Future<bool> notifySoloKmlChanged(int machineNo) => _systemService.notifySoloKmlChanged(machineNo);
  Future<bool> cleanKmlKeepingLogos() => _systemService.cleanKmlKeepingLogos();
}
