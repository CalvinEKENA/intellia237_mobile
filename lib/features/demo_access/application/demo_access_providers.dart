import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../../learn/application/learn_providers.dart';
import '../domain/demo_access.dart';

/// Le compte connecté est le compte démo.
final isDemoAccessProvider = Provider<bool>(
  (ref) =>
      ref.watch(authControllerProvider.select((auth) => auth.userId)) ==
      DemoAccess.uid,
);

/// Change la classe du compte démo, côté serveur (le profil ne se modifie
/// jamais depuis l'appareil).
abstract interface class DemoAccessService {
  Future<void> setClass(DemoClassOption option);
}

class FirebaseDemoAccessService implements DemoAccessService {
  FirebaseDemoAccessService([FirebaseFunctions? functions])
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<void> setClass(DemoClassOption option) async {
    await _functions.httpsCallable('setDemoAccessClass').call<void>({
      'classLevel': option.classLevel,
      'series': option.seriesValue,
    });
  }
}

final demoAccessServiceProvider = Provider<DemoAccessService>(
  (ref) => FirebaseDemoAccessService(),
);

/// Le message d'accueil n'est montré qu'une fois par appareil.
abstract interface class DemoWelcomeMemory {
  Future<bool> seen();
  Future<void> markSeen();
}

class SharedPreferencesDemoWelcomeMemory implements DemoWelcomeMemory {
  static const _key = 'demo_access_welcome_seen_v1';

  @override
  Future<bool> seen() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> markSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}

final demoWelcomeMemoryProvider = Provider<DemoWelcomeMemory>(
  (ref) => SharedPreferencesDemoWelcomeMemory(),
);

/// Classe explorée en ce moment par le compte démo (d'après son profil).
final demoCurrentClassProvider = FutureProvider<DemoClassOption?>((ref) async {
  final context = await ref.watch(studentAcademicContextProvider.future);
  return DemoAccess.optionFor(context.classLevel, context.series);
});

/// Change de classe, puis recharge tout ce qui en dépend (cours, quiz,
/// accueil) à partir du profil mis à jour.
Future<void> changeDemoClass(WidgetRef ref, DemoClassOption option) async {
  await ref.read(demoAccessServiceProvider).setClass(option);
  ref.invalidate(studentAcademicContextProvider);
}
