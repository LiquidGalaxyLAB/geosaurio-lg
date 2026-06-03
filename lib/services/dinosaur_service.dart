import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/dinosaur.dart';

class DinosaurService {
  static Future<List<Dinosaur>> loadDinosaurs() async {
    final csvString = await rootBundle.loadString('assets/data/geosaurio.csv');

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csvString);

    return rows
        .skip(1)
        .map((row) {
          return Dinosaur.fromCsv(row);
        })
        .where((dinosaur) {
          return dinosaur.name.isNotEmpty &&
              dinosaur.country.isNotEmpty &&
              dinosaur.region.isNotEmpty &&
              dinosaur.area.isNotEmpty &&
              dinosaur.period != DinosaurPeriod.unknown;
        })
        .toList();
  }

  static Map<String, List<String>> buildCountriesByContinent(
    List<Dinosaur> dinosaurs,
    DinosaurPeriod period,
  ) {
    final Map<String, Set<String>> grouped = {};

    for (final dinosaur in dinosaurs) {
      if (dinosaur.period != period) continue;

      grouped.putIfAbsent(dinosaur.area, () => {});
      grouped[dinosaur.area]!.add(dinosaur.country);
    }

    return grouped.map((continent, countries) {
      final sortedCountries = countries.toList()..sort();
      return MapEntry(continent, sortedCountries);
    });
  }

  static Map<String, Map<String, List<String>>> buildRegionsByCountry(
    List<Dinosaur> dinosaurs,
    DinosaurPeriod period,
  ) {
    final Map<String, Map<String, Set<String>>> grouped = {};

    for (final dinosaur in dinosaurs) {
      if (dinosaur.period != period) continue;

      grouped.putIfAbsent(dinosaur.country, () => {});
      grouped[dinosaur.country]!.putIfAbsent(dinosaur.region, () => {});
      grouped[dinosaur.country]![dinosaur.region]!.add(dinosaur.name);
    }

    return grouped.map((country, regions) {
      return MapEntry(
        country,
        regions.map((region, dinosaurNames) {
          final sortedNames = dinosaurNames.toList()..sort();
          return MapEntry(region, sortedNames);
        }),
      );
    });
  }
}
