import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/partner_access/domain/partner_digest.dart';

import '../../../tool/partner_release_check.dart';

/// La barrière de la construction partenaire : sans condensat valide, la
/// construction échoue avec un message clair, plutôt que de publier un bundle
/// qui ne reconnaîtrait pas l'accès partenaire. Valeur fictive.
void main() {
  final good = PartnerDigest.create(
    'nouvelle.valeur@exemple.test',
    iterations: 64,
  ).encode();

  String file(Map<String, Object?> content) => jsonEncode(content);

  test('fichier absent : échec clair, avec le remède', () {
    final result = inspectPartnerBuildConfig(null);
    expect(result.isReady, isFalse);
    expect(result.problem, contains('config/partner_access.local.json'));
    expect(result.problem, contains('est absent'));
    expect(result.problem, contains('reconnaîtrait pas'));
    expect(
      result.problem,
      contains('dart run tool/partner_access_digest.dart'),
    );
  });

  test('fichier qui n’est pas du JSON : échec clair', () {
    for (final text in ['', 'pas du json', '{', '[1, 2']) {
      final result = inspectPartnerBuildConfig(text);
      expect(result.isReady, isFalse, reason: text);
      expect(result.problem, contains('JSON'), reason: text);
    }
  });

  test('JSON sans la clé, ou avec une clé vide ou du mauvais type : échec', () {
    for (final text in [
      file({}),
      file({'AUTRE': 'x'}),
      file({'PARTNER_ACCESS_DIGEST': ''}),
      file({'PARTNER_ACCESS_DIGEST': '   '}),
      file({'PARTNER_ACCESS_DIGEST': 42}),
      file({'PARTNER_ACCESS_DIGEST': null}),
      '[]',
      '"texte"',
    ]) {
      final result = inspectPartnerBuildConfig(text);
      expect(result.isReady, isFalse, reason: text);
      expect(result.problem, contains('PARTNER_ACCESS_DIGEST'), reason: text);
    }
  });

  test('condensat mal formé : échec', () {
    for (final digest in [
      'v1:20:4096:zz:zz',
      'v2:20:64:$good',
      'abc',
      good.substring(3),
    ]) {
      final result = inspectPartnerBuildConfig(
        file({'PARTNER_ACCESS_DIGEST': digest}),
      );
      expect(result.isReady, isFalse, reason: digest);
      expect(result.problem, contains('mal formé'), reason: digest);
    }
  });

  test('condensat valide : prêt', () {
    final result = inspectPartnerBuildConfig(
      file({'PARTNER_ACCESS_DIGEST': good}),
    );
    expect(result.isReady, isTrue);
    expect(result.problem, isNull);
    expect(result.digest!.matches('nouvelle.valeur@exemple.test'), isTrue);
    expect(result.digest!.matches('autre@exemple.test'), isFalse);
  });

  test('le condensat lu est bien celui de la construction', () {
    // Le même texte que celui de `--dart-define-from-file`.
    final result = inspectPartnerBuildConfig(
      '{"PARTNER_ACCESS_DIGEST": "$good"}\n',
    );
    expect(result.isReady, isTrue);
    expect(result.digest!.encode(), good);
  });
}
