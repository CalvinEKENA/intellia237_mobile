import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../role_registration/data/firebase_role_registration_repository.dart';
import '../../role_registration/data/role_registration_repository.dart';
import '../../role_registration/domain/admin_registration_payload.dart';
import '../../student_registration/domain/school_establishment.dart';
import 'admin_registration_state.dart';

final adminRegistrationControllerProvider =
    NotifierProvider<AdminRegistrationController, AdminRegistrationState>(
      AdminRegistrationController.new,
    );

class AdminRegistrationController extends Notifier<AdminRegistrationState> {
  RoleRegistrationRepository get _repo =>
      ref.read(roleRegistrationRepositoryProvider);

  @override
  AdminRegistrationState build() => const AdminRegistrationState();

  Future<List<SchoolEstablishment>> searchEstablishments(String query) {
    return _repo.searchEstablishments(query);
  }

  void setFirstName(String value) {
    state = state.copyWith(firstName: value, clearError: true);
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value, clearError: true);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, clearError: true);
  }

  void setJobTitle(String value) {
    state = state.copyWith(jobTitle: value, clearError: true);
  }

  void setEstablishment(SchoolEstablishment value) {
    state = state.copyWith(establishment: value, clearError: true);
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
      1 => _validateOrganization(),
      2 => _validateFinal(),
      _ => null,
    };
  }

  Future<bool> submit() async {
    final validationError =
        _validateIdentity() ?? _validateOrganization() ?? _validateFinal();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    final establishment = state.establishment;
    if (establishment == null) {
      state = state.copyWith(errorMessage: 'Selectionnez un etablissement.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final result = await _repo.registerAdmin(
        AdminRegistrationPayload(
          firstName: state.firstName.trim(),
          lastName: state.lastName.trim(),
          email: state.email.trim(),
          password: state.password,
          jobTitle: state.jobTitle.trim(),
          establishment: establishment,
          acceptedTerms: state.acceptedTerms,
          acceptedPrivacy: state.acceptedPrivacy,
        ),
      );

      ref
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(
            role: AppRole.admin,
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
        errorMessage: 'Inscription administration impossible pour le moment.',
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
    if (!_isPasswordStrong(state.password)) {
      return 'Mot de passe: 8 caracteres, 1 majuscule, 1 chiffre minimum.';
    }
    if (state.confirmPassword != state.password) {
      return 'La confirmation du mot de passe est invalide.';
    }
    return null;
  }

  String? _validateOrganization() {
    if (state.jobTitle.trim().length < 3) {
      return 'La fonction doit contenir au moins 3 caracteres.';
    }
    if (state.establishment == null) {
      return 'Selectionnez un etablissement.';
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

  bool _isPasswordStrong(String value) {
    if (value.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(value)) return false;
    if (!RegExp(r'[0-9]').hasMatch(value)) return false;
    return true;
  }
}
