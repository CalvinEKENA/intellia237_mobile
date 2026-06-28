import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../data/firebase_student_registration_repository.dart';
import '../data/student_registration_repository.dart';
import '../domain/academic_rules.dart';
import '../domain/learning_goal.dart';
import '../domain/student_registration_result.dart';
import '../domain/subject_catalog.dart';
import 'student_registration_state.dart';

final studentRegistrationControllerProvider =
    NotifierProvider<StudentRegistrationController, StudentRegistrationState>(
      StudentRegistrationController.new,
    );

class StudentRegistrationController extends Notifier<StudentRegistrationState> {
  StudentRegistrationResult? _registeredUser;

  StudentRegistrationRepository get _repo =>
      ref.read(studentRegistrationRepositoryProvider);

  @override
  StudentRegistrationState build() => const StudentRegistrationState();

  void setFirstName(String value) {
    state = state.copyWith(firstName: value, clearError: true);
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value, clearError: true);
  }

  void setSchoolClass(SchoolClass schoolClass) {
    final allowedSeries = schoolClass.allowedSeries;
    final currentSeries = state.schoolSeries;
    final shouldResetSeries =
        currentSeries != null && !allowedSeries.contains(currentSeries);

    state = state.copyWith(
      schoolClass: schoolClass,
      schoolSeries: shouldResetSeries ? null : currentSeries,
      clearSchoolSeries: schoolClass.allowedSeries.isEmpty,
      clearError: true,
    );
  }

  void setSchoolSeries(SchoolSeries? series) {
    state = state.copyWith(schoolSeries: series, clearError: true);
  }

  void setSelectedTutorId(String? id) {
    state = id != null
        ? state.copyWith(selectedTutorId: id, clearError: true)
        : state.copyWith(clearSelectedTutorId: true, clearError: true);
  }

  void togglePreferredSubject(String subject) {
    final next = _toggleSubject(state.preferredSubjects, subject);
    state = state.copyWith(preferredSubjects: next, clearError: true);
  }

  void toggleDifficultSubject(String subject) {
    final next = _toggleSubject(state.difficultSubjects, subject);
    state = state.copyWith(difficultSubjects: next, clearError: true);
  }

  void setLearningGoal(LearningGoal? goal) {
    state = state.copyWith(learningGoal: goal, clearError: true);
  }

  void setDailyStudyMinutes(int minutes) {
    state = state.copyWith(dailyStudyMinutes: minutes, clearError: true);
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

  void setAcceptedTerms(bool value) {
    state = state.copyWith(acceptedTerms: value, clearError: true);
  }

  void setAcceptedPrivacy(bool value) {
    state = state.copyWith(acceptedPrivacy: value, clearError: true);
  }

  void setAcceptedDataPolicy(bool value) {
    state = state.copyWith(acceptedDataPolicy: value, clearError: true);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void goToNextStep() {
    if (state.currentStep >= 3) {
      return;
    }
    state = state.copyWith(
      currentStep: state.currentStep + 1,
      clearError: true,
    );
  }

  void goToPreviousStep() {
    if (state.currentStep <= 0) {
      return;
    }
    state = state.copyWith(
      currentStep: state.currentStep - 1,
      clearError: true,
    );
  }

  String? validateStep(int step) {
    return switch (step) {
      0 => _validateIdentity(),
      1 => _validateAcademicInfo(),
      2 => _validatePreferences(),
      3 => _validateCredentialsAndConsents(),
      _ => null,
    };
  }

  Future<bool> submit() async {
    final finalError = validateStep(3) ?? _validateAllSteps();
    if (finalError != null) {
      state = state.copyWith(errorMessage: finalError);
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final result = await _repo.registerStudent(state.toPayload());

      _registeredUser = result;
      state = state.copyWith(
        isSubmitting: false,
        isCompleted: true,
        clearError: true,
      );
      return true;
    } on StudentRegistrationException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Inscription impossible pour le moment.',
      );
      return false;
    }
  }

  void completeRegistration() {
    final result = _registeredUser;
    if (result == null || !state.isCompleted) return;
    ref
        .read(authControllerProvider.notifier)
        .setAuthenticatedUser(
          role: AppRole.student,
          userId: result.uid,
          email: result.email,
          firstName: result.firstName,
        );
  }

  String? _validateAllSteps() {
    return _validateIdentity() ??
        _validateAcademicInfo() ??
        _validatePreferences() ??
        _validateCredentialsAndConsents();
  }

  String? _validateIdentity() {
    final firstName = state.firstName.trim();
    final lastName = state.lastName.trim();

    return AuthInputValidators.displayName(firstName, label: 'Le prenom') ??
        AuthInputValidators.displayName(lastName, label: 'Le nom');
  }

  String? _validateAcademicInfo() {
    final schoolClass = state.schoolClass;
    if (schoolClass == null) {
      return 'Selectionnez votre classe.';
    }

    if (schoolClass.requiresSeries && state.schoolSeries == null) {
      return 'La serie est obligatoire pour cette classe.';
    }

    return null;
  }

  String? _validatePreferences() {
    if (state.selectedTutorId == null) {
      return 'Choisissez Kira ou Leo pour personnaliser votre accompagnement.';
    }
    return null;
  }

  String? _validateCredentialsAndConsents() {
    final email = state.email.trim();
    final password = state.password;
    final confirmPassword = state.confirmPassword;

    final credentialsError =
        AuthInputValidators.email(email) ??
        AuthInputValidators.password(password) ??
        AuthInputValidators.confirmPassword(
          password: password,
          confirmation: confirmPassword,
        );
    if (credentialsError != null) return credentialsError;

    if (!state.acceptedTerms ||
        !state.acceptedPrivacy ||
        !state.acceptedDataPolicy) {
      return 'Validez tous les consentements pour continuer.';
    }

    return null;
  }

  List<String> _toggleSubject(List<String> current, String subject) {
    if (!SubjectCatalog.all.contains(subject)) {
      return current;
    }

    if (current.contains(subject)) {
      return current.where((item) => item != subject).toList();
    }

    if (current.length >= 6) {
      return current;
    }

    return <String>[...current, subject];
  }
}
