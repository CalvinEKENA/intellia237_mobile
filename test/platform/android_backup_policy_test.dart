import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contrat de la politique de sauvegarde Android : aucune donnée de mineur ni
/// état de connexion ne part dans une sauvegarde cloud ou un transfert.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('the application opts out of Android backup', () {
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  test('Android 12+ rules exclude every domain from cloud and transfer', () {
    final rules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      final start = rules.indexOf('<$section>');
      final end = rules.indexOf('</$section>');
      final body = start < 0 || end < start
          ? null
          : rules.substring(start, end);
      expect(body, isNotNull, reason: section);
      for (final domain in ['root', 'file', 'database', 'sharedpref']) {
        expect(
          body,
          contains('<exclude domain="$domain" />'),
          reason: '$section doit exclure $domain',
        );
      }
      expect(body, isNot(contains('<include')));
    }
  });

  test('legacy auto-backup rules exclude shared preferences too', () {
    final rules = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();
    expect(rules, contains('<exclude domain="sharedpref" path="." />'));
    expect(rules, isNot(contains('<include')));
  });
}
