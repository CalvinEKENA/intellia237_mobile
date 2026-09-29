import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/partner_access/domain/partner_access.dart';
import 'package:intellia237/features/partner_access/domain/partner_digest.dart';

import '../../../tool/partner_access_digest.dart';
import '../../support/repo_scan.dart';

/// Une valeur devenue publique est révoquée : l'application ne la reconnaît
/// plus, l'outil la refuse, et le dépôt ne la contient nulle part. Le dépôt ne
/// connaît que le condensat de la valeur révoquée, jamais la valeur. Toutes les
/// valeurs de ce fichier sont fictives.
void main() {
  const fictional = 'ancienne.valeur@exemple.test';
  const current = 'nouvelle.valeur@exemple.test';

  tearDown(PartnerAccess.debugReset);

  group('la liste des valeurs révoquées', () {
    test('ne contient que des condensats, jamais une valeur lisible', () {
      expect(PartnerDigest.revokedDigests, isNotEmpty);
      for (final entry in PartnerDigest.revokedDigests) {
        expect(entry, matches(RegExp(r'^[0-9a-f]{64}$')));
      }
    });

    test('reconnaît une valeur révoquée après trim et minuscules', () {
      final revoked = {PartnerDigest.sha256Hex(fictional)};
      expect(PartnerDigest.isRevoked(fictional, revoked: revoked), isTrue);
      expect(PartnerDigest.isRevoked(current, revoked: revoked), isFalse);
      expect(PartnerDigest.isRevoked('', revoked: revoked), isFalse);
    });
  });

  group('l’application', () {
    test('ne reconnaît jamais une valeur révoquée, même avec son propre '
        'condensat de construction', () {
      PartnerAccess.debugUseDigest(
        PartnerDigest.create(fictional, iterations: 64).encode(),
      );
      expect(PartnerAccess.recognizes(fictional), isTrue);
      PartnerAccess.debugRevoke(fictional);
      expect(PartnerAccess.recognizes(fictional), isFalse);
      expect(
        PartnerAccess.recognizes('  ${fictional.toUpperCase()} '),
        isFalse,
      );
    });

    test('la révocation ne touche pas la valeur en vigueur', () {
      PartnerAccess.debugUseDigest(
        PartnerDigest.create(current, iterations: 64).encode(),
      );
      PartnerAccess.debugRevoke(fictional);
      expect(PartnerAccess.recognizes(current), isTrue);
      expect(PartnerAccess.recognizes(fictional), isFalse);
    });

    test('un condensat de construction périmé (ancienne valeur) ne reconnaît '
        'plus rien de révoqué, et la nouvelle valeur seule est reconnue', () {
      PartnerAccess.debugRevoke(fictional);
      PartnerAccess.debugUseDigest(
        PartnerDigest.create(current, iterations: 64).encode(),
      );
      expect(PartnerAccess.recognizes(fictional), isFalse);
      expect(PartnerAccess.recognizes(current), isTrue);
    });
  });

  group('l’outil de génération', () {
    test('accepte une valeur qui a l’allure d’une adresse', () {
      expect(problemWithPartnerValue(current), isNull);
    });

    test('refuse une valeur sans @, trop courte ou trop longue', () {
      expect(problemWithPartnerValue('sans-arobase'), isNotNull);
      expect(problemWithPartnerValue('a@'), isNotNull);
      expect(problemWithPartnerValue(''), isNotNull);
      expect(problemWithPartnerValue('${'x' * 250}@y.zz'), isNotNull);
    });

    test('refuse une valeur révoquée', () {
      final revoked = {PartnerDigest.sha256Hex(fictional)};
      final problem = problemWithPartnerValue(fictional, revoked: revoked);
      expect(problem, contains('révoquée'));
      expect(problemWithPartnerValue(current, revoked: revoked), isNull);
    });

    test('normalise comme l’application et le serveur', () {
      expect(
        normalizePartnerValue('  Nouvelle.Valeur@Exemple.TEST\n'),
        current,
      );
      expect(normalizePartnerValue(null), '');
    });
  });

  test('aucun fichier du dépôt ne contient une valeur révoquée', () {
    final result = scanRepoForEmails(
      (token) => PartnerDigest.isRevoked(PartnerAccess.normalize(token)),
    );
    expect(
      result.scanned,
      greaterThan(500),
      reason: 'le contrôle a bien parcouru le dépôt',
    );
    expect(
      result.found,
      isEmpty,
      reason: 'une valeur révoquée figure dans : ${result.found}',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
