import 'dart:async';
import 'package:flutter/foundation.dart';
import 'lg_service.dart';

class LgSystemService {
  final LgService _lgService;

  LgSystemService(this._lgService);

  Future<void> setRefreshInterval(
    int screenNumber,
    int interval,
  ) async {
    try {
      final search =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>';

      final replace =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>'
          '<refreshMode>onInterval<\\/refreshMode>'
          '<refreshInterval>$interval<\\/refreshInterval>';

      final command =
          'echo ${_lgService.connectionModel.password} | sudo -S '
          'sed -i "s|$search|$replace|" '
          '~/earth/kml/slave/myplaces.kml';

      await _lgService.execute(
        'sshpass -p ${_lgService.connectionModel.password} '
            'ssh -t lg$screenNumber \'$command\'',
        'Added refresh interval to screen $screenNumber',
      );
    } catch (e) {
      debugPrint(
        'Error setting refresh interval: $e',
      );
    }
  }

  Future<void> removeRefreshInterval(
    int screenNumber,
  ) async {
    try {
      final search =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>'
          '<refreshMode>onInterval<\\/refreshMode>'
          '<refreshInterval>[0-9]+<\\/refreshInterval>';

      final replace =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>';

      final command =
          'echo ${_lgService.connectionModel.password} | sudo -S '
          'sed -i "s|$search|$replace|" '
          '~/earth/kml/slave/myplaces.kml';

      await _lgService.execute(
        'sshpass -p ${_lgService.connectionModel.password} '
            'ssh -t lg$screenNumber \'$command\'',
        'Removed refresh interval from screen $screenNumber',
      );
    } catch (e) {
      debugPrint(
        'Error removing refresh interval: $e',
      );
    }
  }

  Future<void> forceRefresh(
    int screenNumber,
  ) async {
    try {
      await setRefreshInterval(
        screenNumber,
        2,
      );

      await removeRefreshInterval(
        screenNumber,
      );
    } catch (e) {
      debugPrint(
        'Error during force refresh: $e',
      );
    }
  }

  int calculateLeftMostScreen(int screenCount) {
    return screenCount == 1 ? 1 : (screenCount / 2).floor() + 2;
  }

  int calculateRightMostScreen(int screenCount) {
    return screenCount == 1 ? 1 : (screenCount / 2).floor() + 1;
  }

  Future<bool> writeSoloKml(
    int machineNo,
    String kml,
  ) async {
    final result = await _lgService.execute(
      "echo '$kml' > /var/www/html/kml/slave_$machineNo.kml",
      'Solo KML written to slave_$machineNo.kml',
    );

    return result != null;
  }

  Future<bool> notifySoloKmlChanged(
    int machineNo,
  ) async {
    try {
      await forceRefresh(machineNo);
      return true;
    } catch (e) {
      debugPrint(
        'Error notifying Solo KML change: $e',
      );
      return false;
    }
  }

  Future<bool> cleanKmlKeepingLogos() async {
    try {
      final logoScreen =
          calculateLeftMostScreen(_lgService.connectionModel.screens);

      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';

      for (var i = 1; i <= _lgService.connectionModel.screens; i++) {
        if (i == 1 || i == logoScreen) continue;

        await _lgService.execute(
          "echo '$blankKml' > /var/www/html/kml/slave_$i.kml",
          'Cleaned KML screen $i',
        );
      }

      await _lgService.execute(
        "echo '' > /var/www/html/kmls.txt",
        'Loaded geographic KMLs cleaned',
      );

      await _lgService.execute(
        "echo '' > /tmp/query.txt",
        'Query cleaned',
      );

      return true;
    } catch (e) {
      debugPrint('Error cleaning KML keeping logos: $e');
      return false;
    }
  }

  Future<bool> cleanAll() async {
    try {
      await _lgService.stopDinosaurOrbit();
      await _lgService.closeChromiumOnAllScreens();

      final dinosaurMarkersCleaned = await _lgService.cleanDinosaurMarkers();

      if (!dinosaurMarkersCleaned) {
        debugPrint('Could not clean dinosaur markers');
      }

      const blankKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';

      final logoScreen =
          calculateLeftMostScreen(_lgService.connectionModel.screens);

      for (var i = 2; i <= _lgService.connectionModel.screens; i++) {
        if (i == logoScreen) {
          continue;
        }

        await _lgService.execute(
          '''
cat > /var/www/html/kml/slave_$i.kml << 'EOFKML'
$blankKml
EOFKML
''',
          'Cleaned screen $i',
        );

        await forceRefresh(i);
      }

      await _lgService.execute(
        "echo 'exittour=true' > /tmp/query.txt",
        'Stop tour',
      );

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      await _lgService.execute(
        "echo '' > /tmp/query.txt",
        'Clean query',
      );

      await _lgService.execute(
        'rm -f '
            '/var/www/html/skeleton.html '
            '/var/www/html/comparison.html',
        'Chromium HTML cleaned',
      );

      await _lgService.sendLogo();

      return dinosaurMarkersCleaned;
    } catch (e) {
      debugPrint('Error cleaning all: $e');
      return false;
    }
  }

  Future<bool> reboot() async {
    try {
      if (!_lgService.isConnected) {
        debugPrint(
          'Cannot reboot Liquid Galaxy: '
          'not connected',
        );

        return false;
      }

      bool allSuccessful = true;

      for (int screen = _lgService.connectionModel.screens;
          screen >= 1;
          screen--) {
        debugPrint(
          'Rebooting lg$screen...',
        );

        final result = await _lgService.execute(
          'sshpass -p ${_lgService.connectionModel.password} '
          'ssh -t lg$screen '
          '"echo ${_lgService.connectionModel.password} '
          '| sudo -S reboot"',
          'Reboot sent to lg$screen',
        );

        if (result == null) {
          debugPrint(
            'Reboot failed on lg$screen',
          );

          allSuccessful = false;
        } else {
          debugPrint(
            'Reboot command sent successfully '
            'to lg$screen',
          );
        }

        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );
      }

      debugPrint(
        allSuccessful
            ? 'Reboot sent to all Liquid Galaxy screens'
            : 'Reboot finished with some errors',
      );

      return allSuccessful;
    } catch (e, stackTrace) {
      debugPrint(
        'Error rebooting Liquid Galaxy: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<bool> shutdown() async {
    try {
      if (!_lgService.isConnected) {
        debugPrint(
          'Cannot shutdown Liquid Galaxy: '
          'not connected',
        );

        return false;
      }

      bool allSuccessful = true;

      for (int screen = _lgService.connectionModel.screens;
          screen >= 1;
          screen--) {
        debugPrint(
          'Shutting down lg$screen...',
        );

        final result = await _lgService.execute(
          'sshpass -p ${_lgService.connectionModel.password} '
          'ssh -t lg$screen '
          '"echo ${_lgService.connectionModel.password} '
          '| sudo -S poweroff"',
          'Shutdown sent to lg$screen',
        );

        if (result == null) {
          debugPrint(
            'Shutdown failed on lg$screen',
          );

          allSuccessful = false;
        } else {
          debugPrint(
            'Shutdown command sent successfully '
            'to lg$screen',
          );
        }

        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );
      }

      debugPrint(
        allSuccessful
            ? 'Shutdown sent to all Liquid Galaxy screens'
            : 'Shutdown finished with some errors',
      );

      return allSuccessful;
    } catch (e, stackTrace) {
      debugPrint(
        'Error shutting down Liquid Galaxy: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<bool> relaunchLG() async {
    try {
      if (!_lgService.isConnected) {
        debugPrint(
          'Cannot relaunch Liquid Galaxy: '
          'not connected',
        );

        return false;
      }

      bool allSuccessful = true;

      for (int screen = _lgService.connectionModel.screens;
          screen >= 1;
          screen--) {
        debugPrint(
          'Relaunching lg$screen...',
        );

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
  echo ${_lgService.connectionModel.password} | sudo -S service \\\${SERVICE} start
else
  echo ${_lgService.connectionModel.password} | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p ${_lgService.connectionModel.password} ssh -x -t lg@lg$screen "\$RELAUNCH_CMD"
''';

        final result = await _lgService.execute(
          relaunchCmd,
          'Relaunch sent to lg$screen',
        );

        if (result == null) {
          debugPrint(
            'Relaunch failed on lg$screen',
          );

          allSuccessful = false;
        } else {
          debugPrint(
            'lg$screen relaunched successfully',
          );
        }

        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );
      }

      debugPrint(
        allSuccessful
            ? 'Liquid Galaxy relaunched on all screens'
            : 'Liquid Galaxy relaunch finished '
                'with some errors',
      );

      return allSuccessful;
    } catch (e, stackTrace) {
      debugPrint(
        'Error relaunching Liquid Galaxy: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }
}
