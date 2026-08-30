import 'academic_rules.dart';

class AcademicPassport {
  const AcademicPassport({
    required this.preferredDisplayName,
    required this.interfaceLanguage,
    required this.educationalSubsystem,
    required this.educationType,
    required this.level,
    required this.accountLinkage,
    this.streamOrSpeciality,
    this.establishment,
  });

  final String preferredDisplayName;
  final InterfaceLanguage interfaceLanguage;
  final EducationalSubsystem educationalSubsystem;
  final EducationType educationType;
  final SchoolClass level;
  final String? streamOrSpeciality;
  final EstablishmentAffiliation? establishment;
  final LearnerAccountLinkage accountLinkage;

  bool get hasConsistentLevel => level.subsystem == educationalSubsystem;
}
