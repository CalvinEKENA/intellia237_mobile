import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/telemetry/startup_trace.dart';
import '../data/student_home_repository.dart';
import '../domain/student_home_snapshot.dart';

final studentHomeControllerProvider =
    AsyncNotifierProvider<StudentHomeController, StudentHomeSnapshot>(
      StudentHomeController.new,
    );

class StudentHomeController extends AsyncNotifier<StudentHomeSnapshot> {
  StudentHomeRepository get _repository =>
      ref.read(studentHomeRepositoryProvider);

  StreamSubscription<StudentHomeSnapshot>? _hydration;

  /// Change à chaque chargement et à la destruction : une hydratation d'un
  /// chargement dépassé ne touche jamais l'état.
  int _generation = 0;

  @override
  Future<StudentHomeSnapshot> build() async {
    ref.onDispose(_stopHydration);
    final firstName = ref.watch(studentFirstNameProvider);
    return _load(firstName);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(ref.read(studentFirstNameProvider)),
    );
  }

  /// L'accueil immédiat, puis ses compléments à mesure qu'ils arrivent.
  Future<StudentHomeSnapshot> _load(String firstName) async {
    _stopHydration();
    final generation = _generation;
    final repository = _repository;
    final snapshot = await StartupTrace.measure(
      'home-snapshot',
      () => repository.fetchHomeSnapshot(firstName: firstName),
    );
    if (repository is ProgressiveStudentHomeRepository) {
      // Après que l'accueil immédiat est posé (fin de `build`), jamais avant.
      Timer.run(() {
        if (generation != _generation) return;
        _hydration = (repository as ProgressiveStudentHomeRepository)
            .hydrate(snapshot)
            .listen((next) {
              if (generation == _generation) state = AsyncData(next);
            });
      });
    }
    return snapshot;
  }

  void _stopHydration() {
    _generation++;
    unawaited(_hydration?.cancel());
    _hydration = null;
  }
}
