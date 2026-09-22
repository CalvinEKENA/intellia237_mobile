import 'package:firebase_auth/firebase_auth.dart';

import 'app_role.dart';

/// Explicit typed domain states for account linking flows.
///
/// Designed to prevent accidental duplicate identities and enforce proof-of-control
/// before attaching a Google credential to an existing Intellia account.
sealed class AccountLinkingState {
  const AccountLinkingState();
}

/// Google authentication succeeded, but no Intellia profile exists yet.
class GoogleNewState extends AccountLinkingState {
  const GoogleNewState({
    required this.googleUser,
    this.suggestedEmail,
    this.suggestedDisplayName,
  });

  final User googleUser;
  final String? suggestedEmail;
  final String? suggestedDisplayName;
}

/// Google account is already linked to an existing complete Intellia profile.
class GoogleAlreadyLinkedState extends AccountLinkingState {
  const GoogleAlreadyLinkedState({required this.uid, required this.roles});

  final String uid;
  final List<AppRole> roles;
}

/// User wants to link Google to an existing phone-based account.
/// Awaiting phone OTP verification to prove ownership.
class ExistingPhoneAccountState extends AccountLinkingState {
  const ExistingPhoneAccountState({
    required this.googleCredential,
    this.pendingPhoneNumber,
  });

  final AuthCredential googleCredential;
  final String? pendingPhoneNumber;
}

/// User wants to link Google to an existing staff/admin email account.
/// Awaiting password verification to prove ownership.
class ExistingEmailAccountState extends AccountLinkingState {
  const ExistingEmailAccountState({
    required this.googleCredential,
    required this.email,
  });

  final AuthCredential googleCredential;
  final String email;
}

/// Both identities verified; ready to execute provider linking.
class LinkingRequiredState extends AccountLinkingState {
  const LinkingRequiredState({
    required this.targetUid,
    required this.googleCredential,
  });

  final String targetUid;
  final AuthCredential googleCredential;
}

/// Linking succeeded: Google credential is now linked to targetUid.
class LinkingSuccessState extends AccountLinkingState {
  const LinkingSuccessState({required this.linkedUid, required this.roles});

  final String linkedUid;
  final List<AppRole> roles;
}

/// Collision detected: Google credential is already linked to another account.
class ProviderAlreadyInUseState extends AccountLinkingState {
  const ProviderAlreadyInUseState({
    required this.message,
    this.conflictingEmail,
  });

  final String message;
  final String? conflictingEmail;
}

/// Linking was cancelled by the user.
class LinkingCancelledState extends AccountLinkingState {
  const LinkingCancelledState();
}

/// Linking failed with an error.
class LinkingFailedState extends AccountLinkingState {
  const LinkingFailedState({required this.errorCode, required this.message});

  final String errorCode;
  final String message;
}
