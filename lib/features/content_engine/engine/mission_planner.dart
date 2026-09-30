import '../domain/chapter.dart';
import '../domain/curriculum.dart';
import '../domain/game_blueprint.dart';
import '../domain/question.dart';

/// Étapes d'une mission d'intégration, tirées des seules activités validées
/// du chapitre (questions hors leçon, notables).
///
/// Quand le nom du jeu désigne une situation précise (ex. `mission_awa`),
/// seules les activités qui portent ce repère la composent (`int_awa1`…) ;
/// sinon, toutes les activités d'intégration. L'ordre est celui du pack,
/// de la plus accessible à la plus exigeante.
List<Question> missionSteps(Chapter chapter, GameBlueprint game) {
  final all = chapter.integrationQuestions;
  const generic = {
    'mission',
    'game',
    'jeu',
    'chapter',
    'chapitre',
    'integration',
  };
  final markers = [
    for (final token in normalizeKey(game.id).split('-'))
      if (token.length >= 3 && !generic.contains(token)) token,
  ];
  final matching = [
    for (final question in all)
      if (markers.any(normalizeKey(question.id).contains)) question,
  ];
  final steps = matching.isEmpty ? all : matching;
  final ordered = [...steps];
  // Tri stable : difficulté croissante, ordre du pack à égalité.
  final position = {for (final (i, q) in all.indexed) q.id: i};
  ordered.sort((a, b) {
    final byDifficulty = a.difficulty.compareTo(b.difficulty);
    return byDifficulty != 0
        ? byDifficulty
        : position[a.id]!.compareTo(position[b.id]!);
  });
  return ordered;
}
