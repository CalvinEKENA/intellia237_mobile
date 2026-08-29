import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/config/app_config.dart';
import 'package:intellia237/core/security/app_check_service.dart';

void main() {
  group('App Check provider selection', () {
    test('uses Play Integrity for production release builds', () {
      expect(
        selectAndroidAppCheckAttestation(
          config: AppConfig.production,
          isDebugBuild: false,
        ),
        AndroidAppCheckAttestation.playIntegrity,
      );
    });

    test('uses the debug provider for staging releases', () {
      expect(
        selectAndroidAppCheckAttestation(
          config: AppConfig.staging,
          isDebugBuild: false,
        ),
        AndroidAppCheckAttestation.debug,
      );
    });

    test('uses the debug provider for local production debug builds', () {
      expect(
        selectAndroidAppCheckAttestation(
          config: AppConfig.production,
          isDebugBuild: true,
        ),
        AndroidAppCheckAttestation.debug,
      );
    });
  });
}
