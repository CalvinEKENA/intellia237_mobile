import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class Intellia237App extends ConsumerWidget {
  const Intellia237App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // L'identite INTELLIA237 est volontairement lumineuse sur tous les
      // parcours d'entree; le theme sombre reste disponible aux ecrans qui
      // devront le demander explicitement dans une phase ulterieure.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();
        if (!config.isStaging) {
          return app;
        }

        return Banner(
          message: 'STAGING',
          location: BannerLocation.topEnd,
          color: Colors.deepOrange,
          child: app,
        );
      },
    );
  }
}
