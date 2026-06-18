import '../../student_registration/domain/academic_rules.dart';
import '../../student_registration/domain/subject_catalog.dart';

abstract final class TeacherCatalogs {
  static const subjects = SubjectCatalog.all;
  static final levels = [
    for (final schoolClass in SchoolClassX.ordered) schoolClass.label,
  ];
}
