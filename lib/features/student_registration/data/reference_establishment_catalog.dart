import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/establishment.dart';
import 'establishment_catalog.dart';

/// Catalogue de référence des établissements secondaires, embarqué dans
/// l'application. Généré par `tool/establishments/import_master_catalog.dart`
/// (Base maîtresse Yaoundé/Douala + catalogue historique + compléments du
/// propriétaire) : ne jamais le modifier à la main.
const referenceCatalogAsset =
    'assets/data/establishments/cameroon_secondary_2026_09.json';

abstract final class ReferenceEstablishmentCatalog {
  static const schema = 'intellia.establishments.v1';

  /// Lit le catalogue versionné. Un établissement de référence n'est jamais
  /// partenaire : seul le serveur le dit.
  static List<Establishment> parse(String source) {
    final document = jsonDecode(source) as Map<String, dynamic>;
    if (document['schema'] != schema) {
      throw FormatException('Schéma inattendu : ${document['schema']}');
    }
    return [
      for (final raw in document['establishments'] as List)
        _entry(Map<String, dynamic>.from(raw as Map)),
    ];
  }

  static Establishment _entry(Map<String, dynamic> row) {
    final name = row['name'] as String;
    final type = _enum(EstablishmentType.values, row['type']);
    final track = _enum(EstablishmentTrack.values, row['track']);
    final provenance = row['provenance'] as Map?;
    return Establishment(
      id: row['id'] as String,
      officialName: name,
      normalizedName: EstablishmentSearch.normalize(name),
      aliases: [for (final alias in row['aliases'] as List) alias as String],
      region: row['region'] as String? ?? '',
      city: row['city'] as String? ?? '',
      district: row['district'] as String?,
      type: type ?? EstablishmentType.privateSecondarySchool,
      subsystem: _enum(EstablishmentSubsystem.values, row['language']),
      ownership: _enum(EstablishmentOwnership.values, row['ownership']),
      track: track,
      educationTypes: switch (track) {
        EstablishmentTrack.technical => const [
          EstablishmentEducationType.technical,
        ],
        EstablishmentTrack.polyvalent => EstablishmentEducationType.values,
        EstablishmentTrack.general => const [
          EstablishmentEducationType.general,
        ],
        null =>
          type == EstablishmentType.technicalSchool
              ? const [EstablishmentEducationType.technical]
              : const [EstablishmentEducationType.general],
      },
      status: EstablishmentCatalogStatus.active,
      provenance: provenance == null
          ? null
          : EstablishmentProvenance(
              source: provenance['source'] as String,
              confidence:
                  _enum(
                    EstablishmentConfidence.values,
                    provenance['confidence'],
                  ) ??
                  EstablishmentConfidence.medium,
              url: provenance['url'] as String?,
            ),
    );
  }

  static T? _enum<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// Le catalogue de référence, chargé une fois par session, sans réseau. Si
/// le fichier était illisible, le catalogue historique compilé prend le
/// relais : l'élève peut toujours retrouver son établissement.
final referenceEstablishmentsProvider = FutureProvider<List<Establishment>>((
  ref,
) async {
  try {
    return ReferenceEstablishmentCatalog.parse(
      await rootBundle.loadString(referenceCatalogAsset),
    );
  } on Object {
    return EstablishmentCatalog.all;
  }
});
