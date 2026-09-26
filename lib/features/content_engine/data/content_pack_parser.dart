import '../../../core/academics/class_key.dart';
import '../domain/chapter.dart';
import '../domain/companion_action.dart';
import '../domain/content_issue.dart';
import '../domain/curriculum.dart';
import '../domain/game_blueprint.dart';
import '../domain/mastery.dart';
import '../domain/math_text.dart';
import '../domain/pack_catalog.dart';
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
  ///
  /// Les versions récentes ajoutent des champs (plusieurs notions par
  /// leçon, indices gradués, identifiants de propositions, nouveaux types de
  /// réponse) ; elles ne retirent rien : v1 reste lisible.
  static const supportedMajors = <String, int>{
    'source': 2,
    'pedagogy': 3,
    'runtime-learning-pack': 2,
    'validation-report': 3,
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
    final requiredEngine = [
      (raw.manifest['minimum_engine_version'] as num?)?.toInt() ?? 0,
      (runtimeMap['engine_version_required'] as num?)?.toInt() ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    if (requiredEngine > kContentEngineVersion) {
      issue(
        ContentIssueSeverity.error,
        'pack_engine_too_old',
        'Le pack demande le moteur v$requiredEngine ; celui-ci est en '
            'v$kContentEngineVersion.',
      );
    }

    final curriculum = _curriculum(
      _map(runtimeMap['curriculum']) ?? _map(source['curriculum']),
      issue,
    );
    final contentId =
        _string(source['content_id']) ??
        _string(pedagogy['content_id']) ??
        _string(raw.manifest['content_id']) ??
        _string(raw.manifest['id']) ??
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
    var questions = _questions(
      runtimeMap,
      lessons,
      concepts,
      difficulties,
      issue,
    );
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
      explanationLabels: {
        for (final MapEntry(:key, :value)
            in (_map(pedagogy['explanation_axis']) ?? const {}).entries)
          if ((ExplanationMode.fromKey(key), _string(_map(value)?['label']))
              case (final mode?, final label?))
            mode: label,
      },
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
          _string(raw.manifest['id']) ??
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
    // Programmes en modules et units (anglais) ou en modules et séquences
    // (physique) : l'unit ou la séquence tient lieu de chapitre dans son
    // module.
    final unit = _int(map?['unit']);
    final sequence = _int(map?['sequence']);
    return Curriculum(
      country: _string(map?['country']) ?? '',
      level: _string(map?['level']) ?? '',
      subject: _string(map?['subject']) ?? '',
      module: _string(map?['module']),
      moduleNumber: _int(map?['module']),
      moduleTitle: _string(map?['module_title']),
      unitNumber: unit,
      sequenceNumber: sequence,
      chapterNumber:
          (map?['chapter_number'] as num?)?.toInt() ?? unit ?? sequence ?? 0,
      chapterTitle:
          _string(map?['chapter_title']) ??
          _string(map?['unit_title']) ??
          _string(map?['sequence_title']) ??
          '',
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
      // v1 : texte libre (primitive reconnue dans le texte). v2+ : objet
      // `{engine, description}` ; seul un moteur connu donne un visuel, un
      // moteur inconnu n'est jamais deviné.
      final visualObject = _map(map['visual_model']);
      final visualModel =
          _string(map['visual_model']) ?? _string(visualObject?['description']);
      final explicitKind =
          VisualKind.fromKey(_string(map['visual_kind'])) ??
          (visualObject == null
              ? null
              : VisualKind.fromKey(_string(visualObject['engine'])) ??
                    VisualKind.none);
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
    // v1 : `chapter_map` ; v2 : `source_sections`.
    final chapterMap = source['chapter_map'] ?? source['source_sections'];
    if (chapterMap is List) {
      for (final item in chapterMap) {
        final map = _map(item);
        final number = (map?['lesson'] as num?)?.toInt();
        if (map != null && number != null) provenance[number] = map;
      }
    }
    final lessons = <Lesson>[];
    final refs = runtime['lesson_refs'] ?? runtime['lessons'];
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
        final conceptIds = [
          ..._stringList(map['concept_ids']),
          ?_string(map['concept_id']),
        ];
        for (final conceptId in conceptIds) {
          if (concepts.containsKey(conceptId)) continue;
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
            conceptIds: List.unmodifiable(conceptIds),
            verifiedCore: _stringList(
              origin?['verified_core'] ?? origin?['verified_content'],
            ),
            sourceSituation: _string(origin?['source_situation']),
            sourcePages: _stringList(
              origin?['images'] ?? origin?['source_ranges'],
            ),
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
    Map<String, Concept> concepts,
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
      final options = _options(map);
      final choices = options.choices;
      final prompt = _string(map['prompt']);
      String? disabled;
      void disable(
        String code,
        String message, {
        ContentIssueSeverity severity = ContentIssueSeverity.error,
      }) {
        issue(severity, code, message, path);
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
      // Réponse rédigée assumée par le pack : elle n'est pas notée par le
      // moteur, sans que ce soit une anomalie.
      final manual = map['auto_score'] == false;
      if (manual) {
        disable(
          'question_not_auto_scored',
          'Réponse rédigée : question non notée par le moteur.',
          severity: ContentIssueSeverity.info,
        );
      }
      final conceptId = _string(map['concept_id']);
      if (conceptId != null && !concepts.containsKey(conceptId)) {
        issue(
          ContentIssueSeverity.warning,
          'question_concept_unknown',
          'La question vise la notion « $conceptId », absente de la '
              'pédagogie.',
          path,
        );
      }
      var answer = _answer(
        type,
        map['answer'],
        choices,
        accepted: _stringList(map['accepted_answers']),
      );
      // Les identifiants de propositions, quand le pack en donne, doivent
      // désigner exactement la réponse : sinon la correction est douteuse.
      if (options.correctLabels case final labels?
          when answer is! UnscorableAnswer) {
        final consistent = switch (answer) {
          ChoiceAnswer(:final choice) =>
            labels.length == 1 && labels.first == choice,
          MultiChoiceAnswer(:final choices) =>
            labels.toSet().containsAll(choices) && choices.containsAll(labels),
          _ => true,
        };
        if (!consistent) {
          answer = const UnscorableAnswer(
            'Les identifiants de la bonne proposition ne correspondent pas à '
            'la réponse.',
          );
        }
      }
      if (answer is UnscorableAnswer &&
          type != QuestionType.unknown &&
          !manual) {
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
          hints: _hints(map),
          disabledReason: disabled,
          conceptId: conceptId,
          choiceFeedback: options.feedback,
        ),
      );
    }
    return questions;
  }

  /// Indices : textes (v1) ou objets `{level, content}` rangés par niveau.
  List<String> _hints(Map<String, Object?> map) {
    final graded = <(int, String)>[];
    final texts = <String>[];
    for (final item in (map['hints'] as List?) ?? const []) {
      if (_string(item) case final text?) {
        texts.add(text);
      } else if (_map(item) case final hint?) {
        final content = _string(hint['content']) ?? _string(hint['text']);
        if (content != null) {
          graded.add(((hint['level'] as num?)?.toInt() ?? 99, content));
        }
      }
    }
    graded.sort((a, b) => a.$1.compareTo(b.$1));
    return [
      ...texts,
      for (final (_, text) in graded) text,
      ?_string(map['hint']),
    ];
  }

  /// Propositions d'un QCM : `choices` (v1) ou `option_metadata` (v2+), avec
  /// le retour propre à chaque proposition et, s'ils existent, les libellés
  /// désignés par `correct_option_ids`.
  ({
    List<AnswerAtom> choices,
    Map<AnswerAtom, String> feedback,
    List<AnswerAtom>? correctLabels,
  })
  _options(Map<String, Object?> map) {
    final choices = [
      for (final choice in (map['choices'] as List?) ?? const [])
        ?AnswerAtom.fromJson(choice),
    ];
    final byId = <String, AnswerAtom>{};
    final feedback = <AnswerAtom, String>{};
    for (final item in (map['option_metadata'] as List?) ?? const []) {
      final option = _map(item);
      final label = AnswerAtom.fromJson(option?['label']);
      if (option == null || label == null) continue;
      if (_string(option['id']) case final id?) byId[id] = label;
      if (_string(option['feedback']) case final text?) feedback[label] = text;
      if (!choices.contains(label)) choices.add(label);
    }
    final ids = _stringList(map['correct_option_ids']);
    return (
      choices: List.unmodifiable(choices),
      feedback: Map.unmodifiable(feedback),
      correctLabels: ids.isEmpty
          ? null
          : [for (final id in ids) byId[id] ?? AnswerAtom.text('?$id')],
    );
  }

  Answer _answer(
    QuestionType type,
    Object? raw,
    List<AnswerAtom> choices, {
    List<String> accepted = const [],
  }) {
    switch (type) {
      case QuestionType.numeric || QuestionType.multiStep:
        if (raw is String && _isProse(raw)) {
          return const UnscorableAnswer(
            'Réponse rédigée : le moteur ne la corrige pas seul.',
          );
        }
        return _valueAnswer(raw) ??
            UnscorableAnswer(
              type == QuestionType.numeric
                  ? 'Réponse numérique illisible.'
                  : 'Réponse en plusieurs étapes illisible.',
            );
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
        // Oui/non ; sinon une réponse courte à la forme sûre (intervalle,
        // formule d'un seul bloc). Une phrase reste une réponse rédigée.
        if (_verdict(raw) case final verdict?) return verdict;
        final text = _string(raw);
        if (text != null && !_isProse(text)) {
          if (parseInterval(text) case final interval?) {
            return IntervalAnswer(
              lower: interval.lower,
              upper: interval.upper,
              lowerClosed: interval.lowerClosed,
              upperClosed: interval.upperClosed,
              display: text,
            );
          }
          if (!RegExp(r'\s').hasMatch(text)) return ExpressionAnswer(text);
        }
        return const UnscorableAnswer(
          'Réponse rédigée : le moteur ne corrige pas une phrase seul.',
        );
      case QuestionType.solutionSet:
        return _solutionSet(raw);
      case QuestionType.factorization:
        return _factorization(raw);
      case QuestionType.complexParts:
        final parts = _complex(raw);
        if (parts == null) {
          return const UnscorableAnswer(
            'Parties réelle et imaginaire illisibles.',
          );
        }
        return FieldsAnswer({
          're': _realAnswer(parts.re),
          'im': _realAnswer(parts.im),
        });
      case QuestionType.complexNumber:
        final value = _complex(raw);
        if (value == null) {
          return const UnscorableAnswer('Nombre complexe illisible.');
        }
        return ComplexAnswer(value.re, value.im, acceptedTexts: accepted);
      case QuestionType.solutionSetComplex:
        return _complexSet(raw) ??
            const UnscorableAnswer('Solutions complexes illisibles.');
      case QuestionType.numericRadical:
        final map = _map(raw);
        final exact = _string(map?['exact']) ?? _string(raw);
        final value = exact == null ? null : evaluateRadical(exact);
        final approx = (map?['approx'] as num?)?.toDouble();
        if (exact == null || value == null) {
          return const UnscorableAnswer('Valeur exacte illisible.');
        }
        if (approx != null && !nearlyEqual(value, approx, tolerance: 1e-6)) {
          return UnscorableAnswer(
            'La valeur exacte « $exact » ne vaut pas $approx.',
          );
        }
        return RadicalAnswer(exact: exact, value: value);
      case QuestionType.numericApprox:
        if (raw is! num) {
          return const UnscorableAnswer('Valeur approchée illisible.');
        }
        // « 0.68 » : précision du dernier chiffre écrit, soit ±0,005.
        final decimals =
            raw.toString().split('.').elementAtOrNull(1)?.length ?? 0;
        return DecimalAnswer(
          raw.toDouble(),
          tolerance: 0.5 * _pow10(-decimals) + 1e-12,
        );
      case QuestionType.interval:
        final text = _string(raw);
        final interval = text == null ? null : parseInterval(text);
        if (interval == null) {
          return const UnscorableAnswer('Intervalle illisible.');
        }
        return IntervalAnswer(
          lower: interval.lower,
          upper: interval.upper,
          lowerClosed: interval.lowerClosed,
          upperClosed: interval.upperClosed,
          display: text!,
        );
      case QuestionType.expression:
        final text = _string(raw);
        return text == null
            ? const UnscorableAnswer('Expression illisible.')
            : ExpressionAnswer(text);
      case QuestionType.multiAnswer:
        final texts = _stringList(raw);
        return texts.isEmpty || texts.length != ((raw as List?)?.length ?? 0)
            ? const UnscorableAnswer('Réponses multiples illisibles.')
            : ExpressionSetAnswer(texts);
      case QuestionType.unknown:
        return const UnscorableAnswer('Type de question inconnu.');
    }
  }

  /// Une phrase (au moins trois mots) n'est pas une valeur à comparer.
  static bool _isProse(String text) =>
      RegExp(r'\s+').allMatches(text.trim()).length >= 2;

  static double _pow10(int exponent) {
    var value = 1.0;
    for (var i = 0; i < exponent.abs(); i++) {
      value = exponent < 0 ? value / 10 : value * 10;
    }
    return value;
  }

  /// Un réel du pack : entier, décimal ou fraction écrite (« 2/5 »).
  static double? _real(Object? raw) => switch (raw) {
    final num value => value.toDouble(),
    final String text => parseRealNumber(text),
    _ => null,
  };

  static Answer _realAnswer(double value) =>
      value == value.roundToDouble() && value.abs() < 1e15
      ? ScalarAnswer(AnswerAtom.integer(value.toInt()))
      : DecimalAnswer(value);

  /// `{re, im}` → nombre complexe.
  static ({double re, double im})? _complex(Object? raw) {
    final map = _map(raw);
    if (map == null) return null;
    final re = _real(map['re']);
    final im = _real(map['im']);
    return re == null || im == null ? null : (re: re, im: im);
  }

  static ComplexSetAnswer? _complexSet(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    final values = <ComplexAnswer>[];
    for (final item in raw) {
      final value = _complex(item);
      if (value == null) return null;
      values.add(ComplexAnswer(value.re, value.im));
    }
    return ComplexSetAnswer(values);
  }

  /// Entier, décimal, texte, liste d'entiers, complexe, radical, ou champs
  /// nommés (dont les valeurs peuvent être complexes).
  Answer? _valueAnswer(Object? raw, {bool nested = false}) {
    if (raw is num && raw != raw.roundToDouble()) {
      return DecimalAnswer(raw.toDouble());
    }
    if (raw is String) {
      final text = raw.trim();
      if (text.contains('√') && evaluateRadical(text) != null) {
        return RadicalAnswer(exact: text, value: evaluateRadical(text)!);
      }
      final complex = text.contains('i') ? parseComplex(text) : null;
      if (complex != null) return ComplexAnswer(complex.re, complex.im);
    }
    if (AnswerAtom.fromJson(raw) case final atom?) return ScalarAnswer(atom);
    if (raw is List) {
      if (_complexSet(raw) case final set?) return set;
      final ints = raw.whereType<num>().map((value) => value.toInt()).toList();
      return ints.length == raw.length && ints.isNotEmpty
          ? MultisetAnswer(ints)
          : null;
    }
    final map = _map(raw);
    if (map == null || map.isEmpty) return null;
    final complex = map.length == 2 ? _complex(map) : null;
    if (complex != null) return ComplexAnswer(complex.re, complex.im);
    if (nested) return null;
    final fields = <String, Answer>{};
    for (final entry in map.entries) {
      final value = _valueAnswer(entry.value, nested: true);
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
    // Solutions écrites (ex. « 1−√2 », « 1+√2 ») : comparées une à une,
    // sans ordre, après normalisation.
    if (raw.every((value) => value is String) &&
        !raw.any((value) => _congruence.hasMatch(value as String))) {
      return ExpressionSetAnswer([for (final value in raw) value as String]);
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
            source:
                _string(map['source']) ??
                _stringList(map['source_pages']).join(', ').emptyAsNull ??
                _string(map['id']) ??
                '',
            sourcePage:
                _pageOf(_string(map['source'])) ??
                _stringList(map['source_pages']).firstOrNull,
            issue: _string(map['issue']) ?? '',
            runtimeAction: _string(map['runtime_action']),
            questionIds: _stringList(map['question_ids']).toSet(),
            // `question_ids: []` écrit explicitement : l'anomalie concerne des
            // pages de la source qui n'ont produit aucune question du pack.
            concernsRuntime:
                map['question_ids'] is! List ||
                (map['question_ids'] as List).isNotEmpty,
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
      if (!flag.concernsRuntime) {
        issue(
          ContentIssueSeverity.info,
          'validation_flag_source_only',
          'L\'anomalie « ${flag.source} » ne vise aucune question du pack '
              '(source non reprise).',
        );
        continue;
      }
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
      final conceptId =
          _string(map['concept']) ?? _string(map['concept_id']) ?? '';
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
      // Un moteur nommé mais inconnu n'est jamais remplacé par un autre :
      // le jeu reste en préparation plutôt que de devenir un faux jeu.
      final declaredEngine =
          _string(map['engine']) ?? _string(map['engine_blueprint']);
      final engine = declaredEngine != null
          ? GameEngineKind.fromKey(declaredEngine)
          : concept == null
          ? _integrationEngine(conceptId, integrationQuestions)
          : GameEngineKind.forVisual(concept.visualKind);
      final declaredStatus = GameStatus.fromKey(_string(map['status']));
      if (engine == null && declaredStatus == GameStatus.ready) {
        issue(
          ContentIssueSeverity.warning,
          'game_ready_without_engine',
          'Le jeu « $id » est déclaré prêt mais aucun moteur « '
              '${declaredEngine ?? '?'} » n\'existe : il reste en préparation.',
          'runtime.games[$id]',
        );
      }
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
          status: engine == null
              ? GameStatus.draft
              : declaredStatus ?? GameStatus.ready,
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
    final packLabels = <CompanionAction, String>{};
    for (final label in labels) {
      final action = CompanionAction.fromLabel(label);
      if (action != null) packLabels.putIfAbsent(action, () => label);
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
    final fallback =
        _string(map['fallback']) ??
        _string(_map(map['free_text_routing'])?['fallback']);
    final suggestions = int.tryParse(
      RegExp(r'(\d+)').firstMatch(fallback ?? '')?.group(1) ??
          _numberWord(fallback) ??
          '',
    );
    return CompanionConfig(
      actions: actions,
      unrecognizedLabels: unknown,
      fallbackSuggestions: suggestions ?? 3,
      labels: Map.unmodifiable(packLabels),
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
          read('suggest_harder_level_after_consecutive_correct') ??
          read('suggest_harder_after_consecutive_correct') ??
          3,
      showSimpleAfterErrors:
          read('show_simple_after_errors') ??
          read('suggest_simple_after_errors') ??
          2,
      showUltraSimpleAfterAdditionalErrors:
          read('show_ultra_simple_after_additional_error') ??
          read('suggest_ultra_simple_after_additional_error') ??
          1,
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
      ('questions', questions.length),
      ('games', games.length),
      ('game_blueprints', games.length),
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

  /// Un entier, seulement s'il est écrit comme un nombre (un module peut
  /// aussi être un intitulé).
  static int? _int(Object? raw) => raw is num ? raw.toInt() : null;

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

extension on String {
  String? get emptyAsNull => isEmpty ? null : this;
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
