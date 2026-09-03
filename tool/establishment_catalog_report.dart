import 'dart:convert';
import 'dart:io';

import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';

void main() {
  final byRegion = <String, int>{};
  final byCity = <String, int>{};

  for (final establishment in EstablishmentCatalog.all) {
    byRegion.update(
      establishment.region,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    byCity.update(establishment.city, (count) => count + 1, ifAbsent: () => 1);
  }

  final report = <String, Object>{
    'version': EstablishmentCatalog.version,
    'total': EstablishmentCatalog.all.length,
    'byRegion': Map.fromEntries(
      byRegion.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    'byCity': Map.fromEntries(
      byCity.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
