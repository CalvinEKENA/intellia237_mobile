import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../data/firebase_student_registration_repository.dart';
import '../data/student_registration_repository.dart';
import '../domain/academic_rules.dart';
import '../domain/learning_goal.dart';
import '../domain/school_establishment.dart';
import '../domain/subject_catalog.dart';
import 'student_registration_state.dart';

final studentRegistrationControllerProvider =
    NotifierProvider<StudentRegistrationController, StudentRegistrationState>(
      StudentRegistrationController.new,
    );

class StudentRegistrationController extends Notifier<StudentRegistrationState> {
  StudentRegistrationRepository get _repo =>
      ref.read(studentRegistrationRepositoryProvider);

  @override
  StudentRegistrationState build() => const StudentRegistrationState();

  Future<List<SchoolEstablishment>> searchEstablishments(String query) {
    return _repo.searchEstablishments(query);
  }

  void setFirstName(String value) {
    state = state.copyWith(firstName: value, clearError: true);
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value, clearError: true);
  }

  void setEstablishment(SchoolEstablishment establishment) {
    state = state.copyWith(establishment: establishment, clearError: true);
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

      ref
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(
            role: AppRole.student,
            userId: result.uid,
            email: result.email,
            firstName: result.firstName,
          );

      state = state.copyWith(isSubmitting: false, clearError: true);
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

  String? _validateAllSteps() {
    return _validateIdentity() ??
        _validateAcademicInfo() ??
        _validatePreferences() ??
        _validateCredentialsAndConsents();
  }

  String? _validateIdentity() {
    final firstName = state.firstName.trim();
    final lastName = state.lastName.trim();

    if (firstName.length < 2) {
      return 'Le prenom doit contenir au moins 2 caracteres.';
    }
    if (lastName.length < 2) {
      return 'Le nom doit contenir au moins 2 caracteres.';
    }
    return null;
  }

  String? _validateAcademicInfo() {
    if (state.establishment == null) {
      return 'Selectionnez un etablissement.';
    }

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
    if (state.preferredSubjects.isEmpty) {
      return 'Choisissez au moins une matiere preferee.';
    }

    if (state.difficultSubjects.isEmpty) {
      return 'Choisissez au moins une matiere difficile.';
    }

    if (state.learningGoal == null) {
      return 'Selectionnez un objectif d\'apprentissage.';
    }

    if (state.dailyStudyMinutes < 10) {
      return 'Le temps d\'etude quotidien est trop faible.';
    }

    return null;
  }

  String? _validateCredentialsAndConsents() {
    final email = state.email.trim();
    final password = state.password;
    final confirmPassword = state.confirmPassword;

    if (!_isValidEmail(email)) {
      return 'Entrez un email valide.';
    }

    if (password.length < 8 || !_isStrongEnoughPassword(password)) {
      return 'Mot de passe: 8 caracteres, 1 majuscule, 1 chiffre minimum.';
    }

    if (confirmPassword != password) {
      return 'La confirmation du mot de passe est invalide.';
    }

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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
  }

  bool _isStrongEnoughPassword(String password) {
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    return hasUppercase && hasDigit;
  }
}
