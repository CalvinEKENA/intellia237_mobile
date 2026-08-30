import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('edunova-aabd1 is the canonical default Firebase target', () {
      final aliases =
          jsonDecode(File('.firebaserc').readAsStringSync())
              as Map<String, dynamic>;
      expect(
        (aliases['projects'] as Map<String, dynamic>)['default'],
        'edunova-aabd1',
      );
    });

    test('keeps production store and Firebase identifiers stable', () {
      expect(AppConfig.production.appName, 'Intellia 237');
      expect(AppConfig.production.firebaseProjectId, 'edunova-aabd1');
      expect(AppConfig.production.androidApplicationId, 'com.edunova.app');
      expect(AppConfig.production.iosBundleId, 'com.edunova.app');
    });

    test('defines a separate staging identity', () {
      expect(AppConfig.staging.appName, 'Intellia 237 Staging');
      expect(AppConfig.staging.firebaseProjectId, 'intellia237-staging');
      expect(
        AppConfig.staging.androidApplicationId,
        'com.intellia237.app.staging',
      );
      expect(AppConfig.staging.iosBundleId, 'com.intellia237.app.staging');
    });

    test('blocks staging startup with production Firebase options', () {
      final options = _firebaseOptions(
        projectId: 'edunova-aabd1',
        storageBucket: 'edunova-aabd1.firebasestorage.app',
      );

      expect(
        () => AppConfig.staging.validateFirebaseOptions(options),
        throwsStateError,
      );
    });

    test('accepts matching Firebase options', () {
      final options = _firebaseOptions(
        projectId: 'edunova-aabd1',
        storageBucket: 'edunova-aabd1.firebasestorage.app',
      );

      expect(
        () => AppConfig.production.validateFirebaseOptions(options),
        returnsNormally,
      );
    });

    test('blocks a production entrypoint inside a staging flavor', () {
      expect(
        () => AppConfig.production.validateBuildFlavor('staging'),
        throwsStateError,
      );
    });

    test('accepts matching and flavorless entrypoints', () {
      expect(
        () => AppConfig.staging.validateBuildFlavor('staging'),
        returnsNormally,
      );
      expect(
        () => AppConfig.production.validateBuildFlavor(null),
        returnsNormally,
      );
    });

    test('blocks a matching project with the wrong Storage bucket', () {
      final options = _firebaseOptions(
        projectId: 'intellia237-staging',
        storageBucket: 'edunova-aabd1.firebasestorage.app',
      );

      expect(
        () => AppConfig.staging.validateFirebaseOptions(options),
        throwsStateError,
      );
    });
  });
}

FirebaseOptions _firebaseOptions({
  required String projectId,
  required String storageBucket,
}) {
  return FirebaseOptions(
    apiKey: 'test-api-key',
    appId: '1:123:web:test',
    messagingSenderId: '123',
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
