import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reference_establishment_catalog.dart';
import '../data/registration_establishments_provider.dart';
import '../domain/establishment.dart';
import '../domain/school_name_canon.dart';

/// Vue de recherche unifiée : le catalogue de référence embarqué, enrichi des
/// établissements partenaires connus du serveur.
///
/// La fusion est exacte (même identifiant, ou même nom canonique dans la
/// même ville) et jamais approximative : un rapprochement douteux ne doit
/// pas donner le badge partenaire à un autre établissement.
class SchoolDirectory {
  const SchoolDirectory._(this.schools, {required this.partnersPending});

  factory SchoolDirectory.merge({
    required List<Establishment> reference,
    List<Establishment> partners = const [],
    bool partnersPending = false,
  }) {
    final schools = [...reference];
    final byId = <String, int>{
      for (var i = 0; i < schools.length; i++) schools[i].id: i,
    };
    final byIdentity = <String, int>{};
    for (var i = 0; i < schools.length; i++) {
      byIdentity.putIfAbsent(
        SchoolNameCanon.identityKey(schools[i].officialName, schools[i].city),
        () => i,
      );
    }
    final added = <Establishment>[];
    for (final partner in partners) {
      final index =
          byId[partner.id] ??
          byIdentity[SchoolNameCanon.identityKey(
            partner.officialName,
            partner.city,
          )];
      if (index == null || schools[index].isPartner) {
        added.add(partner);
      } else {
        schools[index] = schools[index].asPartner(serverId: partner.id);
      }
    }
    return SchoolDirectory._(
      List.unmodifiable([...schools, ...added]),
      partnersPending: partnersPending,
    );
  }

  final List<Establishment> schools;

  /// La liste des partenaires n'est pas encore arrivée : la recherche
  /// fonctionne déjà sur le catalogue de référence.
  final bool partnersPending;

  Establishment? byId(String id) {
    for (final school in schools) {
      if (school.id == id) return school;
    }
    return null;
  }

  /// Villes proposées en filtre, de la plus fournie à la moins fournie.
  List<String> topCities({int count = 2}) {
    final counts = <String, int>{};
    for (final school in schools) {
      if (school.city.isEmpty) continue;
      counts.update(school.city, (n) => n + 1, ifAbsent: () => 1);
    }
    final cities = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return cities.take(count).toList(growable: false);
  }
}

/// Annuaire de l'inscription. Aucune requête par frappe : le catalogue est
/// local, les partenaires sont demandés une fois ; hors ligne, la recherche
/// reste complète, sans badge partenaire.
final schoolDirectoryProvider =
    Provider.autoDispose<AsyncValue<SchoolDirectory>>((ref) {
      final reference = ref.watch(referenceEstablishmentsProvider);
      final partners = ref.watch(registrationEstablishmentsProvider);
      return reference.whenData(
        (schools) => SchoolDirectory.merge(
          reference: schools,
          partners: partners.valueOrNull ?? const [],
          partnersPending: partners.isLoading,
        ),
      );
    });
