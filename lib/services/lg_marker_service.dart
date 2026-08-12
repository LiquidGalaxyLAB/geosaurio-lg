import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/dinosaur.dart';
import 'lg_service.dart';

class LgMarkerService {
  final LgService _lgService;

  LgMarkerService(this._lgService);

  String _cleanText(String value) {   // Clean text before using it inside KML
    return value
        .replaceAll('&', 'and')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .trim();
  }

  Future<bool> showDinosaurSelectionMarkers(List<Dinosaur> dinosaurs) async {   // Show the dinosaur markers in Google Earth
    try {
      if (!_lgService.isConnected) {
        debugPrint(
          'Cannot show dinosaur markers: '
          'Liquid Galaxy is not connected',
        );
        return false;
      }

      final validDinosaurs = dinosaurs.where((dinosaur) { // Get dinosaurs with valid coordinates
        return dinosaur.latitude != 0 && dinosaur.longitude != 0;
      }).toList();

      if (validDinosaurs.isEmpty) {
        debugPrint(
          'No dinosaurs with valid coordinates '
          'for this selection',
        );
        return false;
      }

      debugPrint(
        'Creating ${validDinosaurs.length} '
        'dinosaur placemarks',
      );

      // Upload the marker image to Liquid Galaxy

      final markerUploaded = await _lgService.uploadAssetToLG(
        assetPath: 'assets/images/markers/dino_marker.png',
        fileName: 'kml/dino_marker.png',
      );

      if (!markerUploaded) {
        debugPrint('Could not upload dinosaur marker icon');
        return false;
      }


      // Create one Placemark for each dinosaur

      final placemarks = validDinosaurs.map((dinosaur) {
        final safeName = _cleanText(dinosaur.name);

        debugPrint(
          'PLACEMARK: ${dinosaur.name} | '
          'lat=${dinosaur.latitude} | '
          'lon=${dinosaur.longitude}',
        );

        return '''
<Placemark>
  <name>$safeName</name>
  <styleUrl>#dinoMarkerStyle</styleUrl>
  <Point>
    <altitudeMode>clampToGround</altitudeMode>
    <coordinates>${dinosaur.longitude},${dinosaur.latitude},0</coordinates>
  </Point>
</Placemark>
''';
      }).join('\n');

      // Create the KML with all dinosaur markers

      final kml = ''' 
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>GeoSaurio Dinosaur Locations</name>
  <Style id="dinoMarkerStyle">
    <IconStyle>
      <scale>1.2</scale>
      <Icon>
        <href>http://lg1:81/kml/dino_marker.png</href>
      </Icon>
      <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
    </IconStyle>
  </Style>
  $placemarks
</Document>
</kml>
''';

      final logoScreen =
          _lgService.calculateLeftMostScreen(_lgService.connectionModel.screens);
      final rightScreen =
          _lgService.calculateRightMostScreen(_lgService.connectionModel.screens);

      await _lgService.execute(
        '''sed -i '\\|master.kml|d' /var/www/html/kmls.txt''',
        'Old master marker reference removed',
      );

      for (int screen = 1; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen || screen == rightScreen) {
          continue;
        }

        await _lgService.execute(
          '''sed -i '\\|slave_$screen.kml|d' /var/www/html/kmls.txt''',
          'Old slave_$screen marker reference removed',
        );
      }

      final masterResult = await _lgService.execute(
        '''
cat > /var/www/html/kml/master.kml << 'EOFKML'
$kml
EOFKML
''',
        'Dinosaur markers written to master.kml',
      );

      if (masterResult == null) {
        return false;
      }

      final registerMasterResult = await _lgService.execute(
        'echo "http://lg1:81/kml/master.kml" >> /var/www/html/kmls.txt',
        'Master dinosaur markers registered',
      );

      if (registerMasterResult == null) {
        return false;
      }

      for (int screen = 1; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen || screen == rightScreen) {
          debugPrint('Skipping slave_$screen to preserve overlay');
          continue;
        }

        final slaveResult = await _lgService.execute(
          '''
cat > /var/www/html/kml/slave_$screen.kml << 'EOFKML'
$kml
EOFKML
''',
          'Dinosaur markers written to slave_$screen.kml',
        );

        if (slaveResult == null) {
          return false;
        }

        final registerSlaveResult = await _lgService.execute(
          'echo "http://lg1:81/kml/slave_$screen.kml" >> /var/www/html/kmls.txt',
          'Dinosaur markers slave_$screen registered',
        );

        if (registerSlaveResult == null) {
          return false;
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final refreshResult = await _lgService.execute(
        'echo "search=http://lg1:81/kmls.txt" > /tmp/query.txt',
        'Dinosaur markers loaded',
      );

      if (refreshResult == null) {
        return false;
      }

      for (int screen = 2; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen || screen == rightScreen) {
          continue;
        }

        await _lgService.forceRefresh(screen);
      }

      await _lgService.sendLogo();

      debugPrint(
        '${validDinosaurs.length} '
        'dinosaur placemarks displayed successfully',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error showing dinosaur placemarks: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> cleanDinosaurSelectionMarkers() async {   // Remove the dinosaur selection markers
    try {
      if (!_lgService.isConnected) {
        return false;
      }

      await _lgService.execute(
        '''sed -i '\\|dinosaur_selection_markers.kml|d' /var/www/html/kmls.txt''',
        'Dinosaur selection marker reference removed',
      );

      const emptyKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
  </Document>
</kml>
''';

      await _lgService.execute(
        '''
cat > /var/www/html/kml/dinosaur_selection_markers.kml << 'EOFKML'
$emptyKml
EOFKML
''',
        'Dinosaur selection markers cleaned',
      );

      final result = await _lgService.execute(
        '''echo "search=http://lg1:81/kmls.txt" > /tmp/query.txt''',
        'Google Earth refreshed after marker cleanup',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint('Error cleaning dinosaur selection markers: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> showSelectedDinosaurCube(Dinosaur dinosaur) async { // Show the cube for the selected dinosaur
    try {
      if (!_lgService.isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      if (dinosaur.latitude == 0 || dinosaur.longitude == 0) {
        debugPrint('Invalid coordinates for ${dinosaur.name}');
        return false;
      }

      // Size and height of the cube

      const double radius = 0.0025;
      const double altitude = 30.0;

      // Calculate the cube position

      final cubePosition = _lgService.calculateCubePosition(dinosaur);
      final double latitude = cubePosition['latitude']!;
      final double longitude = cubePosition['longitude']!;

      // Calculate the four sides of the cube

      final double north = latitude + radius;
      final double south = latitude - radius;
      final double east = longitude + radius;
      final double west = longitude - radius;

      final safeName = _cleanText(dinosaur.name);

      // Create the cube using KML polygons

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
          _lgService.calculateLeftMostScreen(_lgService.connectionModel.screens);

      await _lgService.execute(
        '> /var/www/html/kmls.txt',
        'Old cube removed',
      );

      await _lgService.execute(
        '''
cat > /var/www/html/kml/master.kml << 'EOFKML'
$kml
EOFKML
''',
        'Master cube written',
      );

      await _lgService.execute(
        'echo "http://lg1:81/kml/master.kml" >> /var/www/html/kmls.txt',
        'Master registered',
      );

      for (int screen = 1; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen) {
          continue;
        }

        await _lgService.execute(
          '''
cat > /var/www/html/kml/slave_$screen.kml << 'EOFKML'
$kml
EOFKML
''',
          'Slave cube written',
        );

        await _lgService.execute(
          'echo "http://lg1:81/kml/slave_$screen.kml" >> /var/www/html/kmls.txt',
          'Slave registered',
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      await _lgService.execute(
        'echo "search=http://lg1:81/kmls.txt" > /tmp/query.txt',
        'Cube refreshed',
      );

      for (int screen = 2; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen) {
          continue;
        }

        await _lgService.forceRefresh(screen);
      }

      debugPrint('Open cube shown for ${dinosaur.name}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error showing selected cube: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> cleanDinosaurMarkers() async { //Remove dinosaur markers and cubes
    try {
      if (!_lgService.isConnected) {
        debugPrint('SSH client is not connected');
        return false;
      }

      final int logoScreen =
          _lgService.calculateLeftMostScreen(_lgService.connectionModel.screens);

      // Use an empty KML to clean the screens

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

      final masterResult = await _lgService.execute(
        clearMasterCommand,
        'master.kml cleaned',
      );

      if (masterResult == null) {
        return false;
      }

      for (int screen = 1; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen) {
          debugPrint('Skipping slave_$screen.kml to preserve logo');
          continue;
        }

        final String clearSlaveCommand = '''
cat > /var/www/html/kml/slave_$screen.kml << 'EOFKML'
$emptyKml
EOFKML
''';

        final slaveResult = await _lgService.execute(
          clearSlaveCommand,
          'slave_$screen.kml cleaned',
        );

        if (slaveResult == null) {
          return false;
        }
      }

      final clearListResult = await _lgService.execute(
        '> /var/www/html/kmls.txt',
        'KML list cleared',
      );

      if (clearListResult == null) {
        return false;
      }

      final registerMasterResult = await _lgService.execute(
        'echo "http://lg1:81/kml/master.kml" >> /var/www/html/kmls.txt',
        'Empty master.kml registered',
      );

      if (registerMasterResult == null) {
        return false;
      }

      for (int screen = 1; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen) {
          continue;
        }

        final registerSlaveResult = await _lgService.execute(
          'echo "http://lg1:81/kml/slave_$screen.kml" >> /var/www/html/kmls.txt',
          'Empty slave_$screen.kml registered',
        );

        if (registerSlaveResult == null) {
          return false;
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final refreshResult = await _lgService.execute(
        'echo "search=http://lg1:81/kmls.txt" > /tmp/query.txt',
        'Empty KML loaded on master',
      );

      if (refreshResult == null) {
        return false;
      }

      for (int screen = 2; screen <= _lgService.connectionModel.screens; screen++) {
        if (screen == logoScreen) {
          continue;
        }

        await _lgService.forceRefresh(screen);
      }

      final logoSent = await _lgService.sendLogo();

      if (!logoSent) {
        debugPrint('Markers cleaned, but logo could not be restored');
      }

      debugPrint(
        'Dinosaur cubes cleaned successfully while preserving logo',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error cleaning dinosaur markers: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
