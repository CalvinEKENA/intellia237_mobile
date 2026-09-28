import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';

import 'pack_fixture.dart';

/// Profil élève Terminale D : exactement les packs de sa série et les packs
/// communs, par matière et dans l'ordre du programme ; rien d'une autre série.
void main() {
  test('Terminale D voit maths D, anglais Terminale et physique C-D', () async {
    final repository = ContentPackRepository(source: DiskContentPackSource());
    final subjects = await repository.subjectsFor(
      const ClassKey('terminale', series: 'd'),
    );
    expect(
      {
        for (final subject in subjects)
          subject.key: [for (final entry in subject.chapters) entry.contentId],
      },
      {
        'anglais': [
          'english_terminale_m1_u1_applying_for_passport',
          'english_terminale_m1_u2_discussing_recreational_activities',
        ],
        'mathematiques': [
          'maths_td_ch01_arithmetique',
          'maths_td_ch02_nombres_complexes_algebrique',
          'maths_td_ch03_fonctions_numeriques',
        ],
        'physique': [
          'physique_terminale_cd_m1_s1_erreurs_et_incertitudes',
          'physique_terminale_cd_m1_s2_dimension_grandeur_physique',
        ],
      },
    );
  });
}
