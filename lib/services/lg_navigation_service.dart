import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/dinosaur.dart';
import 'lg_service.dart';

class LgNavigationService {
  final LgService _lgService;

  // Position and zoom for each continent
  final Map<String, List<double>> _continentViews = {
    'Africa': [20.0, 2.0, 9000000.0],
    'Asia': [100.0, 34.0, 11000000.0],
    'Europe': [15.0, 54.0, 6500000.0],
    'North America': [-100.0, 45.0, 9000000.0],
    'South America': [-60.0, -15.0, 9000000.0],
    'Oceania': [135.0, -25.0, 8000000.0],
    'Antarctica': [0.0, -82.0, 9000000.0],
  };

  LgNavigationService(this._lgService);

  // Calculate where the dinosaur cube has to be
  Map<String, double> calculateCubePosition(Dinosaur dinosaur) {
    const double offset = 0.012;
    final heading = dinosaur.heading * math.pi / 180.0;

    return {
      'latitude': dinosaur.latitude + math.cos(heading) * offset,
      'longitude': dinosaur.longitude + math.sin(heading) * offset,
    };
  }

  // Move the camera to the selected dinosaur
  Future<bool> flyToDinosaur(Dinosaur dinosaur) async {
    try {
      if (!_lgService.isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      // Check that the dinosaur has valid coordinates
      if (dinosaur.latitude == 0 || dinosaur.longitude == 0) {
        debugPrint(
          'Invalid coordinates for ${dinosaur.name}: '
          '${dinosaur.latitude}, ${dinosaur.longitude}',
        );
        return false;
      }

      final cubePosition = calculateCubePosition(dinosaur);
      final double cubeLatitude = cubePosition['latitude']!;
      final double cubeLongitude = cubePosition['longitude']!;

      // Camera values
      const double targetAltitude = 15;
      const double fixedTilt = 72.0;
      const double fixedRange = 610.0;

      // Create the LookAt for Google Earth
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

      // Send the movement to Liquid Galaxy
      final result = await _lgService.execute(
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

  // Move the camera to a continent
  Future<bool> flyToContinent(String continent) async {
    try {
      if (!_lgService.isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      // Get the continent position
      final view = _continentViews[continent];

      if (view == null) {
        debugPrint('Unknown continent: $continent');
        return false;
      }

      // Create the LookAt
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

      // Send the movement to Liquid Galaxy
      final result = await _lgService.execute(
        'echo "flytoview=$lookAt" > /tmp/query.txt',
        'FlyTo continent sent: $continent',
      );

      if (result == null) {
        debugPrint('Could not fly to continent: $continent');
        return false;
      }

      // Show the continent information
      final infoShown = await _lgService.showContinentInfoColumn(continent);

      if (!infoShown) {
        debugPrint(
          'Continent FlyTo worked, '
          'but information column could not be shown',
        );
      }

      debugPrint('Continent selected successfully: $continent');

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error flying to continent: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // Move the camera to the selected country
  Future<bool> flyToCountry(
    String country,
    String continent,
    List<Dinosaur> dinosaurs,
  ) async {
    try {
      if (!_lgService.isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      // Get dinosaurs with valid coordinates
      final validDinosaurs = dinosaurs.where((dinosaur) {
        return dinosaur.latitude != 0 && dinosaur.longitude != 0;
      }).toList();

      if (validDinosaurs.isEmpty) {
        debugPrint('No valid dinosaur coordinates found for $country');
        return false;
      }

      // Calculate the center using the dinosaur positions
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

      // Camera distance
      final double range = validDinosaurs.length <= 1 ? 250000.0 : 900000.0;

      // Create the LookAt
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
        'lat=$latitude, '
        'lon=$longitude, '
        'range=$range',
      );

      // Send the movement to Liquid Galaxy
      final result = await _lgService.execute(
        'echo "flytoview=$lookAt" > /tmp/query.txt',
        'FlyTo country sent: $country',
      );

      if (result == null) {
        debugPrint('Could not fly to country: $country');
        return false;
      }

      // Show the country information
      final infoShown = await _lgService.showCountryInfoColumn(
        country,
        continent,
      );

      if (!infoShown) {
        debugPrint(
          'Country FlyTo worked, '
          'but information column could not be shown',
        );
      }

      debugPrint('Country selected successfully: $country');

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error flying to country: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // Synchronize the mini map position with Liquid Galaxy
  Future<bool> flyToMapPosition({
    required double latitude,
    required double longitude,
    required double zoom,
    double bearing = 0,
  }) async {
    try {
      // Convert map zoom to Google Earth range
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

      // Send the map position to Liquid Galaxy
      final result = await _lgService.execute(
        'echo "flytoview=$lookAt" > /tmp/query.txt',
        'Map position sent to Liquid Galaxy',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error synchronizing map with Liquid Galaxy: $e');
      return false;
    }
  }

  // Convert map zoom to the range used by Google Earth
  double _mapZoomToRange(double zoom) {
    final calculatedRange = 40000000.0 / math.pow(2, zoom);
    return calculatedRange.clamp(300.0, 20000000.0).toDouble();
  }
}
