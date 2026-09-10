import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/application/learn_providers.dart';
import '../../learn/domain/curriculum_catalog.dart';
import '../../learn/domain/learn_subject.dart';
import '../../student_registration/domain/academic_level_identity.dart';
import '../../student_registration/domain/academic_rules.dart';

/// Une matière du profil, qu'elle porte ou non du contenu publié.
class LearnerCatalogSubject {
  const LearnerCatalogSubject({
    required this.subject,
    required this.hasPublishedContent,
  });

  final LearnSubject subject;

  /// Faux pour une matière connue du programme mais sans cours publié.
  /// La carte reste affichée, sans jamais inventer de score.
  final bool hasPublishedContent;
}

/// Catalogue de matières de l'élève : programme officiel **et** contenu publié.
///
/// Le profil de maîtrise listait uniquement les matières publiées dans
/// Firestore. Sur l'appareil, seules « Anglais » et « SVT » étaient alimentées,
/// donc seules ces deux matières apparaissaient — comme si l'élève n'en suivait
/// que deux.
///
/// Le contrat de maîtrise n'est pas assoupli pour autant : afficher davantage
/// de matières ne crée aucune estimation. Une matière sans preuve conserve son
/// état « pas encore assez d'éléments », et les plafonds
/// `sourceStateCeiling` / `sourceConfidenceCeiling` restent inchangés.
final learnerSubjectCatalogProvider =
    FutureProvider.autoDispose<List<LearnerCatalogSubject>>((ref) async {
      final context = await ref.watch(studentAcademicContextProvider.future);
      final hub = await ref.watch(learnHubProvider.future);
      final published = hub.subjects;

      final identity = AcademicLevelIdentity.resolve(
        academicLevelId: context.academicLevelId,
        storedClassLevel: context.classLevel,
        educationalSubsystem: context.educationalSubsystem,
        educationType: context.educationType,
      );

      // Niveau non résolu : on n'invente aucun programme et on s'en tient
      // strictement à ce qui est publié.
      if (identity == null) {
        return [
          for (final subject in published)
            LearnerCatalogSubject(subject: subject, hasPublishedContent: true),
        ];
      }

      final curriculum = CurriculumCatalog.forLevel(
        schoolClass: identity.schoolClass,
        series: _series(context.series),
      );

      final merged = <LearnerCatalogSubject>[
        for (final subject in published)
          LearnerCatalogSubject(subject: subject, hasPublishedContent: true),
      ];
      final seen = {
        for (final entry in merged)
          CurriculumCatalog.normalizeId(entry.subject.id),
        for (final entry in merged)
          CurriculumCatalog.normalizeId(entry.subject.title),
      };

      final english =
          (context.educationalSubsystem ?? '').toLowerCase() == 'anglophone';
      for (final subject in curriculum) {
        if (seen.contains(CurriculumCatalog.normalizeId(subject.id))) continue;
        merged.add(
          LearnerCatalogSubject(
            hasPublishedContent: false,
            subject: LearnSubject(
              id: subject.id,
              title: subject.label(english: english),
              description: '',
              colorHex: subject.colorHex,
              iconKey: subject.iconKey,
              chapters: const [],
            ),
          ),
        );
      }
      return merged;
    });

SchoolSeries? _series(String? stored) {
  final value = stored?.trim().toLowerCase();
  return switch (value) {
    'a' => SchoolSeries.a,
    'c' => SchoolSeries.c,
    'd' => SchoolSeries.d,
    _ => null,
  };
}
