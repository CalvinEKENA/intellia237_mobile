import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/establishment.dart';
import 'establishment_catalog.dart';

final registrationEstablishmentsProvider =
    FutureProvider.autoDispose<List<Establishment>>((ref) async {
      final response =
          await FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('listRegistrationEstablishments')
              .call<Map<String, dynamic>>();
      return (response.data['establishments'] as List)
          .map((raw) {
            final row = Map<String, dynamic>.from(raw as Map);
            return Establishment(
              id: row['id'] as String,
              officialName: row['name'] as String,
              normalizedName: EstablishmentSearch.normalize(
                row['name'] as String,
              ),
              aliases: const [],
              region: row['region'] as String? ?? '',
              city: row['city'] as String? ?? '',
              type: EstablishmentType.lycee,
              subsystem: EstablishmentSubsystem.bilingual,
              educationTypes: EstablishmentEducationType.values,
              status: EstablishmentCatalogStatus.active,
            );
          })
          .toList(growable: false);
    });
