import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/dinosaur.dart';
import 'lg_service.dart';

class LgOrbitService {
  final LgService _lgService;

  // Orbit state and timer
  bool _isDinosaurOrbiting = false;
  Timer? _dinosaurOrbitTimer;

  LgOrbitService(this._lgService);

  bool get isDinosaurOrbiting => _isDinosaurOrbiting;

  // Create the LookAt used for each step of the orbit
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

  // Send one orbit movement to Liquid Galaxy
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

      // Build the camera position
      final lookAt = _buildDinosaurOrbitLookAt(
        latitude: latitude,
        longitude: longitude,
        range: range,
        tilt: tilt,
        heading: heading,
      );

      // Send the new camera heading through SSH
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

  // Start the 360 degree orbit around the dinosaur
  Future<bool> startDinosaurOrbit(Dinosaur dinosaur) async {
    // Avoid starting another orbit if one is already running
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
      // Use the same position as the dinosaur cube
      final cubePosition =
      _lgService.calculateCubePosition(dinosaur);

      final double latitude =
      cubePosition['latitude']!;
      final double longitude =
      cubePosition['longitude']!;

      // Keep the camera distance and tilt fixed
      const double orbitRange = 610.0;
      const double orbitTilt = 72.0;

      // Divide the complete 360 degree orbit into 60 steps
      const int steps = 60;
      const int stepDuration = 400;

      int currentStep = 0;
      bool isMoving = false;

      // Start from the dinosaur original heading
      final double startHeading = dinosaur.heading;

      _isDinosaurOrbiting = true;
      _lgService.notifyListeners();

      debugPrint('ORBIT: START');
      debugPrint('ORBIT: latitude=$latitude');
      debugPrint('ORBIT: longitude=$longitude');
      debugPrint('ORBIT: range=$orbitRange');
      debugPrint('ORBIT: tilt=$orbitTilt');

      // Run one orbit step every 400 ms
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

          // Avoid sending two movements at the same time
          if (isMoving) {
            return;
          }

          try {
            isMoving = true;

            // Change only the heading to rotate around the dinosaur
            double heading =
                startHeading +
                    (currentStep * (360.0 / steps));

            heading %= 360.0;

            // Send the next position of the orbit
            await _flyToDinosaurOrbit(
              latitude: latitude,
              longitude: longitude,
              range: orbitRange,
              tilt: orbitTilt,
              heading: heading,
            );

            currentStep++;

            // Start again after completing 360 degrees
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

  // Stop the current orbit
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