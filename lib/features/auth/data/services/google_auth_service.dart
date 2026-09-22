import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_role.dart';
import '../../domain/auth_linking_state.dart';

/// Result outcome of a Google Sign-In attempt.
sealed class GoogleAuthResult {
  const GoogleAuthResult();
}

/// User successfully authenticated with Google and has an existing complete Intellia profile.
class GoogleAuthSuccess extends GoogleAuthResult {
  const GoogleAuthSuccess({
    required this.uid,
    required this.roles,
    required this.profileCompleted,
  });

  final String uid;
  final List<AppRole> roles;
  final bool profileCompleted;
}

/// Google authentication succeeded, but this identity does NOT yet have an Intellia profile.
/// Enters neutral onboarding / discovery gateway.
class GoogleAuthNewUser extends GoogleAuthResult {
  const GoogleAuthNewUser({this.user, this.email, this.displayName});

  final User? user;
  final String? email;
  final String? displayName;
}

/// Google authentication was cancelled by the user.
class GoogleAuthCancelled extends GoogleAuthResult {
  const GoogleAuthCancelled();
}

/// Collision: account already exists with a different credential or provider in use.
class GoogleAuthCollision extends GoogleAuthResult {
  const GoogleAuthCollision({
    required this.code,
    required this.message,
    this.email,
  });

  final String code;
  final String message;
  final String? email;
}

/// An error occurred during Google authentication.
class GoogleAuthFailure extends GoogleAuthResult {
  const GoogleAuthFailure({required this.code, required this.message});

  final String code;
  final String message;
}

/// Abstract contract for Google authentication, allowing 100% testability.
abstract interface class GoogleAuthGateway {
  Future<GoogleAuthResult> signIn();
  Future<AccountLinkingState> linkGoogleCredential(
    User currentUser,
    AuthCredential credential,
  );
  Future<void> signOut();
}

/// Production implementation of GoogleAuthGateway using FirebaseAuth.
class FirebaseGoogleAuthGateway implements GoogleAuthGateway {
  FirebaseGoogleAuthGateway({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<GoogleAuthResult> signIn() async {
    try {
      final googleProvider = GoogleAuthProvider();
      // Add standard scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        credential = await _auth.signInWithProvider(googleProvider);
      }

      final user = credential.user;
      if (user == null) {
        return const GoogleAuthFailure(
          code: 'missing-user',
          message: 'Impossible de récupérer le profil Google.',
        );
      }

      // Check whether user document exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return GoogleAuthNewUser(
          user: user,
          email: user.email,
          displayName: user.displayName,
        );
      }

      final data = userDoc.data()!;
      final roleString = (data['role'] as String? ?? '').trim();
      final roles = parseStoredAppRoles(data['roles'], roleString);
      final profileCompleted = data['profileCompleted'] as bool? ?? false;

      return GoogleAuthSuccess(
        uid: user.uid,
        roles: roles,
        profileCompleted: profileCompleted,
      );
    } on FirebaseAuthException catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Google Auth Error: ${e.code} - ${e.message}',
          stackTrace: stack,
        );
      }
      if (e.code == 'popup_closed_by_user' ||
          e.code == 'canceled' ||
          e.code == 'cancelled') {
        return const GoogleAuthCancelled();
      }
      if (e.code == 'account-exists-with-different-credential' ||
          e.code == 'credential-already-in-use') {
        return GoogleAuthCollision(
          code: e.code,
          message:
              'Ce compte Google est déjà associé à un autre mode de connexion.',
          email: e.email,
        );
      }
      return GoogleAuthFailure(
        code: e.code,
        message: _friendlyErrorMessage(e.code),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Google Auth Unexpected Error: $e', stackTrace: stack);
      }
      return GoogleAuthFailure(
        code: 'unknown',
        message:
            'Une erreur imprévue est survenue lors de la connexion Google.',
      );
    }
  }

  @override
  Future<AccountLinkingState> linkGoogleCredential(
    User currentUser,
    AuthCredential credential,
  ) async {
    try {
      final userCredential = await currentUser.linkWithCredential(credential);
      final uid = userCredential.user?.uid ?? currentUser.uid;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      final roleString = (data['role'] as String? ?? '').trim();
      final roles = parseStoredAppRoles(data['roles'], roleString);

      return LinkingSuccessState(linkedUid: uid, roles: roles);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked') {
        return ProviderAlreadyInUseState(
          message:
              'Ce compte Google est déjà associé à un autre profil INTELLIA.',
          conflictingEmail: e.email,
        );
      }
      return LinkingFailedState(
        errorCode: e.code,
        message: _friendlyErrorMessage(e.code),
      );
    } catch (e) {
      return LinkingFailedState(
        errorCode: 'unknown',
        message: 'Impossible de lier ce compte Google pour le moment.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _friendlyErrorMessage(String code) {
    return switch (code) {
      'network-request-failed' =>
        'Connexion Internet instable. Vérifiez votre réseau.',
      'user-disabled' =>
        'Ce compte a été désactivé. Contactez l’assistance Intellia 237.',
      'operation-not-allowed' =>
        'La connexion Google n’est pas activée sur ce serveur.',
      _ => 'La connexion Google n’a pas pu aboutir. Veuillez réessayer.',
    };
  }
}

/// Provider for GoogleAuthGateway.
final googleAuthGatewayProvider = Provider<GoogleAuthGateway>((ref) {
  return FirebaseGoogleAuthGateway();
});
