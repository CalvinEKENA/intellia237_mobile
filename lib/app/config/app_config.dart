import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { production, staging }

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.production);

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
    required this.androidApplicationId,
    required this.iosBundleId,
    required this.enableDebugTools,
  });

  static const production = AppConfig(
    environment: AppEnvironment.production,
    appName: 'Intellia 237',
    firebaseProjectId: 'edunova-aabd1',
    firebaseStorageBucket: 'edunova-aabd1.firebasestorage.app',
    androidApplicationId: 'com.edunova.app',
    iosBundleId: 'com.edunova.app',
    enableDebugTools: false,
  );

  static const staging = AppConfig(
    environment: AppEnvironment.staging,
    appName: 'Intellia 237 Staging',
    firebaseProjectId: 'intellia237-staging',
    firebaseStorageBucket: 'intellia237-staging.firebasestorage.app',
    androidApplicationId: 'com.intellia237.app.staging',
    iosBundleId: 'com.intellia237.app.staging',
    enableDebugTools: true,
  );

  final AppEnvironment environment;
  final String appName;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final String androidApplicationId;
  final String iosBundleId;
  final bool enableDebugTools;

  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  String get environmentName => environment.name;

  void validateFirebaseOptions(FirebaseOptions options) {
    if (options.projectId == firebaseProjectId) {
      return;
    }

    throw StateError(
      'Firebase options project "${options.projectId}" do not match '
      '$environmentName project "$firebaseProjectId". '
      'Create real Firebase client options for this environment before launch.',
    );
  }
}
