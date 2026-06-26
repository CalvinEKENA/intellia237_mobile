import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../../role_registration/data/firebase_role_registration_repository.dart';
import '../../role_registration/data/role_registration_repository.dart';
import '../../role_registration/domain/teacher_catalogs.dart';
import '../../role_registration/domain/teacher_registration_payload.dart';
import '../../student_registration/domain/school_establishment.dart';
import 'teacher_registration_state.dart';

final teacherRegistrationControllerProvider =
    NotifierProvider<TeacherRegistrationController, TeacherRegistrationState>(
      TeacherRegistrationController.new,
    );

class TeacherRegistrationController extends Notifier<TeacherRegistrationState> {
  RoleRegistrationRepository get _repo =>
      ref.read(roleRegistrationRepositoryProvider);

  @override
  TeacherRegistrationState build() => const TeacherRegistrationState();

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

  void setEstablishment(SchoolEstablishment value) {
    state = state.copyWith(establishment: value, clearError: true);
  }

  void toggleSubject(String value) {
    if (!TeacherCatalogs.subjects.contains(value)) {
      return;
    }

    if (state.subjects.contains(value)) {
      state = state.copyWith(
        subjects: state.subjects.where((item) => item != value).toList(),
        clearError: true,
      );
      return;
    }

    if (state.subjects.length >= 8) {
      return;
    }

    state = state.copyWith(
      subjects: [...state.subjects, value],
      clearError: true,
    );
  }

  void toggleLevel(String value) {
    if (!TeacherCatalogs.levels.contains(value)) {
      return;
    }

    if (state.levels.contains(value)) {
      state = state.copyWith(
        levels: state.levels.where((item) => item != value).toList(),
        clearError: true,
      );
      return;
    }

    state = state.copyWith(levels: [...state.levels, value], clearError: true);
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
      1 => _validateTeachingData(),
      2 => _validateFinal(),
      _ => null,
    };
  }

  Future<bool> submit() async {
    final validationError =
        _validateIdentity() ?? _validateTeachingData() ?? _validateFinal();
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
      final result = await _repo.registerTeacher(
        TeacherRegistrationPayload(
          firstName: state.firstName.trim(),
          lastName: state.lastName.trim(),
          email: state.email.trim(),
          password: state.password,
          establishment: establishment,
          subjects: state.subjects,
          levels: state.levels,
          acceptedTerms: state.acceptedTerms,
          acceptedPrivacy: state.acceptedPrivacy,
        ),
      );

      ref
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(
            role: AppRole.teacher,
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
        errorMessage: 'Inscription enseignant impossible pour le moment.',
      );
      return false;
    }
  }

  String? _validateIdentity() {
    return AuthInputValidators.displayName(
          state.firstName,
          label: 'Le prenom',
        ) ??
        AuthInputValidators.displayName(state.lastName, label: 'Le nom') ??
        AuthInputValidators.email(state.email) ??
        AuthInputValidators.password(state.password) ??
        AuthInputValidators.confirmPassword(
          password: state.password,
          confirmation: state.confirmPassword,
        );
  }

  String? _validateTeachingData() {
    if (state.establishment == null) {
      return 'Selectionnez un etablissement.';
    }
    if (state.subjects.isEmpty) {
      return 'Selectionnez au moins une matiere enseignee.';
    }
    if (state.levels.isEmpty) {
      return 'Selectionnez au moins un niveau enseigne.';
    }
    return null;
  }

  String? _validateFinal() {
    if (!state.acceptedTerms || !state.acceptedPrivacy) {
      return 'Veuillez accepter les consentements requis.';
    }
    return null;
  }
}
