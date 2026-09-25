import '../../../core/academics/class_key.dart';
import '../domain/chapter.dart';
import '../domain/companion_action.dart';
import '../domain/content_issue.dart';
import '../domain/curriculum.dart';
import '../domain/game_blueprint.dart';
import '../domain/mastery.dart';
import '../domain/pedagogy.dart';
import '../domain/question.dart';
import '../domain/validation.dart';
import '../domain/visual_kind.dart';

/// Les documents bruts d'un pack, tels que lus sur le disque.
class RawContentPack {
  const RawContentPack({
    required this.directory,
    required this.manifest,
    this.source,
    this.pedagogy,
    this.runtime,
    this.validation,
  });

  final String directory;
  final Map<String, Object?> manifest;
  final Map<String, Object?>? source;
  final Map<String, Object?>? pedagogy;
  final Map<String, Object?>? runtime;
  final Map<String, Object?>? validation;
}

/// Transforme un pack JSON en [Chapter] fortement typé.
///
/// Règles :
/// * aucune donnée n'est corrigée : une incohérence devient une
///   [ContentIssue] et, si elle rend la correction incertaine, la question
///   est retirée des exercices notés ;
/// * un champ facultatif absent ne fait jamais échouer la lecture ;
/// * une version majeure de schéma inconnue est refusée, pas devinée.
class ContentPackParser {
  const ContentPackParser();

  /// Versions majeures que ce moteur sait lire, par famille de document.
  static const supportedMajors = <String, int>{
    'source': 1,
    'pedagogy': 1,
    'runtime-learning-pack': 1,
    'validation-report': 1,
  };

  Chapter parse(RawContentPack raw) {
    final issues = <ContentIssue>[];
    void issue(
      ContentIssueSeverity severity,
      String code,
      String message, [
      String? path,
    ]) => issues.add(
      ContentIssue(
        severity: severity,
        code: code,
        message: message,
        path: path,
      ),
    );

    final runtime = raw.runtime;
    if (runtime == null) {
      issue(
        ContentIssueSeverity.error,
        'pack_runtime_missing',
        "Le fichier d'exécution du pack est absent : aucun contenu "
            'consommable.',
      );
    }
    for (final (name, document, family) in [
      ('source', raw.source, 'source'),
      ('pedagogy', raw.pedagogy, 'pedagogy'),
      ('runtime', runtime, 'runtime-learning-pack'),
      ('validation', raw.validation, 'validation-report'),
    ]) {
      if (document == null) continue;
      _checkSchema(document, name, family, issue);
    }

    final runtimeMap = runtime ?? const <String, Object?>{};
    final pedagogy = raw.pedagogy ?? const <String, Object?>{};
    final source = raw.source ?? const <String, Object?>{};

    final curriculum = _curriculum(
      _map(runtimeMap['curriculum']) ?? _map(source['curriculum']),
      issue,
    );
    final contentId =
        _string(source['content_id']) ??
        _string(pedagogy['content_id']) ??
        _string(raw.manifest['content_id']) ??
        normalizeKey(raw.directory.split('/').last);
    final packId = _string(runtimeMap['pack_id']) ?? contentId;
    if (_string(pedagogy['content_id']) case final pedagogyId?
        when pedagogyId != contentId) {
      issue(
        ContentIssueSeverity.warning,
        'content_id_mismatch',
        'pedagogy.content_id « $pedagogyId » diffère de « $contentId ».',
      );
    }

    final concepts = _concepts(pedagogy, issue);
    final lessons = _lessons(runtimeMap, source, concepts, issue);
    final difficulties = _difficulties(runtimeMap, pedagogy);
    final modes = _explanationModes(runtimeMap, pedagogy, issue);
    final validation = _validation(raw.validation, packId, issue);
    var questions = _questions(runtimeMap, lessons, difficulties, issue);
    questions = _attachFlags(questions, validation.flags, issue);
    final games = _games(runtimeMap, concepts, difficulties, [
      for (final q in questions)
        if (q.isIntegration && q.autoScorable) q,
    ], issue);
    final companion = _companion(_map(runtimeMap['companion']), issue);
    final mastery = _mastery(_map(runtimeMap['mastery']));
    final llmRequired =
        runtimeMap['llm_required'] == true ||
        _map(runtimeMap['companion'])?['runtime_llm_required'] == true;
    if (llmRequired) {
      issue(
        ContentIssueSeverity.error,
        'pack_requires_llm',
        'Le pack déclare avoir besoin d\'un modèle de langage : il n\'est pas '
            'proposé en mode local.',
      );
    }

    _checkManifest(raw.manifest, lessons, questions, games, issue);
    _checkLearningPath(pedagogy, concepts, issue);
    if (validation.questionCount case final count?
        when count != questions.length) {
      issue(
        ContentIssueSeverity.warning,
        'validation_question_count_mismatch',
        'Le rapport annonce $count questions, le pack en contient '
            '${questions.length}.',
      );
    }

    return Chapter(
      contentId: contentId,
      packId: packId,
      curriculum: curriculum,
      lessons: lessons,
      concepts: concepts,
      learningPath: _stringList(pedagogy['learning_path']),
      difficulties: difficulties,
      explanationModes: modes,
      questions: questions,
      games: games,
      companion: companion,
      mastery: mastery,
      validation: validation,
      issues: List.unmodifiable(issues),
      llmRequired: llmRequired,
      designPrinciple: _string(pedagogy['design_principle']),
      adaptiveRuleTexts: _stringList(pedagogy['adaptive_rules']),
    );
  }

  /// Lecture légère pour le catalogue (manifeste + curriculum).
  ChapterEntry? entry(RawContentPack raw) {
    final curriculumMap =
        _map(raw.manifest['curriculum']) ??
        _map(raw.runtime?['curriculum']) ??
        _map(raw.source?['curriculum']);
    if (curriculumMap == null) return null;
    final curriculum = _curriculum(curriculumMap, (_, _, _, [_]) {});
    final stats = _map(raw.manifest['stats']);
    // Classes visées : déclarées par le manifeste, sinon lues dans le
    // curriculum (« Terminale D » → `terminale-d`). Aucune : pack ignoré.
    final declared = _stringList(raw.manifest['class_keys']);
    final classKeys = [
      for (final key in declared.isEmpty ? [curriculum.level] : declared)
        ...ClassKey.parseTargets(key),
    ];
    if (classKeys.isEmpty) return null;
    return ChapterEntry(
      contentId:
          _string(raw.manifest['content_id']) ??
          _string(raw.source?['content_id']) ??
          normalizeKey(raw.directory.split('/').last),
      directory: raw.directory,
      curriculum: curriculum,
      lessonCount: (stats?['lessons'] as num?)?.toInt() ?? 0,
      classKeys: classKeys,
      version: (raw.manifest['version'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Schéma ────────────────────────────────────────────────────────────

  void _checkSchema(
    Map<String, Object?> document,
    String name,
    String family,
    _IssueSink issue,
  ) {
    final raw = _string(document['schema_version']);
    final version = SchemaVersion.tryParse(raw);
    if (version == null) {
      issue(
        ContentIssueSeverity.warning,
        'schema_version_unreadable',
        '$name.schema_version « $raw » n\'est pas lisible ; lecture tolérante.',
        name,
      );
      return;
    }
    if (version.family != family) {
      issue(
        ContentIssueSeverity.warning,
        'schema_family_mismatch',
        '$name annonce la famille « ${version.family} » au lieu de « $family ».',
        name,
      );
    }
    final supported = supportedMajors[family] ?? 1;
    if (version.major > supported) {
      issue(
        ContentIssueSeverity.error,
        'pack_schema_too_recent',
        '$name est en v${version.major} ; ce moteur lit jusqu\'à v$supported.',
        name,
      );
    }
  }

  // ── Curriculum, notions, leçons ───────────────────────────────────────

  Curriculum _curriculum(Map<String, Object?>? map, _IssueSink issue) {
    if (map == null) {
      issue(
        ContentIssueSeverity.error,
        'pack_curriculum_missing',
        'Aucun curriculum : le chapitre ne peut pas être rangé.',
      );
    }
    return Curriculum(
      country: _string(map?['country']) ?? '',
      level: _string(map?['level']) ?? '',
      subject: _string(map?['subject']) ?? '',
      module: _string(map?['module']),
      chapterNumber: (map?['chapter_number'] as num?)?.toInt() ?? 0,
      chapterTitle: _string(map?['chapter_title']) ?? '',
    );
  }

  Map<String, Concept> _concepts(
    Map<String, Object?> pedagogy,
    _IssueSink issue,
  ) {
    final concepts = <String, Concept>{};
    final list = pedagogy['concepts'];
    if (list is! List) return concepts;
    for (final (index, item) in list.indexed) {
      final map = _map(item);
      final id = _string(map?['id']);
      if (map == null || id == null) {
        issue(
          ContentIssueSeverity.warning,
          'concept_without_id',
          'Notion n°$index sans identifiant : ignorée.',
          'pedagogy.concepts[$index]',
        );
        continue;
      }
      final explanations = <ExplanationMode, String>{};
      final rawExplanations = _map(map['explanations']);
      rawExplanations?.forEach((key, value) {
        final mode = ExplanationMode.fromKey(key);
        final text = _string(value);
        if (mode == null) {
          issue(
            ContentIssueSeverity.info,
            'explanation_mode_unknown',
            'Niveau d\'explication « $key » inconnu : ignoré.',
            'pedagogy.concepts[$id].explanations',
          );
        } else if (text != null) {
          explanations[mode] = text;
        }
      });
      for (final mode in ExplanationMode.values) {
        if (!explanations.containsKey(mode)) {
          issue(
            ContentIssueSeverity.warning,
            'explanation_missing',
            'La notion « $id » n\'a pas d\'explication « ${mode.key} ».',
            'pedagogy.concepts[$id].explanations',
          );
        }
      }
      final visualModel = _string(map['visual_model']);
      final explicitKind = VisualKind.fromKey(_string(map['visual_kind']));
      concepts[id] = Concept(
        id: id,
        lessonNumber: (map['lesson'] as num?)?.toInt(),
        title: _string(map['title']) ?? id,
        prerequisites: _stringList(map['prerequisites']),
        explanations: explanations,
        visualModel: visualModel,
        visualKind: explicitKind ?? VisualKind.infer(visualModel),
        commonMistakes: _stringList(map['common_mistakes']),
        aliases: _stringList(map['aliases']),
      );
    }
    return concepts;
  }

  List<Lesson> _lessons(
    Map<String, Object?> runtime,
    Map<String, Object?> source,
    Map<String, Concept> concepts,
    _IssueSink issue,
  ) {
    final provenance = <int, Map<String, Object?>>{};
    final chapterMap = source['chapter_map'];
    if (chapterMap is List) {
      for (final item in chapterMap) {
        final map = _map(item);
        final number = (map?['lesson'] as num?)?.toInt();
        if (map != null && number != null) provenance[number] = map;
      }
    }
    final lessons = <Lesson>[];
    final refs = runtime['lesson_refs'];
    if (refs is List) {
      for (final (index, item) in refs.indexed) {
        final map = _map(item);
        final number = (map?['lesson'] as num?)?.toInt();
        if (map == null || number == null) {
          issue(
            ContentIssueSeverity.warning,
            'lesson_ref_invalid',
            'Référence de leçon n°$index illisible : ignorée.',
            'runtime.lesson_refs[$index]',
          );
          continue;
        }
        final conceptId = _string(map['concept_id']);
        if (conceptId != null && !concepts.containsKey(conceptId)) {
          issue(
            ContentIssueSeverity.warning,
            'lesson_concept_unknown',
            'La leçon $number vise la notion « $conceptId », absente de la '
                'pédagogie.',
            'runtime.lesson_refs[$index]',
          );
        }
        final origin = provenance[number];
        lessons.add(
          Lesson(
            number: number,
            title:
                _string(map['title']) ?? _string(origin?['title']) ?? '$number',
            conceptId: conceptId,
            verifiedCore: _stringList(origin?['verified_core']),
            sourceSituation: _string(origin?['source_situation']),
            sourcePages: _stringList(origin?['images']),
          ),
        );
      }
    }
    lessons.sort((a, b) => a.number.compareTo(b.number));
    return lessons;
  }

  List<DifficultyLevel> _difficulties(
    Map<String, Object?> runtime,
    Map<String, Object?> pedagogy,
  ) {
    final axis = _map(pedagogy['difficulty_axis']) ?? const {};
    final values = <int>{
      ...?(runtime['difficulty_levels'] as List?)?.whereType<num>().map(
        (value) => value.toInt(),
      ),
      for (final key in axis.keys) ?int.tryParse(key),
    };
    if (values.isEmpty) values.addAll(const [1, 2, 3]);
    final sorted = values.toList()..sort();
    return [
      for (final value in sorted)
        DifficultyLevel(
          value,
          label: _string(_map(axis['$value'])?['label']),
          focus: _string(_map(axis['$value'])?['focus']),
        ),
    ];
  }

  List<ExplanationMode> _explanationModes(
    Map<String, Object?> runtime,
    Map<String, Object?> pedagogy,
    _IssueSink issue,
  ) {
    final declared = _stringList(runtime['explanation_modes']);
    if (declared.isEmpty) return ExplanationMode.values;
    final modes = <ExplanationMode>[];
    for (final key in declared) {
      final mode = ExplanationMode.fromKey(key);
      if (mode == null) {
        issue(
          ContentIssueSeverity.info,
          'explanation_mode_unknown',
          'runtime.explanation_modes contient « $key », inconnu : ignoré.',
        );
      } else {
        modes.add(mode);
      }
    }
    return modes;
  }

  // ── Questions ─────────────────────────────────────────────────────────

  List<Question> _questions(
    Map<String, Object?> runtime,
    List<Lesson> lessons,
    List<DifficultyLevel> difficulties,
    _IssueSink issue,
  ) {
    final lessonNumbers = {for (final lesson in lessons) lesson.number};
    final difficultyValues = {for (final level in difficulties) level.value};
    final seen = <String>{};
    final questions = <Question>[];
    final bank = runtime['question_bank'];
    if (bank is! List) return questions;
    for (final (index, item) in bank.indexed) {
      final map = _map(item);
      final id = _string(map?['id']);
      final path = 'runtime.question_bank[${id ?? index}]';
      if (map == null || id == null) {
        issue(
          ContentIssueSeverity.error,
          'question_without_id',
          'Question n°$index sans identifiant : ignorée.',
          path,
        );
        continue;
      }
      if (!seen.add(id)) {
        issue(
          ContentIssueSeverity.error,
          'question_duplicate_id',
          'Identifiant « $id » en double : seule la première est gardée.',
          path,
        );
        continue;
      }
      final rawType = _string(map['type']) ?? 'unknown';
      final type = QuestionType.fromKey(rawType);
      final lessonNumber = (map['lesson'] as num?)?.toInt() ?? 0;
      final difficulty = (map['difficulty'] as num?)?.toInt() ?? 0;
      final choices = [
        for (final choice in (map['choices'] as List?) ?? const [])
          ?AnswerAtom.fromJson(choice),
      ];
      final prompt = _string(map['prompt']);
      String? disabled;
      void disable(String code, String message) {
        issue(ContentIssueSeverity.error, code, message, path);
        disabled ??= code;
      }

      if (prompt == null) {
        disable('question_without_prompt', 'Question sans énoncé.');
      }
      if (lessonNumber != 0 && !lessonNumbers.contains(lessonNumber)) {
        disable(
          'question_lesson_unknown',
          'La question vise la leçon $lessonNumber, absente du pack.',
        );
      }
      if (!difficultyValues.contains(difficulty)) {
        disable(
          'question_difficulty_unknown',
          'Difficulté « $difficulty » non déclarée.',
        );
      }
      if (type == QuestionType.unknown) {
        disable(
          'question_type_unknown',
          'Type « $rawType » inconnu de ce moteur : question non notée.',
        );
      }
      final answer = _answer(type, map['answer'], choices);
      if (answer is UnscorableAnswer && type != QuestionType.unknown) {
        disable('question_answer_unscorable', answer.reason);
      }
      questions.add(
        Question(
          id: id,
          lessonNumber: lessonNumber,
          difficulty: difficulty,
          type: type,
          rawType: rawType,
          prompt: prompt ?? '',
          answer: answer,
          explanation: _string(map['explanation']),
          sourceAnchor: _string(map['source_anchor']),
          tags: _stringList(map['tags']),
          choices: choices,
          hints: [..._stringList(map['hints']), ?_string(map['hint'])],
          disabledReason: disabled,
        ),
      );
    }
    return questions;
  }

  Answer _answer(QuestionType type, Object? raw, List<AnswerAtom> choices) {
    switch (type) {
      case QuestionType.numeric:
        return _valueAnswer(raw) ??
            const UnscorableAnswer('Réponse numérique illisible.');
      case QuestionType.mcq:
        final atom = AnswerAtom.fromJson(raw);
        if (atom == null) {
          return const UnscorableAnswer('Réponse de QCM illisible.');
        }
        if (!choices.contains(atom)) {
          return UnscorableAnswer(
            'La réponse « $atom » ne figure pas parmi les propositions.',
          );
        }
        return ChoiceAnswer(atom);
      case QuestionType.multiSelect:
        if (raw is! List) {
          return const UnscorableAnswer('Choix multiples illisibles.');
        }
        final atoms = {for (final value in raw) ?AnswerAtom.fromJson(value)};
        if (atoms.length != raw.length) {
          return const UnscorableAnswer('Choix multiples illisibles.');
        }
        final missing = atoms.where((atom) => !choices.contains(atom));
        if (missing.isNotEmpty) {
          return UnscorableAnswer(
            'Réponses absentes des propositions : ${missing.join(', ')}.',
          );
        }
        return MultiChoiceAnswer(atoms);
      case QuestionType.trueFalse:
        return raw is bool
            ? BooleanAnswer(raw)
            : const UnscorableAnswer('Réponse vrai/faux illisible.');
      case QuestionType.reasoning || QuestionType.procedure:
        return _verdict(raw) ??
            const UnscorableAnswer(
              'Réponse rédigée : le moteur ne corrige que « oui » ou « non ».',
            );
      case QuestionType.multiStep:
        return _valueAnswer(raw) ??
            const UnscorableAnswer('Réponse en plusieurs étapes illisible.');
      case QuestionType.solutionSet:
        return _solutionSet(raw);
      case QuestionType.factorization:
        return _factorization(raw);
      case QuestionType.unknown:
        return const UnscorableAnswer('Type de question inconnu.');
    }
  }

  /// Entier, texte, liste d'entiers ou champs nommés.
  Answer? _valueAnswer(Object? raw) {
    if (AnswerAtom.fromJson(raw) case final atom?) return ScalarAnswer(atom);
    if (raw is List) {
      final ints = raw.whereType<num>().map((value) => value.toInt()).toList();
      return ints.length == raw.length && ints.isNotEmpty
          ? MultisetAnswer(ints)
          : null;
    }
    final map = _map(raw);
    if (map == null || map.isEmpty) return null;
    final fields = <String, Answer>{};
    for (final entry in map.entries) {
      final value = _valueAnswer(entry.value);
      if (value == null || value is FieldsAnswer) return null;
      fields[entry.key] = value;
    }
    return FieldsAnswer(fields);
  }

  VerdictAnswer? _verdict(Object? raw) {
    if (raw is bool) return VerdictAnswer(yes: raw);
    final text = _string(raw);
    if (text == null) return null;
    return switch (normalizeKey(text)) {
      'oui' || 'yes' => const VerdictAnswer(yes: true),
      'non' || 'no' => const VerdictAnswer(yes: false),
      _ => null,
    };
  }

  static final _congruence = RegExp(
    r'^\s*([a-zA-Z])\s*≡\s*(-?\d+)\s*[\(\[]\s*(?:mod\s*)?(\d+)\s*[\)\]]\s*$',
  );

  Answer _solutionSet(Object? raw) {
    if (raw is! List || raw.isEmpty) {
      return const UnscorableAnswer('Ensemble de solutions illisible.');
    }
    if (raw.every((value) => value is num)) {
      final values = {for (final value in raw) (value as num).toInt()};
      if (values.length != raw.length) {
        return const UnscorableAnswer('Solutions en double dans le pack.');
      }
      return IntegerSetAnswer(values);
    }
    int? modulus;
    String? variable;
    final residues = <int>{};
    for (final value in raw) {
      final match = value is String ? _congruence.firstMatch(value) : null;
      if (match == null) {
        return UnscorableAnswer('Solution « $value » non reconnue.');
      }
      final m = int.parse(match.group(3)!);
      if ((modulus != null && m != modulus) || m <= 0) {
        return const UnscorableAnswer('Modules différents dans les solutions.');
      }
      modulus = m;
      variable = match.group(1);
      residues.add(int.parse(match.group(2)!) % m);
    }
    return CongruenceSetAnswer(
      modulus: modulus!,
      residues: residues,
      variable: variable ?? 'n',
    );
  }

  Answer _factorization(Object? raw) {
    final map = _map(raw);
    if (map == null || map.isEmpty) {
      return const UnscorableAnswer('Décomposition illisible.');
    }
    final exponents = <int, int>{};
    for (final entry in map.entries) {
      final prime = int.tryParse(entry.key);
      final exponent = (entry.value as num?)?.toInt();
      if (prime == null || exponent == null || exponent < 1) {
        return UnscorableAnswer(
          'Facteur « ${entry.key} » ou exposant illisible.',
        );
      }
      if (!isPrime(prime)) {
        return UnscorableAnswer('Le facteur $prime n\'est pas premier.');
      }
      exponents[prime] = exponent;
    }
    return FactorizationAnswer(exponents);
  }

  // ── Anomalies de source ───────────────────────────────────────────────

  ValidationReport _validation(
    Map<String, Object?>? raw,
    String packId,
    _IssueSink issue,
  ) {
    if (raw == null) {
      issue(
        ContentIssueSeverity.error,
        'pack_validation_missing',
        'Le rapport de validation est absent : le pack n\'est pas vérifié.',
      );
      return ValidationReport.missing;
    }
    final reportPackId = _string(raw['pack_id']);
    if (reportPackId != null && reportPackId != packId) {
      issue(
        ContentIssueSeverity.warning,
        'validation_pack_mismatch',
        'Le rapport porte sur « $reportPackId », pas sur « $packId ».',
      );
    }
    final checks = [
      for (final item in (raw['automated_checks'] as List?) ?? const [])
        if (_map(item) case final map?)
          ValidationCheck(
            name: _string(map['check']) ?? '',
            passed: map['passed'] == true,
            details: _string(map['details']),
          ),
    ];
    for (final check in checks.where((check) => !check.passed)) {
      issue(
        ContentIssueSeverity.warning,
        'validation_check_failed',
        'Contrôle « ${check.name} » en échec dans le rapport.',
      );
    }
    final flags = [
      for (final item in (raw['source_quality_flags'] as List?) ?? const [])
        if (_map(item) case final map?)
          ValidationFlag(
            severity: ValidationSeverity.fromKey(_string(map['severity'])),
            source: _string(map['source']) ?? '',
            sourcePage: _pageOf(_string(map['source'])),
            issue: _string(map['issue']) ?? '',
            runtimeAction: _string(map['runtime_action']),
            questionIds: _stringList(map['question_ids']).toSet(),
          ),
    ];
    final status = _string(raw['status']) ?? 'UNKNOWN';
    if (status.toUpperCase().contains('FAIL')) {
      issue(
        ContentIssueSeverity.error,
        'pack_validation_failed',
        'Le rapport de validation est « $status ».',
      );
    }
    return ValidationReport(
      status: status,
      checks: checks,
      flags: flags,
      questionCount: (raw['question_count'] as num?)?.toInt(),
      gameCount: (raw['game_count'] as num?)?.toInt(),
    );
  }

  static final _pagePattern = RegExp(r'page_\d+\.\w+');

  String? _pageOf(String? source) =>
      source == null ? null : _pagePattern.firstMatch(source)?.group(0);

  /// Rattache chaque anomalie aux questions qu'elle concerne.
  ///
  /// Les identifiants explicites (`question_ids`) priment. À défaut, le
  /// rapport ne nomme qu'une page : l'anomalie accompagne alors toutes les
  /// questions ancrées sur cette page — plus large, jamais plus étroit — et
  /// l'imprécision est signalée à l'équipe de contenu.
  List<Question> _attachFlags(
    List<Question> questions,
    List<ValidationFlag> flags,
    _IssueSink issue,
  ) {
    if (flags.isEmpty) return questions;
    final attached = <String, List<ValidationFlag>>{};
    for (final flag in flags) {
      final targets = flag.questionIds.isNotEmpty
          ? questions.where((q) => flag.questionIds.contains(q.id))
          : questions.where(
              (q) =>
                  flag.sourcePage != null && q.sourceAnchor == flag.sourcePage,
            );
      if (flag.questionIds.isEmpty) {
        issue(
          ContentIssueSeverity.info,
          'validation_flag_page_level',
          'L\'anomalie « ${flag.source} » ne nomme aucune question : elle est '
              'rattachée aux ${targets.length} questions de '
              '${flag.sourcePage ?? 'cette source'}. Ajoutez `question_ids` '
              'pour la cibler.',
        );
      }
      if (targets.isEmpty) {
        issue(
          ContentIssueSeverity.warning,
          'validation_flag_unattached',
          'L\'anomalie « ${flag.source} » ne vise aucune question du pack.',
        );
      }
      for (final question in targets) {
        attached.putIfAbsent(question.id, () => []).add(flag);
      }
    }
    return [
      for (final question in questions)
        attached[question.id] == null
            ? question
            : question.withFlags(List.unmodifiable(attached[question.id]!)),
    ];
  }

  // ── Jeux, Compagnon, maîtrise ─────────────────────────────────────────

  List<GameBlueprint> _games(
    Map<String, Object?> runtime,
    Map<String, Concept> concepts,
    List<DifficultyLevel> difficulties,
    List<Question> integrationQuestions,
    _IssueSink issue,
  ) {
    final maxLevel = difficulties.isEmpty ? 3 : difficulties.last.value;
    final games = <GameBlueprint>[];
    for (final (index, item)
        in ((runtime['games'] as List?) ?? const []).indexed) {
      final map = _map(item);
      final id = _string(map?['id']);
      if (map == null || id == null) {
        issue(
          ContentIssueSeverity.warning,
          'game_without_id',
          'Jeu n°$index sans identifiant : ignoré.',
          'runtime.games[$index]',
        );
        continue;
      }
      final conceptId = _string(map['concept']) ?? '';
      final concept = concepts[conceptId];
      if (concept == null) {
        issue(
          ContentIssueSeverity.info,
          'game_concept_unknown',
          'Le jeu « $id » vise « $conceptId », qui n\'est pas une notion de '
              'la pédagogie.',
          'runtime.games[$id]',
        );
      }
      final levels = <int, String>{};
      _map(map['difficulty'])?.forEach((key, value) {
        final level = int.tryParse(key);
        if (level != null) levels[level] = _string(value) ?? '';
      });
      // Le moteur vient d'un champ explicite `engine`, ou de la primitive
      // visuelle de la notion visée. Jamais d'un texte libre de mécanique :
      // « carton » dans une mini-aventure ne fait pas un jeu de regroupement.
      final engine =
          GameEngineKind.fromKey(_string(map['engine'])) ??
          (concept == null
              ? _integrationEngine(conceptId, integrationQuestions)
              : GameEngineKind.forVisual(concept.visualKind));
      if (engine == null) {
        issue(
          ContentIssueSeverity.info,
          'game_engine_unavailable',
          'Aucun moteur de jeu ne sait encore jouer « $id ».',
          'runtime.games[$id]',
        );
      }
      games.add(
        GameBlueprint(
          id: id,
          title: _string(map['title']) ?? id,
          conceptId: conceptId,
          mechanic: _string(map['mechanic']) ?? '',
          levels: Map.unmodifiable(
            Map.fromEntries(
              levels.entries.toList()..sort((a, b) => a.key - b.key),
            ),
          ),
          scoring: ScoringRule.parse(
            _string(map['scoring']),
            maxLevel: maxLevel,
          ),
          engine: engine,
          status:
              GameStatus.fromKey(_string(map['status'])) ??
              (engine == null ? GameStatus.draft : GameStatus.ready),
        ),
      );
    }
    return games;
  }

  /// Un jeu qui vise le chapitre entier (convention `…integration…`) et
  /// dont le chapitre porte des activités d'intégration notables devient une
  /// mission d'intégration. Le champ explicite `engine` reste préférable.
  GameEngineKind? _integrationEngine(
    String conceptId,
    List<Question> integrationQuestions,
  ) =>
      normalizeKey(conceptId).contains('integration') &&
          integrationQuestions.isNotEmpty
      ? GameEngineKind.integrationMission
      : null;

  CompanionConfig _companion(Map<String, Object?>? map, _IssueSink issue) {
    if (map == null) return CompanionConfig.defaults;
    final labels = _stringList(map['quick_actions']);
    if (labels.isEmpty) return CompanionConfig.defaults;
    final actions = <CompanionAction>[];
    final unknown = <String>[];
    for (final label in labels) {
      final action = CompanionAction.fromLabel(label);
      if (action == null) {
        unknown.add(label);
        issue(
          ContentIssueSeverity.info,
          'companion_action_unknown',
          'Action du Compagnon « $label » non reconnue : ignorée.',
        );
      } else if (!actions.contains(action)) {
        actions.add(action);
      }
    }
    final fallback = _string(map['fallback']);
    final suggestions = int.tryParse(
      RegExp(r'(\d+)').firstMatch(fallback ?? '')?.group(1) ??
          _numberWord(fallback) ??
          '',
    );
    return CompanionConfig(
      actions: actions,
      unrecognizedLabels: unknown,
      fallbackSuggestions: suggestions ?? 3,
    );
  }

  String? _numberWord(String? text) {
    if (text == null) return null;
    final key = normalizeKey(text);
    for (final (word, value) in const [
      ('deux', '2'),
      ('trois', '3'),
      ('quatre', '4'),
      ('cinq', '5'),
      ('two', '2'),
      ('three', '3'),
    ]) {
      if (key.contains(word)) return value;
    }
    return null;
  }

  MasteryConfig _mastery(Map<String, Object?>? map) {
    if (map == null) return const MasteryConfig();
    int? read(String key) => (map[key] as num?)?.toInt();
    final range = map['concept_score_range'];
    return MasteryConfig(
      scoreMin: range is List && range.length == 2
          ? (range.first as num?)?.toInt() ?? 0
          : 0,
      scoreMax: range is List && range.length == 2
          ? (range.last as num?)?.toInt() ?? 100
          : 100,
      unlockNextLessonAt: read('unlock_next_lesson_at') ?? 70,
      suggestHarderAfterConsecutiveCorrect:
          read('suggest_harder_level_after_consecutive_correct') ?? 3,
      showSimpleAfterErrors: read('show_simple_after_errors') ?? 2,
      showUltraSimpleAfterAdditionalErrors:
          read('show_ultra_simple_after_additional_error') ?? 1,
    );
  }

  // ── Cohérence globale ─────────────────────────────────────────────────

  void _checkManifest(
    Map<String, Object?> manifest,
    List<Lesson> lessons,
    List<Question> questions,
    List<GameBlueprint> games,
    _IssueSink issue,
  ) {
    final stats = _map(manifest['stats']);
    if (stats == null) return;
    for (final (key, actual) in [
      ('lessons', lessons.length),
      ('runtime_questions', questions.length),
      ('games', games.length),
    ]) {
      final declared = (stats[key] as num?)?.toInt();
      if (declared != null && declared != actual) {
        issue(
          ContentIssueSeverity.warning,
          'manifest_count_mismatch',
          'Le manifeste annonce $declared pour « $key », le pack en contient '
              '$actual.',
          'manifest.stats.$key',
        );
      }
    }
  }

  void _checkLearningPath(
    Map<String, Object?> pedagogy,
    Map<String, Concept> concepts,
    _IssueSink issue,
  ) {
    for (final id in _stringList(pedagogy['learning_path'])) {
      if (!concepts.containsKey(id)) {
        issue(
          ContentIssueSeverity.warning,
          'learning_path_unknown_concept',
          'Le parcours cite « $id », absente des notions.',
          'pedagogy.learning_path',
        );
      }
    }
  }

  // ── Lecture tolérante ─────────────────────────────────────────────────

  static Map<String, Object?>? _map(Object? raw) =>
      raw is Map ? raw.map((key, value) => MapEntry('$key', value)) : null;

  static String? _string(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _stringList(Object? raw) =>
      raw is List ? [for (final value in raw) ?_string(value)] : const [];
}

typedef _IssueSink =
    void Function(
      ContentIssueSeverity severity,
      String code,
      String message, [
      String? path,
    ]);

/// Primalité exacte (division d'essai jusqu'à √n).
bool isPrime(int n) {
  if (n < 2) return false;
  if (n % 2 == 0) return n == 2;
  for (var d = 3; d * d <= n; d += 2) {
    if (n % d == 0) return false;
  }
  return true;
}
