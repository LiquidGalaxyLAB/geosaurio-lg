import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/dinosaur.dart';
import 'lg_service.dart';

class LgOrbitService {
  final LgService _lgService;

  bool _isDinosaurOrbiting = false;
  Timer? _dinosaurOrbitTimer;

  LgOrbitService(this._lgService);

  bool get isDinosaurOrbiting => _isDinosaurOrbiting;

  String _buildDinosaurOrbitLookAt({
    required double latitude,
    required double longitude,
    required double range,
    required double tilt,
    required double heading,
  }) {
    return '<gx:duration>0.3</gx:duration>'
        '<gx:flyToMode>smooth</gx:flyToMode>'
        '<LookAt>'
        '<longitude>$longitude</longitude>'
        '<latitude>$latitude</latitude>'
        '<range>$range</range>'
        '<tilt>$tilt</tilt>'
        '<heading>$heading</heading>'
        '<altitudeMode>relativeToGround</altitudeMode>'
        '</LookAt>';
  }

  Future<bool> _flyToDinosaurOrbit({
    required double latitude,
    required double longitude,
    required double range,
    required double tilt,
    required double heading,
  }) async {
    try {
      if (!_lgService.isConnected) {
        return false;
      }

      final lookAt = _buildDinosaurOrbitLookAt(
        latitude: latitude,
        longitude: longitude,
        range: range,
        tilt: tilt,
        heading: heading,
      );

      final result = await _lgService.execute(
        'echo "flytoview=$lookAt" > /tmp/query.txt',
        'Orbit view sent: heading=$heading',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 50,
        ),
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint(
        'Error sending orbit view: $e',
      );
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> startDinosaurOrbit(Dinosaur dinosaur) async {
    if (_isDinosaurOrbiting) {
      return false;
    }

    if (!_lgService.isConnected) {
      debugPrint(
        'Cannot start dinosaur orbit: '
        'Liquid Galaxy is not connected',
      );
      return false;
    }

    try {
      final cubePosition = _lgService.calculateCubePosition(dinosaur);

      final double latitude = cubePosition['latitude']!;
      final double longitude = cubePosition['longitude']!;

      const double orbitRange = 610.0;
      const double orbitTilt = 72.0;

      const int steps = 60;
      const int stepDuration = 400;

      int currentStep = 0;
      bool isMoving = false;
      final double startHeading = dinosaur.heading;

      _isDinosaurOrbiting = true;
      _lgService.notifyListeners();

      debugPrint('ORBIT: START');
      debugPrint('ORBIT: latitude=$latitude');
      debugPrint('ORBIT: longitude=$longitude');
      debugPrint('ORBIT: range=$orbitRange');
      debugPrint('ORBIT: tilt=$orbitTilt');

      _dinosaurOrbitTimer?.cancel();
      _dinosaurOrbitTimer = Timer.periodic(
        const Duration(
          milliseconds: stepDuration,
        ),
        (timer) async {
          if (!_isDinosaurOrbiting) {
            timer.cancel();
            return;
          }

          if (isMoving) {
            return;
          }

          try {
            isMoving = true;
            double heading = startHeading + (currentStep * (360.0 / steps));
            heading %= 360.0;

            await _flyToDinosaurOrbit(
              latitude: latitude,
              longitude: longitude,
              range: orbitRange,
              tilt: orbitTilt,
              heading: heading,
            );

            currentStep++;
            if (currentStep >= steps) {
              currentStep = 0;
            }
          } catch (e) {
            debugPrint(
              'Error during dinosaur orbit '
              'step $currentStep: $e',
            );
          } finally {
            isMoving = false;
          }
        },
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Error starting dinosaur orbit: $e',
      );
      debugPrint('$stackTrace');

      _dinosaurOrbitTimer?.cancel();
      _dinosaurOrbitTimer = null;
      _isDinosaurOrbiting = false;
      _lgService.notifyListeners();

      return false;
    }
  }

  Future<void> stopDinosaurOrbit() async {
    _dinosaurOrbitTimer?.cancel();
    _dinosaurOrbitTimer = null;
    _isDinosaurOrbiting = false;
    _lgService.notifyListeners();

    debugPrint(
      'ORBIT: STOP',
    );
  }
}
