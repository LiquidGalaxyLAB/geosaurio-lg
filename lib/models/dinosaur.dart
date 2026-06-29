import 'dart:math' as math;

// Geological periods available in the app
enum DinosaurPeriod { triassic, jurassic, cretaceous, unknown }

class Dinosaur {
  // Dinosaur name
  final String name;

  // Scientific status
  final String status;

  // Author who described the dinosaur
  final String author;

  // Discovery/publication year
  final String year;

  // Estimated length
  final String length;

  // Estimated weight
  final String weight;

  // Geographic area / continent
  final String area;

  // Country
  final String country;

  // Region/state
  final String region;

  // Geological formation
  final String formation;

  // Geological period start
  final String time1;

  // Geological period end
  final String time2;

  // Fossil material information
  final String material;

  // General dinosaur information
  final String generalInfo;

  // Dinosaur diet
  final String diet;

  // Dinosaur habitat
  final String habitat;

  // Narration audio link
  final String audioLink;

  // Liquid Galaxy coordinates
  final double longitude;
  final double latitude;
  final double altitude;
  final double heading;
  final double tilt;
  final double range;
  final String altitudeMode;

  // Constructor
  Dinosaur({
    required this.name,
    required this.status,
    required this.author,
    required this.year,
    required this.length,
    required this.weight,
    required this.area,
    required this.country,
    required this.region,
    required this.formation,
    required this.time1,
    required this.time2,
    required this.material,
    required this.generalInfo,
    required this.diet,
    required this.habitat,
    required this.audioLink,
    required this.longitude,
    required this.latitude,
    required this.altitude,
    required this.heading,
    required this.tilt,
    required this.range,
    required this.altitudeMode,
  });

  // Detects the dinosaur geological period automatically
  DinosaurPeriod get period {
    final text = '$time1 $time2'.toLowerCase();

    if (text.contains('triassic')) {
      return DinosaurPeriod.triassic;
    }

    if (text.contains('jurassic')) {
      return DinosaurPeriod.jurassic;
    }

    if (text.contains('cretaceous')) {
      return DinosaurPeriod.cretaceous;
    }

    return DinosaurPeriod.unknown;
  }

  // Returns readable geological period name
  String get periodName {
    switch (period) {
      case DinosaurPeriod.triassic:
        return 'Triassic';
      case DinosaurPeriod.jurassic:
        return 'Jurassic';
      case DinosaurPeriod.cretaceous:
        return 'Cretaceous';
      case DinosaurPeriod.unknown:
        return 'Unknown';
    }
  }

  /// Calculates the projected marker position based on the camera LookAt position.
  /// This moves the marker from the camera coordinates towards the center of the viewport
  /// based on heading, tilt, and range.
  Map<String, double> getMarkerCoordinates() {
    if (latitude == 0 && longitude == 0) {
      return {'latitude': 0, 'longitude': 0};
    }

    const earthRadius = 6371000.0;
    final lat1 = latitude * math.pi / 180.0;
    final lon1 = longitude * math.pi / 180.0;
    final h = heading * math.pi / 180.0;
    final t = tilt * math.pi / 180.0;
    final r = range == 0 ? 8000.0 : range;

    // We project the point forward. If the camera is at (lat, lon) and looking
    // at a point on the ground, the distance to that point depends on tilt.
    // A simple approximation is using the range and the sine of the tilt.
    // We also add a small adjustment factor to ensure it looks centered.
    double distance = r * math.sin(t);
    
    // If tilt is 0, sin(t) is 0, so we use a small fallback distance or 0.
    // However, if it's 0, it means we are looking straight down, so the marker
    // should be exactly at the coordinates.
    if (distance == 0 && tilt > 0) {
       distance = r * 0.3; // Fallback
    }
    
    // Limit distance to avoid projecting too far
    distance = distance.clamp(0.0, r);

    final angularDistance = distance / earthRadius;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angularDistance) +
          math.cos(lat1) * math.sin(angularDistance) * math.cos(h),
    );

    final lon2 = lon1 +
        math.atan2(
          math.sin(h) * math.sin(angularDistance) * math.cos(lat1),
          math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2),
        );

    return {
      'latitude': lat2 * 180.0 / math.pi,
      'longitude': lon2 * 180.0 / math.pi,
    };
  }

  // Parses numbers with comma decimal format from CSV
  static double parseNumber(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) return 0;

    final normalized = text.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0;
  }

  // Creates a Dinosaur object from a CSV row
  factory Dinosaur.fromCsv(List<dynamic> row) {
    return Dinosaur(
      name: row[1]?.toString().trim() ?? '',
      status: row[2]?.toString().trim() ?? '',
      author: row[3]?.toString().trim() ?? '',
      year: row[4]?.toString().trim() ?? '',
      length: row[5]?.toString().trim() ?? '',
      weight: row[6]?.toString().trim() ?? '',
      area: row[8]?.toString().trim() ?? '',
      country: row[9]?.toString().trim() ?? '',

      region: row[66]?.toString().trim() ?? '',
      formation: row[67]?.toString().trim() ?? '',

      longitude: parseNumber(row[69]),
      latitude: parseNumber(row[70]),
      altitude: parseNumber(row[71]),
      heading: parseNumber(row[72]),
      tilt: parseNumber(row[73]),
      range: parseNumber(row[74]),
      altitudeMode: row[75]?.toString().trim().isEmpty ?? true
          ? 'relativeToGround'
          : row[75].toString().trim(),

      time1: row[172]?.toString().trim() ?? '',
      time2: row[173]?.toString().trim() ?? '',

      material: row[194]?.toString().trim() ?? '',
      generalInfo: row[196]?.toString().trim() ?? '',
      diet: row[197]?.toString().trim() ?? '',
      habitat: row[198]?.toString().trim() ?? '',
      audioLink: row[199]?.toString().trim() ?? '',
    );
  }
}
