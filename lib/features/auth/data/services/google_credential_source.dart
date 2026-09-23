import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/google_access.dart';

/// Acquiert une preuve Google SANS ouvrir de session Firebase.
abstract interface class GoogleCredentialSource {
  Future<GoogleCredentialResult> acquire();

  /// Oublie le compte Google choisi sur cet appareil : le prochain
  /// « Continuer avec Google » repropose le sélecteur de comptes.
  Future<void> signOut();
}

/// Sélecteur de comptes natif (Android : Credential Manager) via
/// `google_sign_in` 7.
///
/// Configuration requise (voir docs/auth/OWNER_GOOGLE_SETUP_CHECKLIST.md) :
/// un client OAuth « Web » du projet Firebase, fourni soit par
/// `google-services.json` (`oauth_client` de type 3), soit par
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=…`. Sans lui, Android renvoie une
/// erreur de configuration — parfois présentée comme une annulation.
class NativeGoogleCredentialSource implements GoogleCredentialSource {
  NativeGoogleCredentialSource({GoogleSignIn? signIn, String? serverClientId})
    : _signIn = signIn ?? GoogleSignIn.instance,
      _serverClientId =
          serverClientId ??
          const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final GoogleSignIn _signIn;
  final String _serverClientId;
  Future<void>? _initialization;

  /// `initialize` n'est appelé qu'une fois ; un échec permet de réessayer.
  Future<void> _ensureInitialized() => _initialization ??= _signIn
      .initialize(
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      )
      .catchError((Object error) {
        _initialization = null;
        throw error;
      });

  @override
  Future<GoogleCredentialResult> acquire() async {
    if (kIsWeb) {
      // Le web exige le bouton rendu par Google Identity Services ; cette
      // version ne cible que les applications natives.
      return const GoogleCredentialFailed('google-unsupported-platform');
    }
    try {
      await _ensureInitialized();
      if (!_signIn.supportsAuthenticate()) {
        return const GoogleCredentialFailed('google-unsupported-platform');
      }
      final account = await _signIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const GoogleCredentialFailed('google-missing-token');
      }
      return GoogleCredentialAcquired(
        GoogleProof(
          idToken: idToken,
          email: account.email,
          displayName: account.displayName,
        ),
      );
    } on GoogleSignInException catch (error) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted =>
          const GoogleCredentialCancelled(),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          const GoogleCredentialFailed('google-not-configured'),
        GoogleSignInExceptionCode.uiUnavailable => const GoogleCredentialFailed(
          'google-ui-unavailable',
        ),
        GoogleSignInExceptionCode.userMismatch ||
        GoogleSignInExceptionCode.unknownError => const GoogleCredentialFailed(
          'google-sign-in-failed',
        ),
      };
    } catch (_) {
      return const GoogleCredentialFailed('google-sign-in-failed');
    }
  }

  @override
  Future<void> signOut() async {
    if (kIsWeb || _initialization == null) return;
    try {
      await _ensureInitialized();
      await _signIn.signOut();
    } catch (_) {
      // Rien à oublier : la session INTELLIA237 est déjà fermée.
    }
  }
}
