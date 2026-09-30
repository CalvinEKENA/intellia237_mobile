import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/data/student_academic_profile_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profil académique : le dernier profil connu de l'appareil sert aussitôt,
/// le serveur le confirme ensuite ; un rafraîchissement explicite relit
/// toujours le serveur.
Map<String, dynamic> _profile(String series) => {
  'classLevel': 'Terminale',
  'series': series,
};

class _Source
    implements
        StudentAcademicProfileSource,
        CachedStudentAcademicProfileSource {
  _Source({this.cached, required this.server});

  Map<String, dynamic>? cached;
  Map<String, dynamic> server;
  int serverReads = 0;
  int cacheReads = 0;
  Completer<void>? gate;

  @override
  Future<Map<String, dynamic>?> fetchCached(String uid) async {
    cacheReads++;
    return cached;
  }

  @override
  Future<Map<String, dynamic>> fetch(String uid) async {
    serverReads++;
    await gate?.future;
    return server;
  }
}

ProviderContainer _container(_Source source) {
  final container = ProviderContainer(
    overrides: [studentAcademicProfileSourceProvider.overrideWithValue(source)],
  );
  addTearDown(container.dispose);
  _signIn(container);
  return container;
}

void _signIn(ProviderContainer container) => container
    .read(authControllerProvider.notifier)
    .setAuthenticatedUser(
      role: AppRole.student,
      userId: 'eleve-1',
      email: 'eleve@example.com',
      firstName: 'Amina',
    );

Future<void> _drain() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('profil connu : servi sans attendre le serveur', () async {
    final source = _Source(cached: _profile('D'), server: _profile('D'))
      ..gate = Completer<void>();
    final container = _container(source);
    container.listen(studentAcademicContextProvider, (_, _) {});

    final context = await container.read(studentAcademicContextProvider.future);
    expect(context.series, 'D');
    expect(source.cacheReads, 1);
    // La confirmation en ligne est partie, mais rien ne l'attend.
    expect(source.serverReads, 1);
    source.gate!.complete();
    await _drain();
    await _drain();
    // Même profil : aucune relecture.
    expect(container.read(studentAcademicContextProvider).value?.series, 'D');
    expect(source.serverReads, 1);
  });

  test('le serveur a changé : sa réponse remplace le profil connu', () async {
    final source = _Source(cached: _profile('D'), server: _profile('C'));
    final container = _container(source);
    container.listen(studentAcademicContextProvider, (_, _) {});

    expect(
      (await container.read(studentAcademicContextProvider.future)).series,
      'D',
    );
    for (var i = 0; i < 5; i++) {
      await _drain();
    }
    expect(
      (await container.read(studentAcademicContextProvider.future)).series,
      'C',
    );
    // La réponse en ligne est appliquée telle quelle, sans seconde lecture.
    expect(source.serverReads, 1);
  });

  test('aucun profil connu : lecture en ligne', () async {
    final source = _Source(server: _profile('D'));
    final container = _container(source);
    final context = await container.read(studentAcademicContextProvider.future);
    expect(context.series, 'D');
    expect(source.serverReads, 1);
  });

  test('rafraîchissement explicite : toujours le serveur', () async {
    final source = _Source(cached: _profile('D'), server: _profile('D'));
    final container = _container(source);
    container.listen(studentAcademicContextProvider, (_, _) {});
    await container.read(studentAcademicContextProvider.future);
    await _drain();

    // Ex. changement de classe du compte démo : le serveur a la nouvelle.
    source.server = _profile('C');
    container.invalidate(studentAcademicContextProvider);
    final refreshed = await container.read(
      studentAcademicContextProvider.future,
    );
    expect(refreshed.series, 'C');
    expect(source.cacheReads, 1);
  });

  test(
    'un nouvel état d\'authentification de la même identité ne relit rien',
    () async {
      final source = _Source(server: _profile('D'));
      final container = _container(source);
      container.listen(studentAcademicContextProvider, (_, _) {});
      await container.read(studentAcademicContextProvider.future);
      expect(source.serverReads, 1);

      // Revalidation de session : même élève, nouvel objet d'état.
      _signIn(container);
      await _drain();
      await container.read(studentAcademicContextProvider.future);
      expect(source.serverReads, 1);
    },
  );
}
