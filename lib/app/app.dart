import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'router/app_router.dart';
import 'session/learner_session.dart';
import 'theme/app_theme.dart';
import '../features/profile/application/user_preferences_controller.dart';
import '../core/widgets/network_status_banner.dart';
import '../core/network/network_status.dart';
import '../features/learn/application/learn_providers.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/app_role.dart';
import '../core/localization/app_locale_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/animations/screen_shatter.dart';
import '../core/system/intellia_system_bars.dart';
import '../core/notifications/notification_navigation_bus.dart';
import '../core/notifications/notification_push_service.dart';
import 'router/app_routes.dart';

class Intellia237App extends ConsumerWidget {
  const Intellia237App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final config = ref.watch(appConfigProvider);
    final preferences = ref.watch(userPreferencesProvider);
    final locale = ref.watch(appLocaleProvider);

    ref.listen<bool>(isOfflineProvider, (previous, offline) {
      if (!offline && previous != false) {
        unawaited(ref.read(learnActionsProvider).flushQueuedProgress());
      }
    });
    // Frontière de session apprenant : maintenue en vie pour toute la durée de
    // l'application, elle purge l'état élève à chaque changement d'identité.
    ref.watch(learnerSessionBoundaryProvider);

    ref.listen(authControllerProvider, (previous, auth) {
      final becameStudent =
          auth.isAuthenticated &&
          auth.role == AppRole.student &&
          (previous?.userId != auth.userId ||
              previous?.isAuthenticated != true);
      if (becameStudent && !ref.read(isOfflineProvider)) {
        unawaited(ref.read(learnActionsProvider).flushQueuedProgress());
      }
      if (previous?.userId != auth.userId || previous?.status != auth.status) {
        unawaited(NotificationPushService.syncForUser(auth.userId));
      }
    });
    ref.listen<AsyncValue<String>>(notificationNavigationProvider, (
      previous,
      next,
    ) {
      final route = next.valueOrNull;
      if (route == null || !AppRoutes.isSafeNotificationRoute(route)) return;
      router.go(route);
    });

    return MaterialApp.router(
      title: config.appName,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // L'identite INTELLIA237 est volontairement lumineuse sur tous les
      // parcours d'entree; le theme sombre reste disponible aux ecrans qui
      // devront le demander explicitement dans une phase ulterieure.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(1);
        final app = MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              (systemScale * preferences.textScale).clamp(0.8, 2.0),
            ),
            disableAnimations:
                media.disableAnimations ||
                preferences.reduceMotion ||
                preferences.dataSaver,
          ),
          child: NetworkStatusBanner(child: child ?? const SizedBox.shrink()),
        );
        final location = router.routeInformationProvider.value.uri.path;
        final surfaced = IntelliaSystemBars(
          tone: IntelliaSystemBarPolicy.toneForLocation(location),
          // Debris from a screen that is already gone has to paint above the
          // navigator, over the route that replaced it.
          child: ScreenShatterLayer(child: app),
        );
        if (!config.isStaging) return surfaced;

        return Banner(
          message: 'STAGING',
          location: BannerLocation.topEnd,
          color: Colors.deepOrange,
          child: surfaced,
        );
      },
    );
  }
}
