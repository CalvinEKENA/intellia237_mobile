import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'bootstrap.dart';

void main() {
  bootstrap(
    config: AppConfig.staging,
    builder: () => ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.staging)],
      child: const Intellia237App(),
    ),
  );
}
