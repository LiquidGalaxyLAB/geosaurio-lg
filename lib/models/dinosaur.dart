// Geological periods available in the app
enum DinosaurPeriod {
  triassic,
  jurassic,
  cretaceous,
  unknown,
}

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

  // Creates a Dinosaur object from a CSV row
  factory Dinosaur.fromCsv(List<dynamic> row) {
    return Dinosaur(
      name: row[1]?.toString() ?? '',
      status: row[2]?.toString() ?? '',
      author: row[3]?.toString() ?? '',
      year: row[4]?.toString() ?? '',
      length: row[5]?.toString() ?? '',
      weight: row[6]?.toString() ?? '',
      area: row[8]?.toString() ?? '',
      country: row[9]?.toString() ?? '',
      region: row[10]?.toString() ?? '',
      formation: row[11]?.toString() ?? '',
      time1: row[12]?.toString() ?? '',
      time2: row[13]?.toString() ?? '',
      material: row[34]?.toString() ?? '',
    );
  }
}