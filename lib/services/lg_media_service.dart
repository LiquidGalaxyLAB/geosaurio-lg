import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/dinosaur.dart';
import 'lg_service.dart';

class LgMediaService {
  final LgService _lgService;

  LgMediaService(this._lgService);

  Future<bool> showDinosaurSkeletonImage(Dinosaur dinosaur) async { //Shows chromium of skeleton
    final cleanName = _lgService.cleanDinosaurImageName(dinosaur.name);

    final assetPath = await _lgService.getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_skeleton',
    );

    if (assetPath == null) {
      debugPrint(
        'Skeleton image not found for ${dinosaur.name}',
      );
      return false;
    }

    final extension = assetPath.split('.').last;
    final imageFileName = '${cleanName}_skeleton.$extension';

    final uploadedImage = await _lgService.uploadAssetToLG(
      assetPath: assetPath,
      fileName: imageFileName,
    );

    if (!uploadedImage) {
      return false;
    }

    final uploadedHtml = await uploadHtmlToLG(
      htmlFileName: 'skeleton.html',
      imageFileName: imageFileName,
      title: '${dinosaur.name} Skeleton',
      imageHeight: 70,
    );

    if (!uploadedHtml) {
      return false;
    }

    return await openChromiumOnAllScreens(
      'http://lg1:81/skeleton.html',
    );
  }

  Future<bool> showDinosaurComparisonImage(Dinosaur dinosaur) async { //shows chromium of comparison
    final cleanName = _lgService.cleanDinosaurImageName(dinosaur.name);

    final assetPath = await _lgService.getExistingImagePath(
      'assets/images/dinosaurs/${cleanName}_comparison',
    );

    if (assetPath == null) return false;

    final extension = assetPath.split('.').last;
    final imageFileName = '${cleanName}_comparison.$extension';

    final uploadedImage = await _lgService.uploadAssetToLG(
      assetPath: assetPath,
      fileName: imageFileName,
    );

    if (!uploadedImage) return false;

    final uploadedHtml = await uploadHtmlToLG(
      htmlFileName: 'comparison.html',
      imageFileName: imageFileName,
      title: '${dinosaur.name} Comparison',
      imageHeight: 70,
    );

    if (!uploadedHtml) return false;

    return await openChromiumOnAllScreens('http://lg1:81/comparison.html');
  }

  Future<bool> openChromiumOnAllScreens(String url) async { //Open Chromium
    try {
      for (var i = 1; i <= _lgService.connectionModel.screens; i++) {
        final fullUrl = '$url?screen=$i&total=${_lgService.connectionModel.screens}';

        final command = '''
sshpass -p ${_lgService.connectionModel.password} ssh -t lg$i "DISPLAY=:0 chromium-browser --kiosk --no-first-run --disable-infobars '$fullUrl' > /dev/null 2>&1 &"
''';

        await _lgService.execute(command, 'Chromium opened on lg$i');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return true;
    } catch (e) {
      debugPrint('Error opening Chromium: $e');
      return false;
    }
  }

  Future<bool> closeChromiumOnAllScreens() async { //Close chromiums
    try {
      for (var i = 1; i <= _lgService.connectionModel.screens; i++) {
        final command = '''
sshpass -p ${_lgService.connectionModel.password} ssh -t lg$i "
pkill -f chromium-browser || true
pkill -f chromium || true
pkill -f chrome || true
sleep 2

DISPLAY=:0 wmctrl -a 'Google Earth' || true
DISPLAY=:0 xdotool search --name 'Google Earth' windowactivate || true
DISPLAY=:0 xdotool key F11 || true
"
''';

        await _lgService.execute(command, 'Chromium closed on lg$i');
        await Future.delayed(const Duration(milliseconds: 700));
      }

      await _lgService.execute(
        "echo 'exittour=true' > /tmp/query.txt",
        'Tour stopped after Chromium close',
      );

      await _lgService.execute(
        "echo '' > /tmp/query.txt",
        'Query cleaned after Chromium close',
      );

      return true;
    } catch (e) {
      debugPrint('Error closing Chromium: $e');
      return false;
    }
  }

  Future<bool> uploadHtmlToLG({ //Sends de html to LG
    required String htmlFileName,
    required String imageFileName,
    required String title,
    double imageHeight = 95,
  }) async {
    try {
      final html = '''
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

      return await _lgService.uploadBytesToLG(
        bytes: Uint8List.fromList(html.codeUnits),
        fileName: htmlFileName,
      );
    } catch (e) {
      debugPrint('Error uploading HTML: $e');
      return false;
    }
  }
}
