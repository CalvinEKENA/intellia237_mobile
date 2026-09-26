import 'package:flutter/foundation.dart';

import '../domain/chapter.dart';
import '../domain/companion_action.dart';
import '../domain/curriculum.dart';
import '../domain/pedagogy.dart';
import '../domain/question.dart';
import '../domain/visual_kind.dart';
import 'adaptive_engine.dart';
import 'answer_checker.dart';

export 'companion_name_policy.dart';

/// Ce que le Compagnon sait de la situation de l'élève.
@immutable
class CompanionContext {
  const CompanionContext({
    required this.conceptId,
    required this.lessonNumber,
    this.question,
    this.lastGrade,
    this.hintsShown = 0,
    this.difficulty = 1,
    this.answered = const {},
    this.examplesShown = 0,
    this.mastery,
    this.difficultyChosen = false,
  });

  /// Exemples déjà montrés pour cette notion.
  final int examplesShown;

  /// Maîtrise actuelle de la notion (score 0–100), si connue.
  final int? mastery;

  /// Vrai si l'élève a choisi lui-même la difficulté (elle prime alors).
  final bool difficultyChosen;

  final String? conceptId;
  final int lessonNumber;

  /// Question en cours, s'il y en a une.
  final Question? question;

  /// Correction de la dernière réponse à [question].
  final GradeResult? lastGrade;

  /// Indices déjà montrés pour [question].
  final int hintsShown;
  final int difficulty;
  final Set<String> answered;
}

/// Un morceau de réponse du Compagnon. Chaque texte vient du pack ; le
/// [role] dit seulement comment l'afficher.
enum CompanionPartRole {
  /// Explication d'une notion.
  explanation,

  /// Piège courant (liste `common_mistakes`).
  mistake,

  /// Indice propre à la question.
  hint,

  /// Correction officielle d'une question.
  correction,

  /// Exemple : énoncé d'une question du pack, suivi de sa correction, ou
  /// exemple vérifié tiré du cours.
  example,

  /// Description du modèle visuel.
  visual,
}

@immutable
class CompanionPart {
  const CompanionPart(this.role, this.text);
  final CompanionPartRole role;
  final String text;
}

/// Pourquoi le Compagnon ne peut pas répondre.
enum CompanionGap {
  /// Aucune notion ne correspond à la demande.
  unknownTopic,

  /// Cette explication n'existe pas encore dans le pack.
  explanationMissing,

  /// Tous les indices disponibles ont déjà été donnés.
  noMoreHints,

  /// Pas de réponse fausse à expliquer.
  nothingToExplain,

  /// Plus aucune question pour tester cette notion.
  noQuestionLeft,

  /// Aucune notion en cours.
  noConcept,

  /// Aucun exemple disponible dans le pack pour cette notion.
  noExample,
}

/// Réponse du Compagnon, construite uniquement à partir du pack.
@immutable
class CompanionReply {
  const CompanionReply({
    required this.action,
    this.concept,
    this.mode,
    this.parts = const [],
    this.visual = VisualKind.none,
    this.question,
    this.diagnosis,
    this.fieldResults = const {},
    this.missingCount = 0,
    this.extraCount = 0,
    this.suggestions = const [],
    this.gap,
    this.fallbackMode,
  });

  final CompanionAction? action;
  final Concept? concept;

  /// Niveau d'explication de la réponse.
  final ExplanationMode? mode;
  final List<CompanionPart> parts;
  final VisualKind visual;

  /// Question proposée par « Teste-moi ».
  final Question? question;
  final GradeDiagnosis? diagnosis;
  final Map<String, bool> fieldResults;
  final int missingCount;
  final int extraCount;

  /// Notions proches proposées quand la demande sort du pack.
  final List<Concept> suggestions;
  final CompanionGap? gap;

  /// Niveau réellement montré quand celui demandé manque.
  final ExplanationMode? fallbackMode;

  bool get answered => gap == null;
}

/// Compagnon déterministe : il ne sait que ce que le pack contient.
class CompanionEngine {
  const CompanionEngine(
    this.chapter, {
    this.selector = const QuestionSelector(),
  });

  final Chapter chapter;
  final QuestionSelector selector;

  CompanionReply respond(CompanionAction action, CompanionContext context) {
    final concept = context.conceptId == null
        ? null
        : chapter.concepts[context.conceptId];
    if (concept == null &&
        action != CompanionAction.whyWrong &&
        action != CompanionAction.testMe) {
      return CompanionReply(action: action, gap: CompanionGap.noConcept);
    }
    return switch (action) {
      CompanionAction.explainStandard => _explain(
        action,
        concept!,
        ExplanationMode.standard,
      ),
      CompanionAction.explainSimple => _explain(
        action,
        concept!,
        ExplanationMode.simple,
      ),
      CompanionAction.explainUltraSimple => _explain(
        action,
        concept!,
        ExplanationMode.ultraSimple,
      ),
      CompanionAction.showMe => CompanionReply(
        action: action,
        concept: concept,
        visual: concept!.visualKind,
        parts: [
          if (concept.visualModel case final text?)
            CompanionPart(CompanionPartRole.visual, text),
        ],
      ),
      CompanionAction.example => _example(action, concept!, context),
      CompanionAction.hint => _hint(action, concept!, context),
      CompanionAction.testMe => _test(action, concept, context),
      CompanionAction.whyWrong => _whyWrong(action, concept, context),
    };
  }

  CompanionReply _explain(
    CompanionAction action,
    Concept concept,
    ExplanationMode mode,
  ) {
    final text = concept.explanation(mode);
    if (text != null) {
      return CompanionReply(
        action: action,
        concept: concept,
        mode: mode,
        visual: mode == ExplanationMode.ultraSimple
            ? concept.visualKind
            : VisualKind.none,
        parts: [CompanionPart(CompanionPartRole.explanation, text)],
      );
    }
    // Le niveau demandé manque : on le dit, et l'on montre le plus proche
    // qui existe — jamais un texte inventé.
    final fallback = _closestMode(concept, mode);
    return CompanionReply(
      action: action,
      concept: concept,
      mode: mode,
      gap: CompanionGap.explanationMissing,
      fallbackMode: fallback,
      parts: [
        if (fallback != null)
          CompanionPart(
            CompanionPartRole.explanation,
            concept.explanation(fallback)!,
          ),
      ],
    );
  }

  ExplanationMode? _closestMode(Concept concept, ExplanationMode wanted) {
    final available = concept.availableModes;
    if (available.isEmpty) return null;
    available.sort(
      (a, b) => (a.index - wanted.index).abs().compareTo(
        (b.index - wanted.index).abs(),
      ),
    );
    return available.first;
  }

  /// Échelle d'indices, sans jamais donner la réponse :
  /// 1. indices propres à la question (s'ils existent dans le pack) ;
  /// 2. pièges courants de la notion ;
  /// 3. explication « simple » de la notion.
  CompanionReply _hint(
    CompanionAction action,
    Concept concept,
    CompanionContext context,
  ) {
    final ladder = <CompanionPart>[
      for (final hint in context.question?.hints ?? const <String>[])
        CompanionPart(CompanionPartRole.hint, hint),
      for (final mistake in concept.commonMistakes)
        CompanionPart(CompanionPartRole.mistake, mistake),
      if (concept.explanation(ExplanationMode.simple) case final simple?)
        CompanionPart(CompanionPartRole.explanation, simple),
    ];
    if (context.hintsShown >= ladder.length) {
      return CompanionReply(
        action: action,
        concept: concept,
        gap: CompanionGap.noMoreHints,
      );
    }
    final part = ladder[context.hintsShown];
    return CompanionReply(
      action: action,
      concept: concept,
      mode: part.role == CompanionPartRole.explanation
          ? ExplanationMode.simple
          : null,
      parts: [part],
    );
  }

  /// Exemples de la notion, sans rien inventer :
  /// 1. les exemples vérifiés du cours (`verified_core` qui en annoncent un) ;
  /// 2. les questions faciles de la leçon, énoncé puis correction du pack.
  List<CompanionPart> examplesFor(Concept concept, int lessonNumber) {
    final lesson =
        chapter.lesson(lessonNumber) ??
        (concept.lessonNumber == null
            ? null
            : chapter.lesson(concept.lessonNumber!));
    return [
      for (final statement in lesson?.verifiedCore ?? const <String>[])
        if (normalizeKey(statement).contains('exemple') ||
            normalizeKey(statement).contains('example'))
          CompanionPart(CompanionPartRole.example, statement),
      for (final question in chapter.questions)
        if (question.lessonNumber == (lesson?.number ?? -1) &&
            question.autoScorable &&
            question.difficulty == 1 &&
            question.explanation != null)
          CompanionPart(
            CompanionPartRole.example,
            '${question.prompt}\n→ ${question.explanation}',
          ),
    ];
  }

  CompanionReply _example(
    CompanionAction action,
    Concept concept,
    CompanionContext context,
  ) {
    final examples = examplesFor(concept, context.lessonNumber);
    if (examples.isEmpty) {
      return CompanionReply(
        action: action,
        concept: concept,
        gap: CompanionGap.noExample,
      );
    }
    return CompanionReply(
      action: action,
      concept: concept,
      parts: [examples[context.examplesShown % examples.length]],
    );
  }

  /// Difficulté de « Teste-moi » : celle choisie par l'élève, sinon celle
  /// qui convient à sa maîtrise actuelle.
  int _testDifficulty(CompanionContext context) {
    if (context.difficultyChosen) return context.difficulty;
    final mastery = context.mastery;
    if (mastery == null) return context.difficulty;
    final max = chapter.maxDifficulty;
    if (mastery < 40) return 1;
    if (mastery < 75) return 2.clamp(1, max);
    return max;
  }

  CompanionReply _test(
    CompanionAction action,
    Concept? concept,
    CompanionContext context,
  ) {
    final question = selector.next(
      chapter,
      lessonNumber: context.lessonNumber,
      difficulty: _testDifficulty(context),
      answered: context.answered,
      excludeId: context.question?.id,
    );
    return CompanionReply(
      action: action,
      concept: concept,
      question: question,
      gap: question == null ? CompanionGap.noQuestionLeft : null,
    );
  }

  CompanionReply _whyWrong(
    CompanionAction action,
    Concept? concept,
    CompanionContext context,
  ) {
    final question = context.question;
    final grade = context.lastGrade;
    if (question == null || grade == null || grade.correct) {
      return CompanionReply(
        action: action,
        concept: concept,
        gap: CompanionGap.nothingToExplain,
      );
    }
    final questionConcept = chapter.conceptForQuestion(question) ?? concept;
    return CompanionReply(
      action: action,
      concept: questionConcept,
      diagnosis: grade.diagnosis,
      fieldResults: grade.fieldResults,
      missingCount: grade.missingCount,
      extraCount: grade.extraCount,
      parts: [
        if (question.explanation case final text?)
          CompanionPart(CompanionPartRole.correction, text),
        for (final mistake
            in questionConcept?.commonMistakes ?? const <String>[])
          CompanionPart(CompanionPartRole.mistake, mistake),
      ],
    );
  }

  /// Une question libre : les notions du pack les plus proches, ou rien.
  CompanionReply ask(String text, {int? limit, String? contextConceptId}) {
    final matches = ConceptRouter(
      chapter,
      contextConceptId: contextConceptId,
    ).match(text, limit: limit ?? chapter.companion.fallbackSuggestions);
    if (matches.isEmpty) {
      return const CompanionReply(action: null, gap: CompanionGap.unknownTopic);
    }
    final best = matches.first;
    final explanation = best.explanation(ExplanationMode.standard);
    return CompanionReply(
      action: null,
      concept: best,
      mode: explanation == null ? null : ExplanationMode.standard,
      parts: [
        if (explanation != null)
          CompanionPart(CompanionPartRole.explanation, explanation),
      ],
      suggestions: matches.skip(1).toList(),
    );
  }
}

/// Retrouve les notions d'un pack à partir de mots libres.
///
/// Déterministe : identifiant, titre, alias, prérequis et pièges de chaque
/// notion forment son vocabulaire ; le score compte les mots en commun.
/// S'y ajoutent un petit lexique de synonymes du vocabulaire scolaire
/// (commun à tous les packs), la tolérance aux fautes de frappe et un léger
/// avantage à la notion de la leçon en cours.
class ConceptRouter {
  ConceptRouter(this.chapter, {this.contextConceptId});

  final Chapter chapter;
  final String? contextConceptId;

  static const _stopWords = {
    'le',
    'la',
    'les',
    'un',
    'une',
    'des',
    'de',
    'du',
    'et',
    'ou',
    'a',
    'en',
    'est',
    'que',
    'qui',
    'quoi',
    'comment',
    'pourquoi',
    'je',
    'tu',
    'il',
    'on',
    'ce',
    'c',
    'd',
    'l',
    'j',
    'qu',
    's',
    'dans',
    'par',
    'pour',
    'sur',
    'avec',
    'sans',
    'the',
    'what',
    'how',
    'is',
    'of',
    'to',
    'me',
    'moi',
    'explique',
    'nombre',
    'nombres',
    'deux',
    'calculer',
    'faire',
    'veut',
    'dire',
    'signifie',
    'cest',
    'mon',
    'ma',
    'mes',
    'ton',
    'ta',
  };

  /// Synonymes du vocabulaire scolaire : une expression → mots équivalents.
  static const _synonyms = <String, List<String>>{
    'plus-grand-diviseur-commun': ['pgcd'],
    'plus-petit-multiple-commun': ['ppcm'],
    'base-2': ['binaire'],
    'base-deux': ['binaire'],
    'base-10': ['decimale'],
    'modulo': ['congruence'],
    'congru': ['congruence'],
    'premier': ['premiers'],
    'reste': ['division', 'euclidienne'],
    'quotient': ['division', 'euclidienne'],
    'gcd': ['pgcd'],
    'lcm': ['ppcm'],
    'prime': ['premiers'],
  };

  static Set<String> _words(String text) {
    final key = normalizeKey(text);
    final split = key.split('-');
    final words = {
      for (final word in split)
        if (word.length > 1 && !_stopWords.contains(word)) _stem(word),
      // Une lettre ou un chiffre seul qualifie le mot qui le précède :
      // « type A » et « type B », « série C » restent distincts.
      for (var i = 1; i < split.length; i++)
        if (split[i].length == 1 &&
            split[i - 1].length > 1 &&
            !_stopWords.contains(split[i - 1]))
          '${_stem(split[i - 1])}$_qualified${split[i]}',
    };
    for (final entry in _synonyms.entries) {
      if (key.contains(entry.key)) {
        words.addAll(entry.value.map(_stem));
      }
    }
    return words;
  }

  /// Séparateur des mots qualifiés (« type·b ») : jamais rapprochés par
  /// la tolérance aux fautes de frappe.
  static const _qualified = '·';

  /// Racine grossière : pluriels et terminaisons courantes retirés.
  static String _stem(String word) {
    for (final suffix in const [
      'iennes',
      'ienne',
      'iens',
      'ien',
      'es',
      's',
      'e',
    ]) {
      if (word.length > suffix.length + 3 && word.endsWith(suffix)) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    return word;
  }

  /// Distance d'édition bornée : une faute de frappe sur un mot assez long.
  static bool _close(String a, String b) {
    if (a.contains(_qualified) || b.contains(_qualified)) return false;
    if (a == b) return true;
    if (a.length < 5 || b.length < 5 || (a.length - b.length).abs() > 1) {
      return false;
    }
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }

  List<Concept> match(String text, {int limit = 3}) {
    final query = _words(text);
    if (query.isEmpty) return const [];
    final scored = <(Concept, int)>[];
    for (final concept in chapter.concepts.values) {
      final strong = {
        ..._words(concept.id.replaceAll('_', ' ')),
        ..._words(concept.title),
        for (final alias in concept.aliases) ..._words(alias),
      };
      final weak = {
        for (final item in [
          ...concept.prerequisites,
          ...concept.commonMistakes,
        ])
          ..._words(item),
      };
      var score = 0;
      for (final word in query) {
        if (strong.contains(word)) {
          score += 3;
        } else if (strong.any((known) => _close(known, word))) {
          score += 2;
        } else if (weak.contains(word)) {
          score += 1;
        }
      }
      if (score >= 2 && concept.id == contextConceptId) score += 1;
      if (score >= 3) scored.add((concept, score));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      return chapter.learningPath
          .indexOf(a.$1.id)
          .compareTo(chapter.learningPath.indexOf(b.$1.id));
    });
    return [for (final (concept, _) in scored.take(limit)) concept];
  }
}
