import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
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

      ref
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(
            role: AppRole.parent,
            userId: result.uid,
            email: result.email,
            firstName: result.firstName,
          );

      state = state.copyWith(isSubmitting: false, clearError: true);
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
    if (state.firstName.trim().length < 2) {
      return 'Le prenom doit contenir au moins 2 caracteres.';
    }
    if (state.lastName.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caracteres.';
    }
    if (!_isEmailValid(state.email.trim())) {
      return 'Entrez une adresse email valide.';
    }
    if (state.phoneNumber.trim().isNotEmpty &&
        !_isPhoneValid(state.phoneNumber.trim())) {
      return 'Numero de telephone invalide.';
    }
    if (!_isPasswordStrong(state.password)) {
      return 'Mot de passe: 8 caracteres, 1 majuscule, 1 chiffre minimum.';
    }
    if (state.confirmPassword != state.password) {
      return 'La confirmation du mot de passe est invalide.';
    }
    return null;
  }

  String? _validateChildLinks() {
    if (state.childIdentifiers.isEmpty) {
      return 'Ajoutez au moins un code ou identifiant enfant.';
    }
    return null;
  }

  String? _validateFinal() {
    if (!state.acceptedTerms || !state.acceptedPrivacy) {
      return 'Veuillez accepter les consentements requis.';
    }
    return null;
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
  }

  bool _isPhoneValid(String phone) {
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone);
  }

  bool _isPasswordStrong(String value) {
    if (value.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(value)) return false;
    if (!RegExp(r'[0-9]').hasMatch(value)) return false;
    return true;
  }
}
