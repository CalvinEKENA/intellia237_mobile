import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../../parent/application/pending_child_link.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../role_registration/data/firebase_role_registration_repository.dart';
import '../../role_registration/data/role_registration_repository.dart';
import '../../role_registration/domain/parent_registration_payload.dart';
import 'parent_registration_state.dart';

final parentRegistrationControllerProvider =
    NotifierProvider<ParentRegistrationController, ParentRegistrationState>(
      ParentRegistrationController.new,
    );

class ParentRegistrationController extends Notifier<ParentRegistrationState> {
  RoleRegistrationRepository get _repo =>
      ref.read(roleRegistrationRepositoryProvider);

  @override
  ParentRegistrationState build() => const ParentRegistrationState();

  void setFirstName(String value) {
    state = state.copyWith(firstName: value, clearError: true);
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value, clearError: true);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void setPhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value, clearError: true);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, clearError: true);
  }

  void addChildIdentifier(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.length < 4 || state.childIdentifiers.contains(normalized)) {
      return;
    }
    state = state.copyWith(
      childIdentifiers: [...state.childIdentifiers, normalized],
      clearError: true,
    );
  }

  void removeChildIdentifier(String value) {
    state = state.copyWith(
      childIdentifiers: state.childIdentifiers
          .where((item) => item != value)
          .toList(),
      clearError: true,
    );
  }

  void setAcceptedTerms(bool value) {
    state = state.copyWith(acceptedTerms: value, clearError: true);
  }

  void setAcceptedPrivacy(bool value) {
    state = state.copyWith(acceptedPrivacy: value, clearError: true);
  }

  void clearError() {
    if (state.errorMessage != null) state = state.copyWith(clearError: true);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  String? validateStep(int step) {
    return switch (step) {
      0 => _validateIdentity(),
      1 => _validateChildLinks(),
      2 => _validateFinal(),
      _ => null,
    };
  }

  Future<bool> submit() async {
    final validationError =
        _validateIdentity() ?? _validateChildLinks() ?? _validateFinal();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final result = await _repo.registerParent(
        ParentRegistrationPayload(
          firstName: state.firstName.trim(),
          lastName: state.lastName.trim(),
          email: state.email.trim(),
          phoneNumber: state.phoneNumber.trim().isEmpty
              ? null
              : state.phoneNumber.trim(),
          password: state.password,
          childIdentifiers: state.childIdentifiers,
          acceptedTerms: state.acceptedTerms,
          acceptedPrivacy: state.acceptedPrivacy,
        ),
      );

      // Consomme les codes saisis — à l'entrée comme à l'inscription — en liens
      // réels et canoniques (children_links approuvés) **avant** d'ouvrir
      // l'espace : le tableau de bord lit alors les enfants dès sa première
      // image, sans rafraîchissement manuel. Un code refusé n'interrompt pas
      // l'inscription ; le compte rendu est présenté dans l'espace parent.
      await ref
          .read(pendingChildLinkProvider.notifier)
          .linkCodes(state.childIdentifiers);

      ref
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(
            role: AppRole.parent,
            userId: result.uid,
            email: result.email,
            firstName: result.firstName,
          );

      state = state.copyWith(isSubmitting: false, clearError: true);
      await IntelliaTelemetry.registrationCompleted(role: 'parent');
      return true;
    } on RoleRegistrationException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Inscription parent impossible pour le moment.',
      );
      return false;
    }
  }

  String? _validateIdentity() {
    return AuthInputValidators.displayName(
          state.firstName,
          label: 'Le prénom',
        ) ??
        AuthInputValidators.displayName(state.lastName, label: 'Le nom');
  }

  String? _validateChildLinks() {
    return null;
  }

  String? _validateFinal() {
    if (!state.acceptedTerms || !state.acceptedPrivacy) {
      return 'Veuillez accepter les consentements requis.';
    }
    return null;
  }
}
