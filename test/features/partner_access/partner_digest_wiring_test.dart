import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/partner_access/domain/partner_access.dart';
import 'package:intellia237/features/partner_access/domain/partner_digest.dart';

import '../../support/repo_scan.dart';

/// Contrôle de la construction réelle, jamais joué par la CI : il faut fournir
/// le condensat (le même que pour la construction) et la valeur à vérifier,
/// que le dépôt ne connaît pas :
///
///   flutter test test/features/partner_access/partner_digest_wiring_test.dart
///     --dart-define-from-file=config/partner_access.local.json
///     --dart-define=PARTNER_ACCESS_CHECK_ADDRESS=VALEUR
///
/// Il prouve deux choses : le condensat compilé reconnaît bien la valeur (la
/// construction livrée fera son travail), et AUCUN fichier du dépôt ne contient
/// une valeur que ce condensat reconnaît (elle n'a pas fuité).
///
/// Avec `--dart-define=PARTNER_ACCESS_REVOKED_ADDRESS=ANCIENNE_VALEUR`, il
/// prouve aussi qu'une valeur révoquée n'est pas reconnue, même quand le
/// condensat de la construction est celui de cette valeur.
void main() {
  const checkAddress = String.fromEnvironment('PARTNER_ACCESS_CHECK_ADDRESS');
  const revokedAddress = String.fromEnvironment(
    'PARTNER_ACCESS_REVOKED_ADDRESS',
  );
  const skipReason =
      'Fournir PARTNER_ACCESS_DIGEST et PARTNER_ACCESS_CHECK_ADDRESS '
      '(voir l\'en-tête de ce fichier).';
  final skip = checkAddress.isEmpty || !PartnerAccess.isConfigured
      ? skipReason
      : false;

  tearDown(PartnerAccess.debugReset);

  test(
    'le condensat compilé reconnaît la valeur, avec les variantes de saisie',
    () {
      expect(PartnerAccess.isConfigured, isTrue);
      expect(PartnerAccess.recognizes(checkAddress), isTrue);
      expect(
        PartnerAccess.recognizes(' ${checkAddress.toUpperCase()} '),
        isTrue,
      );
      expect(PartnerAccess.recognizes('x$checkAddress'), isFalse);
      expect(PartnerAccess.recognizes(''), isFalse);
      expect(
        PartnerDigest.isRevoked(PartnerAccess.normalize(checkAddress)),
        isFalse,
        reason: 'la valeur à livrer ne doit pas être une valeur révoquée',
      );
    },
    skip: skip,
  );

  test(
    'aucun fichier du dépôt ne contient la valeur',
    () {
      final result = scanRepoForEmails(PartnerAccess.recognizes);
      expect(
        result.scanned,
        greaterThan(500),
        reason: 'le contrôle a bien parcouru le dépôt',
      );
      expect(
        result.found,
        isEmpty,
        reason: 'la valeur figure dans : ${result.found}',
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'une valeur révoquée n’est jamais reconnue, même avec son propre condensat',
    () {
      expect(
        PartnerDigest.isRevoked(PartnerAccess.normalize(revokedAddress)),
        isTrue,
        reason: 'la liste des valeurs révoquées connaît cette valeur',
      );
      PartnerAccess.debugUseDigest(
        PartnerDigest.create(
          PartnerAccess.normalize(revokedAddress),
          iterations: 64,
        ).encode(),
      );
      expect(PartnerAccess.isConfigured, isTrue);
      expect(PartnerAccess.recognizes(revokedAddress), isFalse);
      expect(PartnerAccess.recognizes(revokedAddress.toUpperCase()), isFalse);
    },
    skip: revokedAddress.isEmpty
        ? 'Fournir PARTNER_ACCESS_REVOKED_ADDRESS (voir l\'en-tête).'
        : false,
  );
}
