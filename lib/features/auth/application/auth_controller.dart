import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../family_access/application/family_access_providers.dart';
import '../../family_access/data/family_access_repository.dart';
import '../../family_access/domain/family_access_models.dart';
import '../../family_access/domain/family_access_outcomes.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../data/auth_entry_preferences.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/app_role.dart';
import '../domain/auth_entry_intent.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'google_access_coordinator.dart';

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
  static const _lastSelectedSpacePrefix = 'auth_last_selected_space_v1_';

  /// UID élève d'une session vérifiée sous l'entrée parent, en attente de la
  /// décision du parent. Un redémarrage pendant cette attente referme la
  /// session au lieu d'ouvrir l'espace de l'élève.
  static const _pendingFamilyPhoneOfferKey = 'auth_family_phone_offer_uid_v1';

  /// Migration confirmée que le serveur n'a pas pu achever : le numéro, resté
  /// libre, doit être vérifié à nouveau pour terminer l'espace parent.
  static const _familyPhoneResumeKey = 'auth_family_phone_resume_v1';

  /// Identité sans profil qui a choisi la découverte (par UID).
  static const _discoveryPrefix = 'auth_discovery_uid_v1_';
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  FamilyAccessRepository get _familyAccess =>
      ref.read(familyAccessRepositoryProvider);

  /// Commandes d'entrée en cours (connexion, adoption). Tant qu'il y en a,
  /// l'écoute de l'identité Firebase laisse la commande conclure : c'est elle
  /// qui montre le sceau et tranche les conflits avant d'ouvrir un espace.
  int _entryDepth = 0;

  @override
  AuthState build() {
    final subscription = ref
        .read(firebaseIdentityPortProvider)
        .uidChanges()
        .listen(_onIdentityChanged, onError: (Object _) {});
    ref.onDispose(subscription.cancel);
    return const AuthState.bootstrapping();
  }

  /// Résolveur unique, à l'écoute de Firebase Auth.
  ///
  /// Registre de décisions (refonte Auth V2, P0-1 de la revue de 7ea5cf0) :
  /// aucune écoute de `authStateChanges` n'existait. Une session ouverte hors
  /// d'une commande d'entrée restait invisible, et les écrans appelaient
  /// `completeBootstrap`, qui ne fait rien après le démarrage. Désormais :
  /// - identité perdue (déconnexion ailleurs, compte supprimé, jeton révoqué)
  ///   → l'état redevient « non authentifié » ;
  /// - identité remplacée sous une session ouverte, hors commande d'entrée →
  ///   la nouvelle identité est résolue.
  /// Une nouvelle connexion est adoptée par la commande qui l'a ouverte
  /// (sceau, conflits d'espace) ; jamais implicitement pendant le parcours.
  void _onIdentityChanged(String? uid) {
    if (_entryDepth > 0) return;
    final current = state;
    if (current.status == AuthStatus.bootstrapping) return;
    if (uid == null) {
      if (current.hasFirebaseSession) unawaited(_applySessionLoss());
      return;
    }
    if (current.hasFirebaseSession &&
        current.userId != null &&
        current.userId != uid) {
      unawaited(_resolveAfterEstablishedCredential());
    }
  }

  Future<void> _applySessionLoss() async {
    await _clearLocalSession();
    state = const AuthState.unauthenticated();
  }

  /// Exécute une commande d'entrée sans que l'écoute de l'identité ne la
  /// devance. Les écrans qui ouvrent eux-mêmes une session Firebase (code SMS,
  /// récupération d'un compte existant) s'en servent aussi.
  Future<T> holdSessionAdoption<T>(Future<T> Function() command) async {
    _entryDepth++;
    try {
      return await command();
    } finally {
      _entryDepth--;
    }
  }

  /// Vérifie la session Firebase existante au démarrage
  Future<void> completeBootstrap() async {
    if (state.status != AuthStatus.bootstrapping) return;

    try {
      final resolution = await _resolveCurrentSession().timeout(
        const Duration(seconds: 8),
      );
      if (await _isPendingFamilyPhoneOffer(resolution.firebaseUid)) {
        await signOut();
        return;
      }
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
  }) => holdSessionAdoption(
    () => _signInWithEmail(
      email: email,
      password: password,
      intent: intent,
      beforeOpening: beforeOpening,
    ),
  );

  Future<AuthEntryAdoption> _signInWithEmail({
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
      state = await _resolveAuthenticatedState(user);
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
  ///
  /// [confirmSharedStudentPhone] : sous l'accès neutre par téléphone, un
  /// numéro qui ouvre l'espace d'un élève n'est pas adopté tout de suite ; la
  /// personne confirme d'abord qui elle est (voir
  /// [AuthEntryStudentPhoneConfirmation]).
  Future<AuthEntryAdoption> adoptSessionForIntent(
    AppRole? intent, {
    Future<void> Function(AuthState opening)? beforeOpening,
    bool confirmSharedStudentPhone = false,
  }) => holdSessionAdoption(
    () => _adoptSessionForIntent(
      intent,
      beforeOpening: beforeOpening,
      confirmSharedStudentPhone: confirmSharedStudentPhone,
    ),
  );

  Future<AuthEntryAdoption> _adoptSessionForIntent(
    AppRole? intent, {
    Future<void> Function(AuthState opening)? beforeOpening,
    bool confirmSharedStudentPhone = false,
  }) async {
    if (intent == null && confirmSharedStudentPhone) {
      return _adoptNeutralPhoneSession(beforeOpening: beforeOpening);
    }
    if (intent == null) {
      await _adoptCurrentFirebaseSession(beforeOpening: beforeOpening);
      return const AuthEntryAdopted();
    }
    if (intent == AppRole.student) await _forgetFamilyPhoneOffer();

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
      // Le téléphone de la famille ouvre l'accès de l'élève : le parent peut
      // le reprendre. Seul un profil lu à l'instant le permet, jamais un rôle
      // tiré du cache.
      if (intent == AppRole.parent &&
          accountRole == AppRole.student &&
          resolution.user != null) {
        state = state.copyWith(isLoading: false, error: null);
        await _rememberFamilyPhoneOffer(
          resolution.firebaseUid ?? resolution.user!.uid,
        );
        return AuthEntryFamilyPhoneInUse(
          studentFirstName: resolution.user!.firstName,
        );
      }
      await signOut();
      return AuthEntryRoleConflict(intent: intent, accountRole: accountRole!);
    }

    final opening = await _stateFor(resolution);
    await _beforeOpening(beforeOpening, opening);
    await _applyResolution(resolution, resolved: opening);
    return const AuthEntryAdopted();
  }

  Future<AuthEntryAdoption> _adoptNeutralPhoneSession({
    Future<void> Function(AuthState opening)? beforeOpening,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final AuthSessionResolution resolution;
    try {
      resolution = await _resolveCurrentSession().timeout(
        const Duration(seconds: 8),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: null);
      return AuthEntryUnresolved(_safeErrorCode(error));
    }
    final user = resolution.user;
    if (resolution.kind == AuthSessionResolutionKind.authenticated &&
        user != null &&
        user.role == AppRole.student &&
        user.resolvedRoles.length == 1) {
      state = state.copyWith(isLoading: false, error: null);
      // Un redémarrage avant la réponse referme la session, sans ouvrir
      // l'espace de l'élève.
      await _rememberFamilyPhoneOffer(resolution.firebaseUid ?? user.uid);
      return AuthEntryStudentPhoneConfirmation(
        studentFirstName: user.firstName,
      );
    }
    final opening = await _stateFor(resolution);
    await _beforeOpening(beforeOpening, opening);
    await _applyResolution(resolution, resolved: opening);
    return const AuthEntryAdopted();
  }

  /// Cède le numéro vérifié — session élève ouverte mais non adoptée — au
  /// compte parent, après la confirmation explicite de l'écran.
  ///
  /// L'état global ne change pas ici : le code d'accès de l'élève doit être
  /// montré avant que la session du parent ne s'ouvre et que le routeur ne
  /// réagisse.
  Future<FamilyPhoneMigrationOutcome> migrateFamilyPhoneToParent() async {
    try {
      final result = await _familyAccess.migrateStudentPhoneToParent();
      await _setFamilyPhoneResume(false);
      return FamilyPhoneMigrated(result);
    } on FamilyAccessException catch (error) {
      final failed = FamilyPhoneMigrationFailed.from(error);
      if (failed.failure == FamilyPhoneMigrationFailure.verifyAgainToFinish) {
        await _setFamilyPhoneResume(true);
      }
      return failed;
    } catch (_) {
      return const FamilyPhoneMigrationFailed(
        FamilyPhoneMigrationFailure.unavailable,
      );
    }
  }

  /// Termine, après une nouvelle vérification du numéro, une migration que
  /// le parent a déjà confirmée et que le serveur n'a pas pu achever.
  ///
  /// Ce n'est jamais une nouvelle migration silencieuse : sans migration
  /// confirmée en attente sur cet appareil, rien n'est appelé ; et le serveur
  /// n'adopte l'identité fraîche que si son journal attend précisément cette
  /// reprise pour ce numéro.
  Future<bool> resumeConfirmedFamilyPhoneMigration() async {
    if (!await _isFamilyPhoneResumePending()) return false;
    return await migrateFamilyPhoneToParent() is FamilyPhoneMigrated;
  }

  /// Ouvre la session du parent issue de la migration, sous l'entrée parent.
  Future<AuthEntryAdoption> openParentAfterFamilyPhoneMigration(
    FamilyPhoneMigrationResult result, {
    Future<void> Function(AuthState opening)? beforeOpening,
  }) => holdSessionAdoption(
    () => _openParentAfterFamilyPhoneMigration(
      result,
      beforeOpening: beforeOpening,
    ),
  );

  Future<AuthEntryAdoption> _openParentAfterFamilyPhoneMigration(
    FamilyPhoneMigrationResult result, {
    Future<void> Function(AuthState opening)? beforeOpening,
  }) async {
    final token = result.parentToken;
    if (token != null) {
      try {
        await _familyAccess.signInWithCustomToken(token);
      } catch (error) {
        return AuthEntryUnresolved(
          error is FamilyAccessException ? error.code : 'custom-token-failed',
        );
      }
    }
    // La session est désormais celle du parent : plus rien à refermer.
    await _forgetFamilyPhoneOffer();
    return adoptSessionForIntent(AppRole.parent, beforeOpening: beforeOpening);
  }

  /// Connexion d'un élève par son code d'accès INTELLIA, sans SMS : le
  /// serveur renvoie une session du **même** UID élève que son téléphone.
  Future<StudentAccessCodeSignIn> signInWithStudentAccessCode(
    String code, {
    Future<void> Function(AuthState opening)? beforeOpening,
  }) => holdSessionAdoption(
    () => _signInWithStudentAccessCode(code, beforeOpening: beforeOpening),
  );

  Future<StudentAccessCodeSignIn> _signInWithStudentAccessCode(
    String code, {
    Future<void> Function(AuthState opening)? beforeOpening,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _familyAccess.signInWithStudentAccessCode(code);
    } on FamilyAccessException catch (error) {
      state = state.copyWith(isLoading: false, error: null);
      return StudentAccessCodeRejected.from(error);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: null);
      return const StudentAccessCodeRejected(
        StudentAccessCodeRejection.unavailable,
      );
    }
    final adoption = await adoptSessionForIntent(
      AppRole.student,
      beforeOpening: beforeOpening,
    );
    return switch (adoption) {
      AuthEntryAdopted() => const StudentAccessCodeAdopted(),
      AuthEntryUnresolved(:final errorCode) => StudentAccessCodeUnresolved(
        errorCode,
      ),
      // Un code d'accès n'appartient qu'à un élève : tout autre rôle est
      // une incohérence serveur, jamais un espace à ouvrir.
      AuthEntryRoleConflict() ||
      AuthEntryFamilyPhoneInUse() ||
      AuthEntryStudentPhoneConfirmation() => const StudentAccessCodeRejected(
        StudentAccessCodeRejection.invalid,
      ),
    };
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
  }) => holdSessionAdoption(
    () => _adoptCurrentFirebaseSession(beforeOpening: beforeOpening),
  );

  /// Ouvre la session Google que le coordinateur vient d'établir.
  ///
  /// [isNewIdentity] : la personne a répondu « Non, continuer » ; sans profil,
  /// elle entre dans la découverte, et y revient après un redémarrage.
  Future<bool> openGoogleSession({
    required bool isNewIdentity,
    Future<void> Function(AuthState opening)? beforeOpening,
  }) => holdSessionAdoption(() async {
    if (isNewIdentity) {
      final uid = ref.read(firebaseIdentityPortProvider).currentUid;
      if (uid != null) await _setDiscoveryChosen(uid, true);
    }
    return _adoptCurrentFirebaseSession(beforeOpening: beforeOpening);
  });

  Future<bool> _adoptCurrentFirebaseSession({
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
      state = await _resolveAuthenticatedState(user);
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
    // Le compte Google choisi est oublié : sur un appareil partagé, la
    // personne suivante retrouve le sélecteur de comptes.
    try {
      await ref.read(googleAccessCoordinatorProvider).abandon();
    } catch (_) {}
    await _clearLocalSession();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingFamilyPhoneOfferKey);
    // La purge de l'état élève n'est volontairement pas déclenchée ici : un
    // provider ne peut pas invalider ceux qui dépendent de lui, et le
    // contrôleur d'authentification n'a pas à connaître les providers de
    // fonctionnalités. La frontière est tenue par `learnerSessionBoundaryProvider`,
    // qui observe l'identité depuis l'extérieur de ce graphe et couvre donc
    // toutes les transitions, pas seulement ce bouton.
    state = const AuthState.unauthenticated();
  }

  Future<void> _clearLocalSession() async {
    try {
      await ref.read(tutorPreferenceProvider.notifier).clear();
    } catch (_) {}
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_lastValidSessionKey);
    } catch (_) {}
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
        error: resolution.errorCode == 'user-disabled' ? 'user-disabled' : null,
        suspended: resolution.errorCode == 'user-disabled',
      ),
      AuthSessionResolutionKind.needsOnboarding
          when user == null && await _isDiscoveryIdentity(resolution) =>
        AuthState.discovery(
          userId: resolution.firebaseUid!,
          email: resolution.firebaseEmail,
        ),
      AuthSessionResolutionKind.needsOnboarding => AuthState.needsOnboarding(
        userId: resolution.firebaseUid ?? user?.uid ?? '',
        email: resolution.firebaseEmail ?? user?.email,
        firstName: user?.firstName,
        recoveredRole: user?.role,
        accountStatus: user?.accountStatus,
      ),
      AuthSessionResolutionKind.authenticated when user != null =>
        await _resolveAuthenticatedState(user),
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

  /// Espace actif d'un profil complet.
  ///
  /// Un seul espace : il s'ouvre, sans sélecteur. Plusieurs espaces : le
  /// dernier espace valide retenu sur cet appareil s'ouvre ; sans lui (ou si
  /// le serveur l'a retiré), le sélecteur s'affiche une fois.
  Future<AuthState> _resolveAuthenticatedState(AuthUserData user) async {
    final roles = user.resolvedRoles;
    AppRole activeRole = user.role;
    var remembered = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedRoleName = preferences.getString(
        '$_lastSelectedSpacePrefix${user.uid}',
      );
      if (savedRoleName != null) {
        final matching = roles.where((r) => r.name == savedRoleName);
        if (matching.isNotEmpty) {
          activeRole = matching.first;
          remembered = true;
        }
      }
    } catch (_) {}

    return AuthState.authenticated(
      role: activeRole,
      availableRoles: roles,
      userId: user.uid,
      email: user.email,
      firstName: user.firstName,
      profileCompleted: user.profileCompleted,
      isSuperAdmin: user.isSuperAdmin,
      establishmentId: user.establishmentId,
      spaceChoicePending: roles.length > 1 && !remembered,
      accountStatus: user.accountStatus,
    );
  }

  /// Changes the user's active space without logging out.
  Future<void> selectActiveRole(AppRole role) async {
    final current = state;
    if (!current.isAuthenticated || current.userId == null) return;
    if (!current.availableRoles.contains(role)) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        '$_lastSelectedSpacePrefix${current.userId}',
        role.name,
      );
    } catch (_) {}

    state = current.copyWith(role: role, spaceChoicePending: false);
  }

  /// Découverte choisie par une identité prouvée sans profil. Aucune identité
  /// fictive : sans session, rien ne change. Le choix est retenu pour cet
  /// UID, pour que la découverte revienne après un redémarrage.
  Future<void> enterDiscoveryMode() async {
    final current = state;
    final uid = current.userId;
    if (uid == null ||
        (current.status != AuthStatus.needsOnboarding &&
            current.status != AuthStatus.discovery) ||
        current.role != null) {
      return;
    }
    await _setDiscoveryChosen(uid, true);
    state = AuthState.discovery(
      userId: uid,
      email: current.email,
      firstName: current.firstName,
    );
  }

  /// Quitter la découverte ferme la session : l'identité reste sans profil,
  /// et la porte d'entrée neutre s'affiche.
  Future<void> exitDiscoveryMode() => signOut();

  Future<bool> _isDiscoveryIdentity(AuthSessionResolution resolution) async {
    final uid = resolution.firebaseUid;
    if (uid == null || uid.isEmpty) return false;
    if (await _discoveryChosen(uid)) return true;
    // Identité Google seule, sans profil : la découverte, sur tout appareil.
    final providers = resolution.signInProviders;
    return providers.isNotEmpty &&
        providers.every((provider) => provider == 'google.com');
  }

  Future<bool> _discoveryChosen(String uid) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool('$_discoveryPrefix$uid') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setDiscoveryChosen(String uid, bool chosen) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (chosen) {
        await preferences.setBool('$_discoveryPrefix$uid', true);
      } else {
        await preferences.remove('$_discoveryPrefix$uid');
      }
    } catch (_) {}
  }

  Future<void> _rememberFamilyPhoneOffer(String uid) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_pendingFamilyPhoneOfferKey, uid);
    } catch (_) {
      // Sans stockage, l'écran referme encore la session à sa sortie.
    }
  }

  Future<void> _setFamilyPhoneResume(bool pending) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (pending) {
        await preferences.setBool(_familyPhoneResumeKey, true);
      } else {
        await preferences.remove(_familyPhoneResumeKey);
      }
    } catch (_) {}
  }

  Future<bool> _isFamilyPhoneResumePending() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_familyPhoneResumeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// La personne confirme être l'élève dont le numéro vient d'être vérifié.
  Future<AuthEntryAdoption> confirmStudentPhoneOwner({
    Future<void> Function(AuthState opening)? beforeOpening,
  }) => adoptSessionForIntent(AppRole.student, beforeOpening: beforeOpening);

  /// La personne dit être le parent de l'élève dont le numéro vient d'être
  /// vérifié : l'offre de reprise du téléphone familial s'ouvre.
  Future<AuthEntryAdoption> claimStudentPhoneAsParent() =>
      adoptSessionForIntent(AppRole.parent);

  Future<void> _forgetFamilyPhoneOffer() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_pendingFamilyPhoneOfferKey);
    } catch (_) {}
  }

  Future<bool> _isPendingFamilyPhoneOffer(String? uid) async {
    if (uid == null || uid.isEmpty) return false;
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(_pendingFamilyPhoneOfferKey) == uid;
    } catch (_) {
      return false;
    }
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
        'roles': user.resolvedRoles.map((r) => r.name).toList(),
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

      final rolesRaw = data['roles'] as List<dynamic>?;
      final roles = <AppRole>[];
      if (rolesRaw != null) {
        for (final r in rolesRaw) {
          final matched = AppRole.values.where((item) => item.name == r);
          if (matched.isNotEmpty) roles.add(matched.first);
        }
      }

      return AuthUserData(
        uid: uid,
        email: data['email'] as String? ?? '',
        role: role.first,
        roles: roles.isEmpty ? [role.first] : roles,
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
