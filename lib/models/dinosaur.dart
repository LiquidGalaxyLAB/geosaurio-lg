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
