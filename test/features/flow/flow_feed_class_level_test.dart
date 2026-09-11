import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/domain/admin_content_models.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';

/// Ce que l'administration générale publie pour une classe doit paraître dans
/// cette classe de chaque établissement. Encore faut-il que le Studio et
/// l'élève parlent du même niveau.
void main() {
  test('un profil ancien en « Première » lit le fil publié pour « Premiere »', () {
    expect(
      flowFeedClassLevel(
        const LearnAcademicContext(
          classLevel: 'Première',
          catalogClassLevel: 'Premiere',
        ),
      ),
      'Premiere',
    );
  });

  test('sans clé de catalogue, le niveau enregistré sert encore', () {
    expect(
      flowFeedClassLevel(const LearnAcademicContext(classLevel: 'Terminale')),
      'Terminale',
    );
  });

  test('sans profil scolaire, aucun fil n’est demandé', () {
    expect(flowFeedClassLevel(null), isNull);
  });

  test('chaque classe francophone de l’élève existe dans le Studio', () {
    for (final schoolClass in const [
      SchoolClass.sixieme,
      SchoolClass.cinquieme,
      SchoolClass.quatrieme,
      SchoolClass.troisieme,
      SchoolClass.seconde,
      SchoolClass.premiere,
      SchoolClass.terminale,
    ]) {
      expect(kAllClassLevels, contains(schoolClass.catalogKey));
    }
  });
}
