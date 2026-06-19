import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('keeps production store and Firebase identifiers stable', () {
      expect(AppConfig.production.appName, 'INTELLIA237');
      expect(AppConfig.production.firebaseProjectId, 'edunova-aabd1');
      expect(AppConfig.production.androidApplicationId, 'com.edunova.app');
      expect(AppConfig.production.iosBundleId, 'com.edunova.app');
    });

    test('defines a separate staging identity', () {
      expect(AppConfig.staging.appName, 'INTELLIA237 Staging');
      expect(AppConfig.staging.firebaseProjectId, 'intellia237-staging');
      expect(
        AppConfig.staging.androidApplicationId,
        'com.intellia237.app.staging',
      );
      expect(AppConfig.staging.iosBundleId, 'com.intellia237.app.staging');
    });

    test('blocks staging startup with production Firebase options', () {
      final options = _firebaseOptions(projectId: 'edunova-aabd1');

      expect(
        () => AppConfig.staging.validateFirebaseOptions(options),
        throwsStateError,
      );
    });

    test('accepts matching Firebase options', () {
      final options = _firebaseOptions(projectId: 'edunova-aabd1');

      expect(
        () => AppConfig.production.validateFirebaseOptions(options),
        returnsNormally,
      );
    });
  });
}

FirebaseOptions _firebaseOptions({required String projectId}) {
  return FirebaseOptions(
    apiKey: 'test-api-key',
    appId: '1:123:web:test',
    messagingSenderId: '123',
    projectId: projectId,
  );
}
