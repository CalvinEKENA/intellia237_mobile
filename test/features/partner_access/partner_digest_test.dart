import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/partner_access/domain/partner_access.dart';
import 'package:intellia237/features/partner_access/domain/partner_digest.dart';

/// L'application ne connaît pas l'adresse du compte partenaire : le dépôt est
/// public. Elle ne connaît que son condensat salé, fourni à la construction.
/// Toutes les adresses de ce fichier sont fictives.
void main() {
  const address = 'partenaire.essai@exemple.test';
  const salt = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

  String hex(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  tearDown(PartnerAccess.debugReset);

  group('PBKDF2-HMAC-SHA256', () {
    // Valeurs de référence, recoupées avec `hashlib.pbkdf2_hmac` (Python).
    test('donne les valeurs de référence', () {
      final password = utf8.encode('password');
      final saltBytes = utf8.encode('salt');
      expect(
        hex(pbkdf2Sha256(password, saltBytes, 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        hex(pbkdf2Sha256(password, saltBytes, 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
      expect(
        hex(pbkdf2Sha256(password, saltBytes, 4096)),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });
  });

  group('le condensat', () {
    test('reconnaît l’adresse exacte, pas une autre', () {
      final digest = PartnerDigest.create(address, salt: salt, iterations: 64);
      expect(digest.matches(address), isTrue);
      for (final other in [
        'partenaire.essai@exemple.com',
        'partenaire.essai2@exemple.test',
        'Partenaire.essai@exemple.test',
        '',
        address.substring(1),
      ]) {
        expect(digest.matches(other), isFalse, reason: other);
      }
      expect(digest.length, address.length);
    });

    test('s’encode et se relit sans perte', () {
      final digest = PartnerDigest.create(address, salt: salt, iterations: 64);
      final encoded = digest.encode();
      expect(encoded, startsWith('v1:${address.length}:64:'));
      final again = PartnerDigest.tryParse(encoded)!;
      expect(again.encode(), encoded);
      expect(again.matches(address), isTrue);
      expect(PartnerDigest.tryParse('  $encoded \n'), isNotNull);
    });

    test('ne contient pas l’adresse, ni un fragment lisible', () {
      final encoded = PartnerDigest.create(address, iterations: 64).encode();
      expect(encoded, isNot(contains('partenaire')));
      expect(encoded, isNot(contains('exemple')));
      expect(encoded, isNot(contains('@')));
    });

    test('le sel est aléatoire : deux condensats de la même adresse '
        'diffèrent', () {
      final first = PartnerDigest.create(address, iterations: 64).encode();
      final second = PartnerDigest.create(address, iterations: 64).encode();
      expect(first, isNot(second));
    });

    test('un condensat absent ou mal formé est refusé, sans exception', () {
      final good = PartnerDigest.create(address, salt: salt, iterations: 64);
      final parts = good.encode().split(':');
      for (final bad in [
        '',
        '   ',
        'v1',
        'v2:${parts[1]}:${parts[2]}:${parts[3]}:${parts[4]}',
        'v1:${parts[1]}:${parts[2]}:${parts[3]}',
        'v1:${parts[1]}:${parts[2]}:${parts[3]}:${parts[4]}:extra',
        'v1:2:${parts[2]}:${parts[3]}:${parts[4]}',
        'v1:999:${parts[2]}:${parts[3]}:${parts[4]}',
        'v1:x:${parts[2]}:${parts[3]}:${parts[4]}',
        'v1:${parts[1]}:0:${parts[3]}:${parts[4]}',
        'v1:${parts[1]}:-5:${parts[3]}:${parts[4]}',
        'v1:${parts[1]}:99999999:${parts[3]}:${parts[4]}',
        'v1:${parts[1]}:${parts[2]}:zz:${parts[4]}',
        'v1:${parts[1]}:${parts[2]}:0102:${parts[4]}',
        'v1:${parts[1]}:${parts[2]}:${parts[3]}:abcd',
        'v1:${parts[1]}:${parts[2]}:${parts[3]}:${'g' * 64}',
      ]) {
        expect(PartnerDigest.tryParse(bad), isNull, reason: bad);
      }
    });
  });

  group('la reconnaissance dans l’application', () {
    test('sans condensat, aucune adresse n’est reconnue', () {
      PartnerAccess.debugUseDigest(null);
      expect(PartnerAccess.isConfigured, isFalse);
      for (final raw in [address, '', '   ', 'a@b.c']) {
        expect(PartnerAccess.recognizes(raw), isFalse, reason: raw);
      }
    });

    test('un condensat mal formé équivaut à aucun condensat', () {
      PartnerAccess.debugUseDigest('n importe quoi');
      expect(PartnerAccess.isConfigured, isFalse);
      expect(PartnerAccess.recognizes(address), isFalse);
    });

    test(
      'avec un condensat : trim et minuscules, l’adresse exacte seulement',
      () {
        PartnerAccess.debugUseDigest(
          PartnerDigest.create(address, iterations: 64).encode(),
        );
        expect(PartnerAccess.isConfigured, isTrue);
        for (final raw in [
          address,
          address.toUpperCase(),
          '  $address  ',
          '\tPartenaire.Essai@Exemple.TEST\n',
        ]) {
          expect(PartnerAccess.recognizes(raw), isTrue, reason: raw);
        }
        for (final raw in [
          'partenaire.essai@exemple.com',
          'partenaire.essai2@exemple.test',
          'xpartenaire.essai@exemple.test',
          'partenaire.essai@exemple.test.evil.example',
          '',
        ]) {
          expect(PartnerAccess.recognizes(raw), isFalse, reason: raw);
        }
      },
    );

    test('la construction du dépôt ne fournit aucun condensat', () {
      const built = String.fromEnvironment('PARTNER_ACCESS_DIGEST');
      PartnerAccess.debugReset();
      // Une construction locale peut en fournir un ; le dépôt et la CI, non.
      expect(PartnerAccess.isConfigured, built.isNotEmpty);
    });
  });
}
