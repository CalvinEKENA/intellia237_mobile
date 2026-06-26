import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/onboarding_preferences.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/app_role.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider du repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provider du contrôleur d'authentification
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState.bootstrapping();

  /// Vérifie la session Firebase existante au démarrage
  Future<void> completeBootstrap() async {
    if (state.status != AuthStatus.bootstrapping) return;

    try {
      final user = await _repo.getCurrentUser().timeout(
        const Duration(seconds: 8),
      );
      if (user != null) {
        await _markOnboardingSeen();
        state = AuthState.authenticated(
          role: user.role,
          userId: user.uid,
          email: user.email,
          firstName: user.firstName,
        );
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Connexion email/mot de passe
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repo.signInWithEmail(
        email: email,
        password: password,
      );

      await _markOnboardingSeen();
      state = AuthState.authenticated(
        role: user.role,
        userId: user.uid,
        email: user.email,
        firstName: user.firstName,
      );
    } on AuthError catch (e) {
      state = AuthState.unauthenticated(error: e.message);
    } catch (_) {
      state = const AuthState.unauthenticated(
        error: 'Une erreur inattendue est survenue.',
      );
    }
  }

  /// Inscription avec rôle
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      await _markOnboardingSeen();
      state = AuthState.authenticated(
        role: user.role,
        userId: user.uid,
        email: user.email,
        firstName: user.firstName,
      );
    } on AuthError catch (e) {
      state = AuthState.unauthenticated(error: e.message);
    } catch (_) {
      state = const AuthState.unauthenticated(
        error: 'Une erreur inattendue est survenue.',
      );
    }
  }

  /// Envoi de l'email de réinitialisation
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordResetEmail(email);
      return true;
    } on AuthError {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Déconnexion propre
  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } catch (_) {
      // On déconnecte localement même si Firebase échoue
    }
    state = const AuthState.unauthenticated();
  }

  /// Utilise les donnees reelles retournees apres un onboarding/inscription.
  void setAuthenticatedUser({
    required AppRole role,
    required String userId,
    required String email,
    required String firstName,
  }) {
    unawaited(_markOnboardingSeen());
    state = AuthState.authenticated(
      role: role,
      userId: userId,
      email: email,
      firstName: firstName,
    );
  }

  /// Efface l'erreur courante
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<void> _markOnboardingSeen() async {
    if (ref.read(hasSeenOnboardingProvider)) {
      return;
    }

    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    await OnboardingPreferences().setSeenOnboarding(true);
  }
}
