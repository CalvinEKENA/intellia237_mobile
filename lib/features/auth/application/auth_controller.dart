import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../onboarding/data/onboarding_preferences.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../data/auth_entry_preferences.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/app_role.dart';
import '../domain/auth_entry_intent.dart';
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
  static const _lastValidSessionKey = 'auth_last_valid_profile_v1';
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState.bootstrapping();

  /// Vérifie la session Firebase existante au démarrage
  Future<void> completeBootstrap() async {
    if (state.status != AuthStatus.bootstrapping) return;

    try {
      final resolution = await _resolveCurrentSession().timeout(
        const Duration(seconds: 8),
      );
      await _applyResolution(resolution);
    } catch (error) {
      await _applyRetryableFailure(errorCode: _safeErrorCode(error));
    }
  }

  /// Connexion email/mot de passe.
  ///
  /// Sous une intention d'entrée ([intent]), un compte d'un autre rôle n'est
  /// jamais ouvert : la session est refermée et le conflit est renvoyé.
  ///
  /// [beforeOpening] s'exécute une fois les identifiants acceptés et l'espace
  /// jugé compatible, juste avant que l'état global — et donc le routeur —
  /// n'ouvre l'espace : l'écran y montre le sceau complet. Son échec
  /// n'empêche jamais la connexion.
  Future<AuthEntryAdoption> signInWithEmail({
    required String email,
    required String password,
    AppRole? intent,
    Future<void> Function()? beforeOpening,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repo.signInWithEmail(
        email: email,
        password: password,
      );

      if (matchAuthEntry(intent: intent, accountRole: user.role) ==
          AuthEntryMatch.conflict) {
        await signOut();
        return AuthEntryRoleConflict(intent: intent!, accountRole: user.role);
      }

      if (beforeOpening != null) {
        try {
          await beforeOpening();
        } catch (_) {
          // L'ouverture de l'espace ne dépend pas de sa mise en scène.
        }
      }
      await _markOnboardingSeen();
      await _markAuthenticatedBefore();
      state = AuthState.authenticated(
        role: user.role,
        userId: user.uid,
        email: user.email,
        firstName: user.firstName,
        profileCompleted: user.profileCompleted,
        isSuperAdmin: user.isSuperAdmin,
        establishmentId: user.establishmentId,
      );
      await _cacheValidUser(user);
    } on AuthError catch (e) {
      if (_isProfileResolutionError(e.code)) {
        await _resolveAfterEstablishedCredential();
      } else {
        state = AuthState.unauthenticated(error: e.message);
      }
    } catch (error) {
      await _resolveAfterEstablishedCredential(
        fallbackErrorCode: _safeErrorCode(error),
      );
    }
    return const AuthEntryAdopted();
  }

  /// Adopte la session Firebase issue d'une vérification téléphone seulement
  /// si le rôle enregistré du compte correspond à l'espace choisi à l'entrée.
  ///
  /// Registre de décisions (QA appareil, round 2) : la session était adoptée
  /// sans condition, puis l'écran suivait le rôle enregistré ; un parent qui
  /// saisissait le numéro d'un élève ouvrait l'espace de cet élève. La
  /// compatibilité est désormais tranchée **avant** que l'état global ne
  /// change. Sur un conflit, aucun espace ne s'ouvre et le routeur ne voit
  /// jamais le compte de l'autre rôle ; le rôle enregistré n'est pas touché ;
  /// la session Firebase est refermée, pour qu'un redémarrage ne rouvre pas
  /// l'autre espace. Sans intention, le comportement historique est conservé.
  ///
  /// [beforeOpening] reçoit l'état qui va être adopté, avant qu'il ne le
  /// soit : l'écran y montre le sceau complet. Registre de décisions (QA
  /// appareil, round 3) : dès que l'état global change, le routeur réévalue
  /// la route de base de la pile (`/auth`, `/register`) et emporte l'écran
  /// téléphone poussé par-dessus ; toute mise en scène placée après
  /// l'adoption était coupée. Son échec n'empêche jamais l'adoption.
  Future<AuthEntryAdoption> adoptSessionForIntent(
    AppRole? intent, {
    Future<void> Function(AuthState opening)? beforeOpening,
  }) async {
    if (intent == null) {
      await adoptCurrentFirebaseSession(beforeOpening: beforeOpening);
      return const AuthEntryAdopted();
    }

    state = state.copyWith(isLoading: true, error: null);
    final AuthSessionResolution resolution;
    try {
      resolution = await _resolveCurrentSession().timeout(
        const Duration(seconds: 8),
      );
    } catch (error) {
      // Le rôle est inconnu : rien n'est adopté, l'intention reste entière.
      state = state.copyWith(isLoading: false, error: null);
      return AuthEntryUnresolved(_safeErrorCode(error));
    }

    final AppRole? accountRole;
    if (resolution.kind == AuthSessionResolutionKind.retryableProfileFailure) {
      // Seul le dernier profil valide de cette même identité peut dire son
      // rôle ; sans lui, on ne devine pas.
      final cached = await _readCachedUser(expectedUid: resolution.firebaseUid);
      if (cached == null) {
        state = state.copyWith(isLoading: false, error: null);
        return AuthEntryUnresolved(
          resolution.errorCode ?? 'profile-resolution-failed',
        );
      }
      accountRole = cached.role;
    } else {
      accountRole = resolution.user?.role;
    }

    if (matchAuthEntry(intent: intent, accountRole: accountRole) ==
        AuthEntryMatch.conflict) {
      await signOut();
      return AuthEntryRoleConflict(intent: intent, accountRole: accountRole!);
    }

    final opening = await _stateFor(resolution);
    await _beforeOpening(beforeOpening, opening);
    await _applyResolution(resolution, resolved: opening);
    return const AuthEntryAdopted();
  }

  static Future<void> _beforeOpening(
    Future<void> Function(AuthState opening)? hook,
    AuthState opening,
  ) async {
    if (hook == null) return;
    try {
      await hook(opening);
    } catch (_) {
      // L'ouverture de l'espace ne dépend pas de sa mise en scène.
    }
  }

  /// Adopts a Firebase session created by phone verification without ever
  /// creating or replacing the user's Firestore identity.
  ///
  /// Returns false when the phone credential is valid but registration has
  /// not created a profile yet.
  Future<bool> adoptCurrentFirebaseSession({
    Future<void> Function(AuthState opening)? beforeOpening,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resolution = await _resolveCurrentSession().timeout(
        const Duration(seconds: 8),
      );
      final opening = await _stateFor(resolution);
      await _beforeOpening(beforeOpening, opening);
      await _applyResolution(resolution, resolved: opening);
      return state.isAuthenticated;
    } catch (error) {
      await _applyRetryableFailure(errorCode: _safeErrorCode(error));
      return state.isAuthenticated;
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
      await _markAuthenticatedBefore();
      state = AuthState.authenticated(
        role: user.role,
        userId: user.uid,
        email: user.email,
        firstName: user.firstName,
        profileCompleted: user.profileCompleted,
        isSuperAdmin: user.isSuperAdmin,
        establishmentId: user.establishmentId,
      );
      await _cacheValidUser(user);
    } on AuthError catch (e) {
      if (_isProfileResolutionError(e.code)) {
        await _resolveAfterEstablishedCredential();
      } else {
        state = AuthState.unauthenticated(error: e.message);
      }
    } catch (error) {
      await _resolveAfterEstablishedCredential(
        fallbackErrorCode: _safeErrorCode(error),
      );
    }
  }

  /// Envoi de l'email de réinitialisation
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } on AuthError catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Le service est momentanément indisponible. Réessaie.',
      );
      return false;
    }
  }

  /// Déconnexion propre
  Future<void> signOut() async {
    if (state.hasFirebaseSession) {
      await _markAuthenticatedBefore();
    }
    try {
      await _repo.signOut();
    } catch (_) {
      // On déconnecte localement même si Firebase échoue
    }
    await ref.read(tutorPreferenceProvider.notifier).clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastValidSessionKey);
    // La purge de l'état élève n'est volontairement pas déclenchée ici : un
    // provider ne peut pas invalider ceux qui dépendent de lui, et le
    // contrôleur d'authentification n'a pas à connaître les providers de
    // fonctionnalités. La frontière est tenue par `learnerSessionBoundaryProvider`,
    // qui observe l'identité depuis l'extérieur de ce graphe et couvre donc
    // toutes les transitions, pas seulement ce bouton.
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
    unawaited(_markAuthenticatedBefore());
    state = AuthState.authenticated(
      role: role,
      userId: userId,
      email: email,
      firstName: firstName,
      profileCompleted: true,
    );
    unawaited(
      _cacheValidUser(
        AuthUserData(
          uid: userId,
          email: email,
          role: role,
          firstName: firstName,
          lastName: '',
          profileCompleted: true,
        ),
      ),
    );
  }

  /// Efface l'erreur courante
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  void updateProfileName(String firstName) {
    if (!state.isAuthenticated) return;
    final cleaned = firstName.trim();
    if (cleaned.isEmpty) return;
    state = state.copyWith(firstName: cleaned, error: null);
  }

  Future<void> _markOnboardingSeen() async {
    if (ref.read(hasSeenOnboardingProvider)) {
      return;
    }

    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    await OnboardingPreferences().setSeenOnboarding(true);
  }

  Future<void> _markAuthenticatedBefore() async {
    if (!ref.read(hasAuthenticatedBeforeProvider)) {
      ref.read(hasAuthenticatedBeforeProvider.notifier).state = true;
    }
    try {
      await AuthEntryPreferences().markAuthenticated();
    } catch (_) {
      // L'etat courant reste correct meme si le stockage local est indisponible.
    }
  }

  Future<void> retryProfileResolution() async {
    if (!state.hasFirebaseSession) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resolution = await _resolveCurrentSession().timeout(
        const Duration(seconds: 8),
      );
      await _applyResolution(resolution);
    } catch (error) {
      await _applyRetryableFailure(errorCode: _safeErrorCode(error));
    }
  }

  Future<void> _resolveAfterEstablishedCredential({
    String? fallbackErrorCode,
  }) async {
    try {
      final resolution = await _resolveCurrentSession().timeout(
        const Duration(seconds: 8),
      );
      await _applyResolution(resolution);
    } catch (error) {
      await _applyRetryableFailure(
        errorCode: fallbackErrorCode ?? _safeErrorCode(error),
      );
    }
  }

  /// État que [resolution] donnera une fois appliquée, sans rien appliquer.
  Future<AuthState> _stateFor(AuthSessionResolution resolution) async {
    final user = resolution.user;
    return switch (resolution.kind) {
      AuthSessionResolutionKind.unauthenticated => AuthState.unauthenticated(
        error: resolution.errorCode == 'user-disabled'
            ? 'Ce compte est désactivé. Contacte l’assistance Intellia 237.'
            : null,
      ),
      AuthSessionResolutionKind.needsOnboarding => AuthState.needsOnboarding(
        userId: resolution.firebaseUid ?? user?.uid ?? '',
        email: resolution.firebaseEmail ?? user?.email,
        firstName: user?.firstName,
        recoveredRole: user?.role,
      ),
      AuthSessionResolutionKind.authenticated when user != null =>
        AuthState.authenticated(
          role: user.role,
          userId: user.uid,
          email: user.email,
          firstName: user.firstName,
          profileCompleted: user.profileCompleted,
          isSuperAdmin: user.isSuperAdmin,
          establishmentId: user.establishmentId,
        ),
      AuthSessionResolutionKind.authenticated => await _retryableState(
        errorCode: 'profile-empty',
      ),
      AuthSessionResolutionKind.retryableProfileFailure =>
        await _retryableState(
          userId: resolution.firebaseUid,
          email: resolution.firebaseEmail,
          errorCode: resolution.errorCode,
        ),
      AuthSessionResolutionKind.legacyProfileRecovery =>
        AuthState.legacyProfileRecovery(
          userId: resolution.firebaseUid ?? user?.uid ?? '',
          email: resolution.firebaseEmail ?? user?.email,
          firstName: user?.firstName,
          recoveredRole: user?.role,
          profileCompleted: user?.profileCompleted ?? false,
          isSuperAdmin: user?.isSuperAdmin ?? false,
          establishmentId: user?.establishmentId,
          error: user == null
              ? 'Le profil utilise un rôle historique non reconnu.'
              : null,
        ),
    };
  }

  /// Applique [resolution] : préférences locales, état global, cache du
  /// dernier profil valide. [resolved] est l'état déjà calculé par
  /// [_stateFor] pour cette même résolution.
  Future<void> _applyResolution(
    AuthSessionResolution resolution, {
    AuthState? resolved,
  }) async {
    final user = resolution.user;
    final next = resolved ?? await _stateFor(resolution);
    switch (resolution.kind) {
      case AuthSessionResolutionKind.unauthenticated:
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_lastValidSessionKey);
      case AuthSessionResolutionKind.needsOnboarding ||
          AuthSessionResolutionKind.legacyProfileRecovery:
        await _markOnboardingSeen();
        await _markAuthenticatedBefore();
      case AuthSessionResolutionKind.authenticated when user != null:
        await _markOnboardingSeen();
        await _markAuthenticatedBefore();
      case AuthSessionResolutionKind.authenticated ||
          AuthSessionResolutionKind.retryableProfileFailure:
        break;
    }
    state = next;
    final cacheable = switch (resolution.kind) {
      AuthSessionResolutionKind.authenticated => user != null,
      AuthSessionResolutionKind.legacyProfileRecovery =>
        user != null && user.profileCompleted,
      _ => false,
    };
    if (cacheable) await _cacheValidUser(user!);
  }

  Future<AuthSessionResolution> _resolveCurrentSession() async {
    final repository = _repo;
    if (repository is AuthSessionResolver) {
      return (repository as AuthSessionResolver).resolveCurrentSession();
    }
    final user = await repository.getCurrentUser();
    return AuthSessionResolution(
      kind: user == null
          ? AuthSessionResolutionKind.unauthenticated
          : user.profileCompleted
          ? AuthSessionResolutionKind.authenticated
          : AuthSessionResolutionKind.needsOnboarding,
      firebaseUid: user?.uid,
      firebaseEmail: user?.email,
      user: user,
    );
  }

  Future<void> _applyRetryableFailure({
    String? userId,
    String? email,
    String? errorCode,
  }) async {
    state = await _retryableState(
      userId: userId,
      email: email,
      errorCode: errorCode,
    );
  }

  Future<AuthState> _retryableState({
    String? userId,
    String? email,
    String? errorCode,
  }) async {
    final cached = await _readCachedUser(expectedUid: userId);
    return AuthState.retryableProfileFailure(
      userId: userId ?? cached?.uid,
      email: email ?? cached?.email,
      firstName: cached?.firstName,
      cachedRole: cached?.role,
      cachedProfileCompleted: cached?.profileCompleted ?? false,
      isSuperAdmin: cached?.isSuperAdmin ?? false,
      establishmentId: cached?.establishmentId,
      error: 'Le profil ne peut pas être synchronisé pour le moment.',
    );
  }

  Future<void> _cacheValidUser(AuthUserData user) async {
    if (!user.profileCompleted) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _lastValidSessionKey,
      jsonEncode(<String, Object>{
        'uid': user.uid,
        'email': user.email,
        'role': user.role.name,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'profileCompleted': true,
        'isSuperAdmin': user.isSuperAdmin,
        if (user.establishmentId != null)
          'establishmentId': user.establishmentId!,
      }),
    );
  }

  Future<AuthUserData?> _readCachedUser({String? expectedUid}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_lastValidSessionKey);
      if (raw == null) return null;
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final uid = data['uid'] as String? ?? '';
      if (uid.isEmpty || (expectedUid != null && expectedUid != uid)) {
        return null;
      }
      final roleName = data['role'] as String?;
      final role = AppRole.values.where((item) => item.name == roleName);
      if (role.isEmpty) return null;
      return AuthUserData(
        uid: uid,
        email: data['email'] as String? ?? '',
        role: role.first,
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        profileCompleted: data['profileCompleted'] == true,
        isSuperAdmin:
            role.first == AppRole.admin && data['isSuperAdmin'] == true,
        establishmentId: data['establishmentId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isProfileResolutionError(String? code) =>
      code == 'user-profile-not-found' || code == 'user-role-invalid';

  String _safeErrorCode(Object error) => switch (error) {
    TimeoutException _ => 'timeout',
    AuthError authError => authError.code ?? 'auth-profile-error',
    _ => 'profile-resolution-failed',
  };
}
