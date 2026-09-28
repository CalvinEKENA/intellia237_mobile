import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content_engine/application/subject_journey.dart';
import '../../content_engine/domain/curriculum.dart';
import '../domain/learn_subject.dart';
import 'learn_providers.dart';

/// Une matière du Hall d'Apprendre : une seule carte, quelle que soit la
/// source (chapitres interactifs du Content Engine, catalogue en ligne, ou
/// les deux).
@immutable
class LearnSubjectOverview {
  const LearnSubjectOverview({
    required this.key,
    required this.title,
    required this.progress,
    required this.lessonCount,
    required this.sequenceCount,
    this.levelLabel = '',
    this.journey,
    this.catalogue,
    this.contentTerms = const [],
  });

  /// Clé canonique (`mathematiques`, `anglais`, `physique`…).
  final String key;
  final String title;
  final String levelLabel;

  /// Progression de 0 à 1 : la maîtrise des notions pour le Content
  /// Engine, l'avancement du catalogue sinon.
  final double progress;
  final int lessonCount;
  final int sequenceCount;

  /// Parcours interactif (packs embarqués ou en cache), s'il existe.
  final SubjectJourney? journey;

  /// Matière du catalogue en ligne, s'il en existe une.
  final LearnSubject? catalogue;

  /// Modules, séquences et titres de leçons, pour la recherche par
  /// contenu (ex. « passport » trouve l'anglais).
  final List<String> contentTerms;

  int get percent => (progress * 100).round();

  /// L'écran de la matière est celui du Content Engine dès qu'un parcours
  /// existe ; l'ancienne page ne sert qu'aux matières du seul catalogue.
  bool get opensContentEngine => journey != null;

  static LearnSubjectOverview fromJourney(SubjectJourney journey) {
    final subject = journey.subject;
    return LearnSubjectOverview(
      key: canonicalSubjectKey(subject.key),
      title: subject.title,
      levelLabel: subject.levelLabel,
      progress: journey.progress.progress,
      lessonCount: journey.lessonCount,
      sequenceCount: journey.chapters.length,
      journey: journey,
      contentTerms: [
        for (final chapter in journey.chapters) ...[
          ?chapter.entry.curriculum.moduleTitle,
          chapter.entry.curriculum.chapterTitle,
          for (final lesson in chapter.chapter.lessons) lesson.title,
        ],
      ],
    );
  }

  static LearnSubjectOverview fromCatalogue(
    LearnSubject subject, {
    String levelLabel = '',
  }) => LearnSubjectOverview(
    key: canonicalSubjectKey(subject.title),
    title: subject.title,
    levelLabel: levelLabel,
    progress: subject.completion,
    lessonCount: subject.lessonsCount,
    sequenceCount: subject.chapters.length,
    catalogue: subject,
    contentTerms: [for (final chapter in subject.chapters) chapter.title],
  );

  LearnSubjectOverview withCatalogue(LearnSubject subject) =>
      LearnSubjectOverview(
        key: key,
        title: title,
        levelLabel: levelLabel,
        progress: progress,
        lessonCount: lessonCount,
        sequenceCount: sequenceCount,
        journey: journey,
        catalogue: subject,
        contentTerms: [
          ...contentTerms,
          for (final chapter in subject.chapters) chapter.title,
        ],
      );
}

/// Réunit les deux sources en une matière par clé canonique : le parcours
/// interactif d'abord (le contenu réel), puis le catalogue pour les
/// matières qu'il est seul à connaître. L'ordre est celui des parcours,
/// puis celui du catalogue.
List<LearnSubjectOverview> buildSubjectHall({
  List<SubjectJourney> journeys = const [],
  List<LearnSubject> catalogue = const [],
  String catalogueLevel = '',
}) {
  final byKey = <String, LearnSubjectOverview>{};
  for (final journey in journeys) {
    final overview = LearnSubjectOverview.fromJourney(journey);
    byKey.putIfAbsent(overview.key, () => overview);
  }
  for (final subject in catalogue) {
    final key = canonicalSubjectKey(subject.title);
    final known = byKey[key] ?? byKey[canonicalSubjectKey(subject.id)];
    if (known != null) {
      byKey[known.key] = known.withCatalogue(subject);
    } else {
      byKey[key] = LearnSubjectOverview.fromCatalogue(
        subject,
        levelLabel: catalogueLevel,
      );
    }
  }
  return byKey.values.toList(growable: false);
}

/// Une matière retenue par la recherche, avec, si elle a été trouvée par
/// son contenu, le titre qui correspond (ex. « Applying for a passport »).
@immutable
class SubjectHallMatch {
  const SubjectHallMatch(this.subject, {this.context});

  final LearnSubjectOverview subject;
  final String? context;
}

/// Recherche du Hall : réactive, locale, sans réseau.
///
/// Le nom de la matière prime : dès qu'une matière correspond par son nom
/// (« anglais », « math », « phys »), seules ces matières sont montrées.
/// Sinon, une matière dont un module, une séquence ou une leçon correspond
/// est proposée avec ce titre en contexte.
abstract final class SubjectHallSearch {
  static const _aliases = {
    'mathematiques': ['maths', 'math', 'mathematics'],
    'anglais': ['english'],
    'physique': ['physics'],
    'chimie': ['chemistry'],
    'svt': ['sciences de la vie et de la terre', 'biologie', 'biology'],
    'francais': ['french'],
    'histoire': ['history'],
    'geographie': ['geography'],
    'philosophie': ['philosophy', 'philo'],
  };

  /// Minuscules, sans accents, espaces et tirets unifiés.
  static String fold(String input) => normalizeKey(input).replaceAll('-', ' ');

  /// [nameOf] donne le nom affiché (« Anglais » pour un pack « English ») :
  /// l'élève cherche ce qu'il voit.
  static List<SubjectHallMatch> filter(
    List<LearnSubjectOverview> subjects,
    String rawQuery, {
    String Function(LearnSubjectOverview subject)? nameOf,
  }) {
    final query = fold(rawQuery).trim();
    if (query.isEmpty) {
      return [for (final subject in subjects) SubjectHallMatch(subject)];
    }
    final compact = query.replaceAll(' ', '');
    bool matches(String text) {
      final folded = fold(text);
      return folded.contains(query) ||
          folded.replaceAll(' ', '').contains(compact);
    }

    final byName = [
      for (final subject in subjects)
        if ([
          subject.title,
          ?nameOf?.call(subject),
          subject.key,
          ...?_aliases[subject.key],
        ].any(matches))
          SubjectHallMatch(subject),
    ];
    if (byName.isNotEmpty || compact.length < 3) return byName;

    return [
      for (final subject in subjects)
        if (subject.contentTerms.where(matches).firstOrNull case final context?)
          SubjectHallMatch(subject, context: context),
    ];
  }
}

/// Le Hall d'Apprendre, depuis les deux sources, sans jamais attendre la
/// plus lente : les parcours embarqués s'affichent même si le catalogue en
/// ligne tarde ou échoue, et inversement.
final subjectHallProvider = Provider<AsyncValue<List<LearnSubjectOverview>>>((
  ref,
) {
  final journeys = ref.watch(subjectJourneysProvider);
  final catalogue = ref.watch(learnHubProvider);
  final hall = buildSubjectHall(
    journeys: journeys.valueOrNull ?? const [],
    catalogue: catalogue.valueOrNull?.subjects ?? const [],
    catalogueLevel: catalogue.valueOrNull?.context.label ?? '',
  );
  if (hall.isNotEmpty) return AsyncData(hall);
  if (journeys.isLoading || catalogue.isLoading) return const AsyncLoading();
  if (catalogue.hasError && !journeys.hasValue) {
    return AsyncError(catalogue.error!, catalogue.stackTrace!);
  }
  return const AsyncData([]);
});
