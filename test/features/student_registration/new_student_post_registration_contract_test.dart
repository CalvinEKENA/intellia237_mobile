import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/learning_goal.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_payload.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';

void main() {
  for (final tutorId in const ['kira', 'leo']) {
    test(
      'new student immediately satisfies home, quiz and companion contract ($tutorId)',
      () async {
        final payload = _newStudent(tutorId);
        final now = DateTime.utc(2026, 8, 30, 12);
        final user = payload.toUserDocument(uid: 'student-237', now: now);
        final profile = payload.toStudentProfileDocument(
          uid: 'student-237',
          now: now,
        );

        // Profile loading and home identity require no manual write.
        final context = studentAcademicContextFromProfile(profile);
        final home = StudentHomeSnapshot(
          firstName: profile['firstName'] as String,
        );
        expect(home.firstName, 'Amina');
        expect(profile['profileCompleted'], isTrue);
        expect(profile['points'], 0);
        expect(profile['level'], 1);
        expect(profile['streak'], isA<Map<String, dynamic>>());

        // Subject catalog and quiz use the non-localized production key.
        expect(user['classLevel'], '6eme');
        expect(profile['classLevel'], '6eme');
        expect(context.quizAndCatalogClassLevel, '6eme');
        expect(context.academicLevelId, 'fr_general_6e');
        expect(context.displayClassLevel, '6ème');
        expect(context.educationalSubsystem, 'francophone');
        expect(context.educationType, 'general');

        // Companion selection resolves from the persisted profile on a new
        // device, independently from local SharedPreferences.
        final tutor = TutorPersona.resolve(context.tutorId);
        expect(tutor.id, tutorId);

        final preferences = profile['preferences'] as Map<String, dynamic>;
        expect(preferences['academicLevelId'], 'fr_general_6e');
        expect(preferences['educationalSubsystem'], 'francophone');
        expect(preferences['educationType'], 'general');
        expect(profile['tutorId'], tutorId);
      },
    );
  }
}

StudentRegistrationPayload _newStudent(String tutorId) {
  return StudentRegistrationPayload(
    firstName: 'Amina',
    lastName: 'Ndi',
    schoolClass: SchoolClass.sixieme,
    schoolSeries: null,
    interfaceLanguage: InterfaceLanguage.french,
    educationalSubsystem: EducationalSubsystem.francophone,
    educationType: EducationType.general,
    selectedTutorId: tutorId,
    preferredSubjects: const ['Mathématiques'],
    difficultSubjects: const ['Anglais'],
    learningGoal: LearningGoal.examMastery,
    dailyStudyMinutes: 30,
    email: 'amina@example.com',
    password: 'MotDePasse!237',
    acceptedTerms: true,
    acceptedPrivacy: true,
    acceptedDataPolicy: true,
  );
}
