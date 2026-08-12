import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/dinosaur.dart';
import 'lg_service.dart';

class LgOverlayService {
  final LgService _lgService;

  final Map<String, String> _continentFacts = { // Facts shown in the continent information columns
    'Africa':
        'Africa preserves an extraordinary dinosaur fossil record covering '
        'almost the entire Age of Dinosaurs. Some of the earliest dinosaurs '
        'are known from Africa, while later ecosystems were home to enormous '
        'sauropods and unusual predators such as Spinosaurus.',
    'Asia':
        'Asia has one of the richest and most diverse dinosaur fossil records '
        'in the world. China and Mongolia are especially famous for spectacular '
        'fossils, including feathered dinosaurs and discoveries that helped '
        'scientists understand the connection between dinosaurs and birds.',
    'Europe':
        'Europe preserves dinosaur fossils from many different environments '
        'throughout the Mesozoic Era. During several periods, much of Europe '
        'consisted of islands, allowing distinctive dinosaur species and '
        'ecosystems to develop.',
    'North America':
        'North America contains some of the most famous dinosaur fossil '
        'formations in the world. Its fossil record includes giant Jurassic '
        'sauropods, armored dinosaurs, hadrosaurs and iconic Late Cretaceous '
        'predators.',
    'South America':
        'South America is extremely important for understanding dinosaur '
        'evolution. Some of the earliest known dinosaurs were discovered here, '
        'together with some of the largest sauropods and predatory dinosaurs '
        'ever found.',
    'Oceania':
        'Oceania preserves a fascinating dinosaur fossil record from '
        'environments that were once much closer to the polar regions. '
        'Australian fossils show that dinosaurs could survive in cool and '
        'highly seasonal environments.',
    'Antarctica':
        'Antarctica was much warmer during the Mesozoic Era and supported '
        'forests and diverse ecosystems. Dinosaur fossils discovered there '
        'show that these animals were capable of living in ancient polar '
        'environments.',
  };

  final Map<String, String> _countryFacts = {   // Facts shown in the country information columns
    'China':
        'China is especially famous for exceptionally preserved feathered '
        'dinosaurs. Discoveries from northeastern China provided important '
        'evidence about the evolutionary relationship between dinosaurs '
        'and modern birds.',
    'Mongolia':
        'Mongolia is famous for spectacular dinosaur discoveries from the '
        'Gobi Desert. Its fossils include Velociraptor, dinosaur eggs, nests '
        'and remarkably well-preserved skeletons.',
    'Argentina':
        'Argentina has an extraordinary dinosaur fossil record. It preserves '
        'some of the earliest dinosaurs known to science as well as some of '
        'the largest sauropods and giant predatory dinosaurs ever discovered.',
    'Brazil':
        'Southern Brazil has produced important fossils from the earliest '
        'stages of dinosaur evolution. These discoveries help scientists '
        'understand how dinosaurs diversified during the Triassic Period.',
    'United States':
        'The United States has an exceptionally diverse dinosaur fossil '
        'record. Famous formations preserve giant Jurassic sauropods, '
        'stegosaurs, horned dinosaurs, hadrosaurs and large Late Cretaceous '
        'predators.',
    'Canada':
        'Canada is particularly famous for its Late Cretaceous dinosaur '
        'fossils. Alberta has produced many hadrosaurs, horned dinosaurs '
        'and tyrannosaurs, making it one of the richest dinosaur regions '
        'in the world.',
    'United Kingdom':
        'The United Kingdom played an important role in the birth of '
        'dinosaur science. Some of the first dinosaurs ever scientifically '
        'described were discovered there.',
    'Germany':
        'Germany has produced important dinosaur fossils from several '
        'geological periods. Some fossil sites are especially famous for '
        'their exceptional preservation.',
    'France':
        'France has a varied dinosaur fossil record covering several parts '
        'of the Mesozoic Era, including sauropods, theropods and ornithopods.',
    'Spain':
        'Spain contains many important dinosaur fossil sites, including '
        'footprints, skeletons and nesting areas that reveal information '
        'about dinosaurs living in ancient European environments.',
    'Portugal':
        'Portugal is especially well known for its Late Jurassic dinosaur '
        'fossils. Several discoveries show similarities with dinosaurs '
        'known from North America.',
    'South Africa':
        'South Africa preserves an important record of early dinosaurs and '
        'sauropodomorphs, providing valuable information about dinosaur '
        'evolution around the Triassic and Jurassic periods.',
    'India':
        'India preserves dinosaurs from several stages of the Mesozoic Era. '
        'Its fossil record is especially interesting because the Indian '
        'landmass travelled across ancient oceans before colliding with Asia.',
    'Australia':
        'Australian dinosaur fossils reveal animals adapted to environments '
        'located close to the ancient polar regions, where they experienced '
        'strong seasonal changes in climate and daylight.',
  };

  LgOverlayService(this._lgService);

  String _cleanText(String value) {
    return value
        .replaceAll('&', 'and')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .trim();
  }

  Future<bool> createDinosaurInfoColumn(   // Creates the dinosaur information column as an imag
    Dinosaur dinosaur,
    String fileName,
  ) async {
    try {
      const double width = 1000;
      const double height = 2600;
      const double padding = 60;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      const backgroundColor = ui.Color(0xFF102F33);
      const cardColor = ui.Color(0xFF1A464A);
      const secondaryCardColor = ui.Color(0xFF24575B);
      const accentColor = ui.Color(0xFFE9C46A);
      const titleColor = ui.Color(0xFFFFFFFF);
      const textColor = ui.Color(0xFFF4F7F6);

      final backgroundPaint = ui.Paint()..color = backgroundColor;

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(0, 0, width, height),
          const ui.Radius.circular(45),
        ),
        backgroundPaint,
      );

      double currentY = 55;

      double drawText({
        required String text,
        required double fontSize,
        required double y,
        double x = padding,
        ui.FontWeight fontWeight = ui.FontWeight.normal,
        ui.Color color = textColor,
        double maxWidth = width - (padding * 2),
        double lineHeight = 1.25,
        ui.TextAlign textAlign = ui.TextAlign.left,
      }) {
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: textAlign,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: lineHeight,
          ),
        )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          )
          ..addText(text);

        final paragraph = builder.build();
        paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
        canvas.drawParagraph(paragraph, ui.Offset(x, y));
        return paragraph.height;
      }

      void drawCard({
        required double x,
        required double y,
        required double cardWidth,
        required double cardHeight,
        ui.Color color = cardColor,
      }) {
        final paint = ui.Paint()..color = color;
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(x, y, cardWidth, cardHeight),
            const ui.Radius.circular(28),
          ),
          paint,
        );
      }

      void drawInfoCard({
        required String label,
        required String value,
        required double x,
        required double y,
        required double cardWidth,
        double cardHeight = 135,
      }) {
        drawCard(x: x, y: y, cardWidth: cardWidth, cardHeight: cardHeight);
        drawText(
          text: label,
          fontSize: 27,
          y: y + 20,
          x: x + 22,
          maxWidth: cardWidth - 44,
          fontWeight: ui.FontWeight.bold,
          color: accentColor,
        );
        drawText(
          text: value.trim().isEmpty ? 'Unknown' : value,
          fontSize: 32,
          y: y + 60,
          x: x + 22,
          maxWidth: cardWidth - 44,
          color: textColor,
        );
      }

      currentY += drawText(
        text: dinosaur.name.toUpperCase(),
        fontSize: 60,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        textAlign: ui.TextAlign.center,
        color: titleColor,
      );

      currentY += 16;
      currentY += drawText(
        text: dinosaur.periodName.toUpperCase(),
        fontSize: 28,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        textAlign: ui.TextAlign.center,
        color: accentColor,
      );

      currentY += 28;
      final separatorPaint = ui.Paint()
        ..color = accentColor
        ..strokeWidth = 4;

      canvas.drawLine(
        ui.Offset(padding, currentY),
        ui.Offset(width - padding, currentY),
        separatorPaint,
      );

      currentY += 35;

      final cleanName = _lgService.cleanDinosaurImageName(dinosaur.name);
      final dinosaurImagePath = await _lgService.getExistingImagePath(
        'assets/images/dinosaurs/${cleanName}_normal',
      );

      ui.Image? dinosaurImage;
      if (dinosaurImagePath != null) {
        try {
          final data = await rootBundle.load(dinosaurImagePath);
          final bytes = data.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          dinosaurImage = frame.image;
        } catch (e) {
          debugPrint('Could not load dinosaur image for column: $e');
        }
      }

      if (dinosaurImage != null) {
        const double maxImageWidth = 780;
        const double maxImageHeight = 390;
        final originalWidth = dinosaurImage.width.toDouble();
        final originalHeight = dinosaurImage.height.toDouble();
        final scale = math.min(
          maxImageWidth / originalWidth,
          maxImageHeight / originalHeight,
        );
        final imageWidth = originalWidth * scale;
        final imageHeight = originalHeight * scale;
        final imageX = (width - imageWidth) / 2;

        drawCard(
          x: imageX - 18,
          y: currentY - 18,
          cardWidth: imageWidth + 36,
          cardHeight: imageHeight + 36,
          color: secondaryCardColor,
        );

        final sourceRect = ui.Rect.fromLTWH(0, 0, originalWidth, originalHeight);
        final destinationRect = ui.Rect.fromLTWH(imageX, currentY, imageWidth, imageHeight);
        canvas.drawImageRect(dinosaurImage, sourceRect, destinationRect, ui.Paint());
        currentY += imageHeight + 55;
      }

      currentY += drawText(
        text: 'Overview',
        fontSize: 38,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );

      currentY += 18;
      const double gap = 18;
      final double cardWidth = (width - (padding * 2) - gap) / 2;

      drawInfoCard(
        label: 'Period',
        value: dinosaur.periodName,
        x: padding,
        y: currentY,
        cardWidth: cardWidth,
      );
      drawInfoCard(
        label: 'Year',
        value: dinosaur.year,
        x: padding + cardWidth + gap,
        y: currentY,
        cardWidth: cardWidth,
      );
      currentY += 153;

      drawInfoCard(
        label: 'Diet',
        value: dinosaur.diet,
        x: padding,
        y: currentY,
        cardWidth: cardWidth,
      );
      drawInfoCard(
        label: 'Habitat',
        value: dinosaur.habitat,
        x: padding + cardWidth + gap,
        y: currentY,
        cardWidth: cardWidth,
      );
      currentY += 153;

      drawInfoCard(
        label: 'Length',
        value: dinosaur.length,
        x: padding,
        y: currentY,
        cardWidth: cardWidth,
      );
      drawInfoCard(
        label: 'Weight',
        value: dinosaur.weight,
        x: padding + cardWidth + gap,
        y: currentY,
        cardWidth: cardWidth,
      );
      currentY += 170;

      final location = [dinosaur.region, dinosaur.country]
          .where((value) => value.trim().isNotEmpty)
          .join(', ');

      drawCard(x: padding, y: currentY, cardWidth: width - (padding * 2), cardHeight: 125);
      drawText(
        text: 'Location',
        fontSize: 27,
        y: currentY + 18,
        x: padding + 22,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );
      drawText(
        text: location.isEmpty ? 'Unknown' : location,
        fontSize: 32,
        y: currentY + 58,
        x: padding + 22,
        maxWidth: width - (padding * 2) - 44,
      );
      currentY += 165;

      currentY += drawText(
        text: 'Scientific Information',
        fontSize: 40,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );

      currentY += 18;
      const double scientificHeight = 390;
      drawCard(
        x: padding,
        y: currentY,
        cardWidth: width - (padding * 2),
        cardHeight: scientificHeight,
        color: secondaryCardColor,
      );

      double scientificY = currentY + 25;
      drawText(
        text: 'Status',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );
      scientificY += 38;
      scientificY += drawText(
        text: dinosaur.status.isEmpty ? 'Unknown' : dinosaur.status,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth: width - (padding * 2) - 56,
      );
      scientificY += 14;

      drawText(
        text: 'Author',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );
      scientificY += 38;
      scientificY += drawText(
        text: dinosaur.author.isEmpty ? 'Unknown' : dinosaur.author,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth: width - (padding * 2) - 56,
      );
      scientificY += 14;

      drawText(
        text: 'Formation',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );
      scientificY += 38;
      scientificY += drawText(
        text: dinosaur.formation.isEmpty ? 'Unknown' : dinosaur.formation,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth: width - (padding * 2) - 56,
      );
      scientificY += 14;

      drawText(
        text: 'Time',
        fontSize: 27,
        y: scientificY,
        x: padding + 28,
        fontWeight: ui.FontWeight.bold,
        color: accentColor,
      );
      scientificY += 38;
      final timeRange = [dinosaur.time1, dinosaur.time2]
          .where((value) => value.trim().isNotEmpty)
          .join(' – ');
      drawText(
        text: timeRange.isEmpty ? 'Unknown' : timeRange,
        fontSize: 31,
        y: scientificY,
        x: padding + 28,
        maxWidth: width - (padding * 2) - 56,
      );
      currentY += scientificHeight + 45;

      currentY += drawText(
        text: 'About',
        fontSize: 40,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );
      currentY += 18;
      final aboutText = dinosaur.generalInfo.isEmpty
          ? 'No additional information available.'
          : dinosaur.generalInfo;

      final aboutBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: 30, height: 1.4),
      )
        ..pushStyle(ui.TextStyle(color: textColor, fontSize: 30))
        ..addText(aboutText);
      final aboutParagraph = aboutBuilder.build();
      aboutParagraph.layout(ui.ParagraphConstraints(width: width - (padding * 2) - 56));
      final aboutCardHeight = aboutParagraph.height + 56;

      drawCard(x: padding, y: currentY, cardWidth: width - (padding * 2), cardHeight: aboutCardHeight);
      canvas.drawParagraph(aboutParagraph, ui.Offset(padding + 28, currentY + 28));

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('Could not generate dinosaur info column image');
        return false;
      }

      final bytes = byteData.buffer.asUint8List();
      final uploaded = await _lgService.uploadBytesToLG(bytes: bytes, fileName: fileName);

      if (!uploaded) {
        debugPrint('Could not upload dinosaur info column');
        return false;
      }

      debugPrint('Dinosaur info column created and uploaded: $fileName');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error creating dinosaur info column: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> showDinosaurAboutColumn(Dinosaur dinosaur) async {   // Shows the dinosaur information column on the right screen
    try {
      if (!_lgService.isConnected) {
        debugPrint('Cannot show dinosaur information: Liquid Galaxy is not connected');
        return false;
      }

      final screen = _lgService.calculateRightMostScreen(_lgService.connectionModel.screens);
      final imageFileName = '${_lgService.cleanDinosaurImageName(dinosaur.name)}_info.png';
      final created = await createDinosaurInfoColumn(dinosaur, imageFileName);

      if (!created) {
        debugPrint('Could not create dinosaur information column');
        return false;
      }

      final cleanDinosaurName = _cleanText(dinosaur.name);
      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay>
      <name>$cleanDinosaurName Information</name>
      <Icon>
        <href>http://lg1:81/$imageFileName</href>
      </Icon>
      <overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="850" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';

      await cleanRightScreenKml();
      final result = await _lgService.execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Dinosaur information column sent',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint('Error showing dinosaur information column: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> createLocationInfoColumn({   // Creates the information column used for continents and countries
    required String title,
    required String subtitle,
    required String introduction,
    required String instructions,
    required String fact,
    required String fileName,
  }) async {
    try {
      const double width = 1000;
      const double height = 1900;
      const double padding = 60;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      const backgroundColor = ui.Color(0xFF102F33);
      const cardColor = ui.Color(0xFF1A464A);
      const secondaryCardColor = ui.Color(0xFF24575B);
      const accentColor = ui.Color(0xFFE9C46A);
      const titleColor = ui.Color(0xFFFFFFFF);
      const textColor = ui.Color(0xFFF4F7F6);
      const secondaryTextColor = ui.Color(0xFFC6DAD8);

      final backgroundPaint = ui.Paint()..color = backgroundColor;

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(0, 0, width, height),
          const ui.Radius.circular(45),
        ),
        backgroundPaint,
      );

      double currentY = 55;

      double drawText({
        required String text,
        required double fontSize,
        required double y,
        double x = padding,
        ui.FontWeight fontWeight = ui.FontWeight.normal,
        ui.Color color = textColor,
        double maxWidth = width - (padding * 2),
        double lineHeight = 1.3,
        ui.TextAlign textAlign = ui.TextAlign.left,
      }) {
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: textAlign,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: lineHeight,
          ),
        )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          )
          ..addText(text);

        final paragraph = builder.build();
        paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
        canvas.drawParagraph(paragraph, ui.Offset(x, y));
        return paragraph.height;
      }

      void drawCard({
        required double y,
        required double cardHeight,
        ui.Color color = cardColor,
      }) {
        final paint = ui.Paint()..color = color;
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(padding, y, width - (padding * 2), cardHeight),
            const ui.Radius.circular(30),
          ),
          paint,
        );
      }

      currentY += drawText(
        text: title.toUpperCase(),
        fontSize: 62,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        textAlign: ui.TextAlign.center,
        color: titleColor,
      );

      currentY += 8;
      currentY += drawText(
        text: subtitle.toUpperCase(),
        fontSize: 30,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        textAlign: ui.TextAlign.center,
        color: accentColor,
      );

      currentY += 25;
      final separatorPaint = ui.Paint()
        ..color = accentColor
        ..strokeWidth = 4;

      canvas.drawLine(
        ui.Offset(padding, currentY),
        ui.Offset(width - padding, currentY),
        separatorPaint,
      );

      currentY += 38;
      currentY += drawText(
        text: introduction,
        fontSize: 34,
        y: currentY,
        textAlign: ui.TextAlign.center,
        color: secondaryTextColor,
        lineHeight: 1.4,
      );

      currentY += 48;
      currentY += drawText(
        text: 'WHAT CAN YOU DO NOW?',
        fontSize: 41,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );

      currentY += 20;
      const double actionsCardHeight = 465;
      drawCard(y: currentY, cardHeight: actionsCardHeight);
      drawText(
        text: instructions,
        fontSize: 32,
        y: currentY + 35,
        x: padding + 38,
        maxWidth: width - (padding * 2) - 76,
        lineHeight: 1.55,
      );

      currentY += actionsCardHeight + 50;
      currentY += drawText(
        text: 'DID YOU KNOW?',
        fontSize: 41,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        color: titleColor,
      );

      currentY += 20;
      const double factCardHeight = 485;
      drawCard(y: currentY, cardHeight: factCardHeight, color: secondaryCardColor);
      drawText(
        text: fact,
        fontSize: 31,
        y: currentY + 36,
        x: padding + 38,
        maxWidth: width - (padding * 2) - 76,
        lineHeight: 1.45,
      );

      currentY += factCardHeight + 55;
      drawText(
        text: 'Continue exploring with GeoSaurio',
        fontSize: 30,
        y: currentY,
        fontWeight: ui.FontWeight.bold,
        textAlign: ui.TextAlign.center,
        color: accentColor,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('Could not create location info column');
        return false;
      }

      final bytes = byteData.buffer.asUint8List();
      final uploaded = await _lgService.uploadBytesToLG(bytes: bytes, fileName: fileName);

      if (!uploaded) {
        debugPrint('Could not upload location info column');
        return false;
      }

      debugPrint('Location info column created: $fileName');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error creating location info column: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> showLocationInfoOverlay({
    required String fileName,
    required String locationName,
  }) async {
    try {
      if (!_lgService.isConnected) {
        debugPrint('Cannot show location info: Liquid Galaxy is not connected');
        return false;
      }

      final screen = _lgService.calculateRightMostScreen(_lgService.connectionModel.screens);
      final cleanLocationName = _cleanText(locationName);
      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay>
      <name>$cleanLocationName Information</name>
      <Icon>
        <href>http://lg1:81/$fileName</href>
      </Icon>
      <overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="850" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';

      await cleanRightScreenKml();
      final result = await _lgService.execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Location info column sent',
      );

      return result != null;
    } catch (e, stackTrace) {
      debugPrint('Error showing location info overlay: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> showContinentInfoColumn(String continent) async {   // Creates and shows the information for the selected continent
    try {
      final fact = _continentFacts[continent] ??
          'This continent preserves an important dinosaur fossil record with discoveries from different parts of the Mesozoic Era.';
      const instructions = '→ Select a country to continue exploring\n\n'
          '→ Discover which dinosaurs were found there\n\n'
          '→ Explore dinosaur fossil locations\n\n'
          '→ Travel across the discoveries using Liquid Galaxy';
      const fileName = 'continent_info.png';

      final created = await createLocationInfoColumn(
        title: continent,
        subtitle: 'GeoSaurio',
        introduction: 'Explore the dinosaur discoveries of $continent and learn how dinosaur life changed across this part of the world.',
        instructions: instructions,
        fact: fact,
        fileName: fileName,
      );

      if (!created) return false;

      return await showLocationInfoOverlay(fileName: fileName, locationName: continent);
    } catch (e, stackTrace) {
      debugPrint('Error showing continent information: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> showCountryInfoColumn(String country, String continent) async {   // Creates and shows the information for the selected country
    try {
      final fact = _countryFacts[country] ??
          '$country has produced dinosaur fossils that help scientists understand dinosaur diversity and evolution during the Mesozoic Era.';
      const instructions = '→ Explore the dinosaurs found in this country\n\n'
          '→ Select a dinosaur to visit its fossil location\n\n'
          '→ Discover information about each species\n\n'
          '→ View its skeleton and size comparison\n\n'
          '→ Listen to its narrated description';
      const fileName = 'country_info.png';

      final created = await createLocationInfoColumn(
        title: country,
        subtitle: '$continent • GeoSaurio',
        introduction: 'Explore the dinosaurs discovered in $country and learn more about the fossil sites that preserve their history.',
        instructions: instructions,
        fact: fact,
        fileName: fileName,
      );

      if (!created) return false;

      return await showLocationInfoOverlay(fileName: fileName, locationName: country);
    } catch (e, stackTrace) {
      debugPrint('Error showing country information: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> sendLogo() async { //sends logo
    try {
      final screen = _lgService.calculateLeftMostScreen(_lgService.connectionModel.screens);
      final uploaded = await _lgService.uploadAssetToLG(
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

      final result = await _lgService.execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Logo sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error sending logo: $e');
      return false;
    }
  }

  Future<bool> showRightScreenImage({   // Shows an image on the right screen
  Future<bool> showRightScreenImage({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final screen = _lgService.calculateRightMostScreen(_lgService.connectionModel.screens);
      final uploaded = await _lgService.uploadAssetToLG(
        assetPath: assetPath,
        fileName: fileName,
      );

      if (!uploaded) return false;

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
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

      final result = await _lgService.execute(
        "echo '$kml' > /var/www/html/kml/slave_$screen.kml",
        'Image sent',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return false;
    }
  }

  Future<void> cleanLogos() async { //clean logos
    try {
      final screen = _lgService.calculateLeftMostScreen(_lgService.connectionModel.screens);
      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty Logo</name>
  </Document>
</kml>''';

      await _lgService.execute(
        "echo '$blankKml' > /var/www/html/kml/slave_$screen.kml",
        'Logo cleaned',
      );
    } catch (e) {
      debugPrint('Error cleaning logos: $e');
    }
  }

  Future<bool> cleanRightScreenKml() async { //clean right screen kml
    try {
      final screen = _lgService.calculateRightMostScreen(_lgService.connectionModel.screens);
      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty Right Screen</name>
  </Document>
</kml>''';

      final result = await _lgService.execute(
        "echo '$blankKml' > /var/www/html/kml/slave_$screen.kml",
        'Right screen cleaned',
      );

      return result != null;
    } catch (e) {
      debugPrint('Error cleaning right screen: $e');
      return false;
    }
  }
}
