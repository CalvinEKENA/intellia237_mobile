import 'package:flutter/foundation.dart';

import '../../quiz/domain/pack_quiz.dart' show stableHash;
import 'companion_conversation_state.dart';
import 'companion_dialogue_bank.dart';
import 'companion_reply_action.dart';
import 'companion_study_context.dart';
import 'companion_text.dart';

/// Une réponse du compagnon : un texte court, des actions réelles, et la
/// mémoire de conversation mise à jour.
@immutable
class CompanionReply {
  const CompanionReply({
    required this.text,
    required this.responseKey,
    required this.intent,
    required this.actions,
    required this.state,
  });

  final String text;

  /// Clé de la banque utilisée (ex. `want_quiz_subject`).
  final String responseKey;

  /// Intention reconnue (ex. `want_quiz`).
  final String intent;
  final List<CompanionReplyAction> actions;
  final CompanionConversationState state;
}

/// Ordre de préférence entre intentions de même poids : l'honnêteté et le
/// soutien passent avant la politesse.
const _priority = [
  'are_you_ai',
  'who_are_you',
  'self_doubt',
  'exam_stress',
  'discouraged',
  'tired',
  'motivation',
  'dont_understand',
  'what_should_i_review',
  'ask_progress',
  'surprise_me',
  'want_quiz',
  'bored',
  'help',
  'want_to_study',
  'compliment',
  'goodbye',
  'thanks',
  'how_are_you',
  'greeting',
  'decline',
  'affirm',
];

/// Intentions de politesse : une matière nommée dans le même message passe
/// devant (« Bonjour, on fait des maths ? »).
const _social = {'greeting', 'how_are_you', 'thanks', 'compliment', 'affirm'};

/// Moteur de conversation déterministe de Kira et Léo.
///
/// message → normalisation → intention → contexte local → variante choisie
/// sans hasard → réponse et actions. Aucun réseau, aucun modèle de langage :
/// le compagnon ne répond qu'avec la banque de dialogues et les données
/// réelles de l'élève, et réoriente honnêtement ce qu'il ne sait pas.
class DeterministicCompanionEngine {
  const DeterministicCompanionEngine();

  CompanionReply respond({
    required String message,
    required CompanionStudyContext context,
    required CompanionDialogueBank bank,
    required String personaId,
    CompanionConversationState state = CompanionConversationState.initial,
    String? lessonContext,
  }) {
    final text = normalizeCompanionText(
      message,
      replacements: bank.normalization,
    );
    final turn = _Turn(
      engine: this,
      text: text,
      context: context,
      bank: bank,
      personaId: personaId,
      state: state,
    );
    return turn.resolve(lessonContext);
  }

  /// Le commentaire d'un quiz qui vient d'être terminé, s'il existe.
  CompanionReply quizReturn({
    required CompanionQuizResult result,
    required CompanionStudyContext context,
    required CompanionDialogueBank bank,
    required String personaId,
    CompanionConversationState state = CompanionConversationState.initial,
  }) {
    final turn = _Turn(
      engine: this,
      text: 'quiz ${result.setId} ${result.completedAt.toIso8601String()}',
      context: context,
      bank: bank,
      personaId: personaId,
      state: state,
    );
    final key = result.ratio >= 0.8
        ? 'quiz_return_high'
        : result.ratio >= 0.5
        ? 'quiz_return_mid'
        : 'quiz_return_low';
    final subject = context.subject(result.subjectKey);
    final actions = [
      CompanionReplyAction(
        kind: CompanionActionKind.openQuiz,
        label: CompanionActionLabel.retryQuiz,
        setId: result.setId,
        mode: result.mode,
        subjectKey: result.subjectKey,
        subjectTitle: subject?.title,
      ),
      if (result.mode == 'evaluation')
        CompanionReplyAction(
          kind: CompanionActionKind.openQuiz,
          label: CompanionActionLabel.trainTopic,
          setId: result.setId,
          mode: 'training',
          subjectKey: result.subjectKey,
          subjectTitle: subject?.title,
        ),
      if (result.contentId case final contentId?)
        CompanionReplyAction(
          kind: CompanionActionKind.openChapter,
          label: CompanionActionLabel.continueCourse,
          contentId: contentId,
          subjectKey: result.subjectKey,
        )
      else
        CompanionReplyAction(
          kind: CompanionActionKind.openSubject,
          label: CompanionActionLabel.continueCourse,
          subjectKey: result.subjectKey,
          subjectTitle: subject?.title,
        ),
    ];
    return turn.reply(
      intent: 'quiz_return',
      key: key,
      values: {'score': '${result.score}', 'total': '${result.total}'},
      actions: actions,
      subjectKey: result.subjectKey,
      countTurn: false,
    );
  }

  /// Suggestions du composeur, selon ce que l'élève peut réellement faire.
  List<String> suggestions({
    required CompanionStudyContext context,
    required CompanionDialogueBank bank,
  }) {
    final result = <String>[];
    final quizSubjects = context.quizSubjects;
    if (context.reviewFocus != null) {
      result.add(bank.suggestions['what_to_review']!);
    }
    if (quizSubjects.isNotEmpty) result.add(bank.suggestions['quiz']!);
    final subjectKey =
        context.resume?.subjectKey ??
        context.lastQuiz?.subjectKey ??
        context.subjects.firstOrNull?.key;
    if (subjectKey != null) {
      final name = _subjectName(bank, context, subjectKey);
      result.add(
        bank.suggestions['subject']!.replaceAll('{subjectName}', name),
      );
    }
    result.add(
      context.startedConcepts > 0
          ? bank.suggestions['progress']!
          : bank.suggestions['review']!,
    );
    if (result.length < 4 && quizSubjects.length > 1) {
      result.add(bank.suggestions['surprise']!);
    }
    if (context.reviewFocus == null && result.length < 4) {
      result.add(bank.suggestions['what_to_review']!);
    }
    return result.take(4).toList();
  }
}

String _subjectName(
  CompanionDialogueBank bank,
  CompanionStudyContext context,
  String key,
) =>
    bank.subject(key)?.name ?? context.subject(key)?.title.toLowerCase() ?? key;

String _capitalize(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

class _Turn {
  _Turn({
    required this.engine,
    required this.text,
    required this.context,
    required this.bank,
    required this.personaId,
    required this.state,
  });

  final DeterministicCompanionEngine engine;
  final String text;
  final CompanionStudyContext context;
  final CompanionDialogueBank bank;
  final String personaId;
  final CompanionConversationState state;

  late final Map<String, int> scores = {
    for (final intent in companionTriggerIntents)
      intent: [
        for (final phrase in bank.triggers[intent]!)
          if (containsPhrase(text, phrase)) wordCount(phrase),
      ].fold(0, (sum, weight) => sum + weight),
  };

  /// L'intention la plus appuyée ; `null` si aucune.
  late final String? topIntent = () {
    String? best;
    var bestScore = 0;
    for (final intent in _priority) {
      final score = scores[intent] ?? 0;
      if (score > bestScore) {
        best = intent;
        bestScore = score;
      }
    }
    return best;
  }();

  /// La matière nommée : l'alias le plus long l'emporte.
  late final String? subjectKey = () {
    String? best;
    var length = 0;
    for (final subject in bank.subjects) {
      for (final alias in subject.aliases) {
        if (alias.length > length && containsPhrase(text, alias)) {
          best = subject.key;
          length = alias.length;
        }
      }
    }
    return best;
  }();

  late final bool isQuestion = bank.questionMarkers.any(
    (marker) => containsPhrase(text, marker),
  );

  CompanionReply resolve(String? lessonContext) {
    if (text.isEmpty) return _unknown();
    final intent = topIntent;
    final words = wordCount(text);

    // « oui » / « non » répondent à la dernière proposition.
    if ((intent == 'affirm' || intent == 'decline') && words <= 4) {
      if (intent == 'decline') return _plain('decline', 'decline');
      if (state.pendingActions.isNotEmpty) {
        return reply(
          intent: 'affirm',
          key: 'affirm',
          actions: state.pendingActions,
          pending: state.pendingActions,
        );
      }
      if (subjectKey == null) {
        return reply(
          intent: 'affirm',
          key: 'affirm_open',
          actions: _startActions(),
        );
      }
    }

    // Une matière seule répond à la question « Quelle matière ? ».
    final subject = subjectKey;
    if (subject != null &&
        (intent == null || _social.contains(intent)) &&
        state.awaiting != CompanionAwaiting.nothing) {
      return switch (state.awaiting) {
        CompanionAwaiting.subjectToQuiz => _quizSubject(subject),
        CompanionAwaiting.subjectToUnblock ||
        CompanionAwaiting.subjectToStudy => _subject(subject, learnFirst: true),
        CompanionAwaiting.nothing => _subject(subject),
      };
    }

    switch (intent) {
      case 'are_you_ai':
        return _plain('are_you_ai', 'are_you_ai', actions: _startActions());
      case 'who_are_you':
        return _plain('who_are_you', 'who_are_you', actions: _startActions());
      case 'self_doubt' ||
          'discouraged' ||
          'exam_stress' ||
          'tired' ||
          'motivation' ||
          'bored':
        return _support(intent!);
      case 'dont_understand':
        return _dontUnderstand(lessonContext);
      case 'what_should_i_review':
        return _review();
      case 'ask_progress':
        return _progress();
      case 'surprise_me':
        return _surprise();
      case 'want_quiz':
        final target = subject ?? state.recentSubjectKey;
        return target == null ? _quiz() : _quizSubject(target);
      case 'help':
        if (subject != null) return _subject(subject, learnFirst: true);
        return _plain('help', 'help', actions: _helpActions());
      case 'want_to_study':
        if (subject != null) return _subject(subject, learnFirst: true);
        if (_topic() case final topic?) return _topicReply(topic);
        if (state.recentSubjectKey case final recent?
            when words <= 3 && context.subject(recent) != null) {
          return _learnNow(recent);
        }
        return _study();
      case 'compliment' || 'greeting' || 'how_are_you' || 'thanks'
          when subject != null:
        return _subject(subject);
      case 'compliment':
        return _plain('compliment', 'compliment', actions: _startActions());
      case 'greeting':
        return _plain('greeting', 'greeting', actions: _startActions());
      case 'how_are_you':
        return _plain('how_are_you', 'how_are_you');
      case 'thanks':
        return _plain('thanks', 'thanks');
      case 'goodbye':
        return _plain('goodbye', 'goodbye');
      case 'decline':
        return _plain('decline', 'decline');
      case 'affirm':
        if (subject != null) return _subject(subject);
        return reply(
          intent: 'affirm',
          key: 'affirm_open',
          actions: _startActions(),
        );
    }

    if (subject != null && !isQuestion) return _subject(subject);
    if (_topic() case final topic?) return _topicReply(topic);
    if (isQuestion) {
      return _plain(
        'unsupported_freeform',
        'unsupported_freeform',
        actions: [
          if (subject != null && context.subject(subject) != null)
            ..._subjectActions(subject, learnFirst: true)
          else
            _seeSubjects,
          if (context.quizCount > 0) _seeQuizzes,
        ],
      );
    }
    if (subject != null) return _subject(subject);
    return _unknown();
  }

  CompanionReply _unknown() =>
      _plain('unknown', 'unknown', actions: _startActions());

  CompanionTopic? _topic() => matchCompanionTopic(text, context.topics);

  // ── Réponses ──────────────────────────────────────────────────────────

  CompanionReply _plain(
    String intent,
    String key, {
    List<CompanionReplyAction> actions = const [],
  }) => reply(intent: intent, key: key, actions: actions);

  CompanionReply _study() {
    if (context.resume case final resume?) {
      final resumeAction = CompanionReplyAction(
        kind: CompanionActionKind.openChapter,
        label: CompanionActionLabel.resume,
        contentId: resume.contentId,
        subjectKey: resume.subjectKey,
      );
      return reply(
        intent: 'want_to_study',
        key: 'want_to_study_resume',
        values: {
          ..._subjectValues(resume.subjectKey),
          'topicTitle': resume.title,
        },
        actions: [resumeAction, ..._subjectChips()],
        pending: [resumeAction],
        subjectKey: resume.subjectKey,
        awaiting: CompanionAwaiting.subjectToStudy,
      );
    }
    return reply(
      intent: 'want_to_study',
      key: 'want_to_study',
      actions: _subjectChips().isEmpty ? [_seeSubjects] : _subjectChips(),
      awaiting: CompanionAwaiting.subjectToStudy,
    );
  }

  /// « Cours » juste après une matière : on ouvre la matière.
  CompanionReply _learnNow(String subject) {
    final actions = _subjectActions(subject, learnFirst: true);
    return reply(
      intent: 'want_to_study',
      key: 'affirm',
      actions: actions,
      pending: actions,
      subjectKey: subject,
    );
  }

  CompanionReply _subject(String key, {bool learnFirst = false}) {
    final info = context.subject(key);
    if (info == null) {
      return reply(
        intent: 'want_subject',
        key: 'want_subject_missing',
        values: _subjectValues(key),
        actions: [..._subjectChips(), _seeSubjects],
        subjectKey: key,
      );
    }
    final actions = _subjectActions(key, learnFirst: learnFirst);
    if (!info.hasQuiz) {
      return reply(
        intent: 'want_subject',
        key: 'want_subject_no_quiz',
        values: _subjectValues(key),
        actions: actions,
        pending: actions,
        subjectKey: key,
      );
    }
    final responseKey = switch (key) {
      'mathematiques' => 'want_math',
      'anglais' => 'want_english',
      'physique' => 'want_physics',
      _ => 'want_subject',
    };
    return reply(
      intent: responseKey,
      key: responseKey,
      values: _subjectValues(key),
      actions: actions,
      pending: actions,
      subjectKey: key,
    );
  }

  CompanionReply _quiz() {
    final subjects = context.quizSubjects;
    if (subjects.isEmpty) {
      return reply(
        intent: 'want_quiz',
        key: 'want_quiz_none',
        actions: [_seeQuizzes, _seeSubjects],
      );
    }
    return reply(
      intent: 'want_quiz',
      key: 'want_quiz',
      values: {if (context.quizCount >= 2) 'quizCount': '${context.quizCount}'},
      actions: [
        for (final subject in subjects)
          CompanionReplyAction(
            kind: CompanionActionKind.openQuiz,
            label: CompanionActionLabel.subject,
            setId: subject.quizSetId,
            mode: 'training',
            subjectKey: subject.key,
            subjectTitle: subject.title,
          ),
        _seeQuizzes,
      ],
      awaiting: CompanionAwaiting.subjectToQuiz,
    );
  }

  CompanionReply _quizSubject(String key) {
    final info = context.subject(key);
    if (info == null || !info.hasQuiz) return _subject(key);
    final actions = [
      _quizAction(info, 'training', CompanionActionLabel.training),
      _quizAction(info, 'evaluation', CompanionActionLabel.evaluation),
    ];
    return reply(
      intent: 'want_quiz',
      key: 'want_quiz_subject',
      values: _subjectValues(key),
      actions: actions,
      pending: [actions.first],
      subjectKey: key,
    );
  }

  CompanionReply _support(String intent) {
    final subject = subjectKey;
    final info = subject == null ? null : context.subject(subject);
    final List<CompanionReplyAction> actions;
    var awaiting = CompanionAwaiting.nothing;
    if (info != null) {
      actions = _subjectActions(info.key, learnFirst: intent != 'bored');
    } else if (intent == 'self_doubt' || intent == 'discouraged') {
      actions = _subjectChips().isEmpty ? [_seeSubjects] : _subjectChips();
      awaiting = CompanionAwaiting.subjectToUnblock;
    } else {
      final quick = _quickQuiz(
        mode: intent == 'exam_stress' ? 'evaluation' : 'training',
        label: switch (intent) {
          'exam_stress' => CompanionActionLabel.diagnostic,
          'bored' => CompanionActionLabel.takeQuiz,
          _ => CompanionActionLabel.practice,
        },
      );
      actions = [?quick, _seeSubjects];
    }
    return reply(
      intent: intent,
      key: intent,
      actions: actions,
      pending: actions
          .where((a) => a.kind != CompanionActionKind.reply)
          .take(1)
          .toList(),
      subjectKey: info?.key,
      awaiting: awaiting,
    );
  }

  CompanionReply _dontUnderstand(String? lessonContext) {
    final lesson = lessonContext?.trim();
    if (lesson != null && lesson.isNotEmpty) {
      final topic =
          context.topics
              .where(
                (t) =>
                    normalizeCompanionText(t.title) ==
                    normalizeCompanionText(lesson),
              )
              .firstOrNull ??
          matchCompanionTopic(normalizeCompanionText(lesson), context.topics);
      final actions = [
        if (topic != null) ...[
          CompanionReplyAction(
            kind: CompanionActionKind.openChapter,
            label: CompanionActionLabel.resumeLesson,
            contentId: topic.contentId,
            lesson: topic.lesson,
            subjectKey: topic.subjectKey,
          ),
          if (topic.quizSetId case final setId?)
            CompanionReplyAction(
              kind: CompanionActionKind.openQuiz,
              label: CompanionActionLabel.practice,
              setId: setId,
              mode: 'training',
              subjectKey: topic.subjectKey,
            ),
        ] else
          _seeSubjects,
      ];
      return reply(
        intent: 'dont_understand',
        key: 'dont_understand_lesson',
        values: {'lessonTitle': lesson},
        actions: actions,
        pending: actions.take(1).toList(),
        subjectKey: topic?.subjectKey,
      );
    }
    if (subjectKey case final subject? when context.subject(subject) != null) {
      return _subject(subject, learnFirst: true);
    }
    return reply(
      intent: 'dont_understand',
      key: 'dont_understand',
      actions: _subjectChips().isEmpty ? [_seeSubjects] : _subjectChips(),
      awaiting: CompanionAwaiting.subjectToUnblock,
    );
  }

  CompanionReply _review() {
    final focus = context.reviewFocus;
    if (focus == null) {
      final quick = _quickQuiz(
        mode: 'evaluation',
        label: CompanionActionLabel.diagnostic,
      );
      return reply(
        intent: 'what_should_i_review',
        key: 'what_should_i_review_no_data',
        actions: [?quick, if (quick == null) _seeSubjects],
        pending: [?quick],
      );
    }
    final actions = [
      CompanionReplyAction(
        kind: CompanionActionKind.openChapter,
        label: CompanionActionLabel.reviewSubject,
        contentId: focus.contentId,
        lesson: focus.lesson,
        subjectKey: focus.subjectKey,
        subjectTitle: context.subject(focus.subjectKey)?.title,
      ),
      if (focus.quizSetId case final setId?)
        CompanionReplyAction(
          kind: CompanionActionKind.openQuiz,
          label: CompanionActionLabel.diagnostic,
          setId: setId,
          mode: 'training',
          subjectKey: focus.subjectKey,
        ),
    ];
    return reply(
      intent: 'what_should_i_review',
      key: 'what_should_i_review',
      values: {
        ..._subjectValues(focus.subjectKey),
        'topicTitle': focus.topicTitle,
      },
      actions: actions,
      pending: actions.take(1).toList(),
      subjectKey: focus.subjectKey,
    );
  }

  CompanionReply _progress() {
    final subject = subjectKey;
    final info = subject == null ? null : context.subject(subject);
    if (info != null) {
      if (info.started == 0) {
        return _noProgress();
      }
      return reply(
        intent: 'ask_progress',
        key: 'ask_progress_subject',
        values: {..._subjectValues(info.key), 'percent': '${info.percent}'},
        actions: [
          CompanionReplyAction(
            kind: CompanionActionKind.openSubject,
            label: CompanionActionLabel.progress,
            subjectKey: info.key,
            subjectTitle: info.title,
          ),
        ],
        subjectKey: info.key,
      );
    }
    if (context.startedConcepts == 0) return _noProgress();
    return reply(
      intent: 'ask_progress',
      key: 'ask_progress',
      values: {
        'started': '${context.startedConcepts}',
        'mastered': '${context.masteredConcepts}',
      },
      actions: [
        const CompanionReplyAction(
          kind: CompanionActionKind.showSubjects,
          label: CompanionActionLabel.progress,
        ),
      ],
    );
  }

  CompanionReply _noProgress() {
    final quick = _quickQuiz(
      mode: 'training',
      label: CompanionActionLabel.takeQuiz,
    );
    return reply(
      intent: 'ask_progress',
      key: 'ask_progress_no_data',
      actions: [?quick, if (quick == null) _seeSubjects],
      pending: [?quick],
    );
  }

  CompanionReply _surprise() {
    final subjects = context.quizSubjects;
    if (subjects.isEmpty) {
      return _plain('surprise_me', 'surprise_me_none', actions: [_seeSubjects]);
    }
    final pick =
        subjects[stableHash('surprise|${context.studentKey}|${state.turn}') %
            subjects.length];
    final action = _quizAction(pick, 'training', CompanionActionLabel.go);
    return reply(
      intent: 'surprise_me',
      key: 'surprise_me',
      values: _subjectValues(pick.key),
      actions: [action],
      pending: [action],
      subjectKey: pick.key,
    );
  }

  CompanionReply _topicReply(CompanionTopic topic) {
    final actions = [
      CompanionReplyAction(
        kind: CompanionActionKind.openChapter,
        label: CompanionActionLabel.openCourse,
        contentId: topic.contentId,
        lesson: topic.lesson,
        subjectKey: topic.subjectKey,
      ),
      if (topic.quizSetId case final setId?)
        CompanionReplyAction(
          kind: CompanionActionKind.openQuiz,
          label: CompanionActionLabel.topicQuiz,
          setId: setId,
          mode: 'training',
          subjectKey: topic.subjectKey,
        ),
    ];
    return reply(
      intent: 'course_topic',
      key: 'course_topic',
      values: {'topicTitle': topic.title},
      actions: actions,
      pending: actions.take(1).toList(),
      subjectKey: topic.subjectKey,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────

  static const _seeSubjects = CompanionReplyAction(
    kind: CompanionActionKind.showSubjects,
    label: CompanionActionLabel.seeSubjects,
  );

  static const _seeQuizzes = CompanionReplyAction(
    kind: CompanionActionKind.showQuizzes,
    label: CompanionActionLabel.seeAllQuizzes,
  );

  List<CompanionReplyAction> _startActions() => [
    if (context.resume case final resume?)
      CompanionReplyAction(
        kind: CompanionActionKind.openChapter,
        label: CompanionActionLabel.continueLearning,
        contentId: resume.contentId,
        subjectKey: resume.subjectKey,
      )
    else
      const CompanionReplyAction(
        kind: CompanionActionKind.showSubjects,
        label: CompanionActionLabel.continueLearning,
      ),
    if (context.quizCount > 0)
      const CompanionReplyAction(
        kind: CompanionActionKind.showQuizzes,
        label: CompanionActionLabel.takeQuiz,
      ),
  ];

  List<CompanionReplyAction> _helpActions() => [
    ..._startActions(),
    _seeSubjects,
  ];

  /// Une pastille par matière disponible : la toucher répond « Anglais ».
  List<CompanionReplyAction> _subjectChips() => [
    for (final subject in context.subjects)
      CompanionReplyAction(
        kind: CompanionActionKind.reply,
        label: CompanionActionLabel.subject,
        subjectKey: subject.key,
        subjectTitle: subject.title,
        reply: _capitalize(_subjectName(bank, context, subject.key)),
      ),
  ];

  List<CompanionReplyAction> _subjectActions(
    String key, {
    bool learnFirst = false,
  }) {
    final info = context.subject(key);
    if (info == null) return [_seeSubjects];
    final learn = CompanionReplyAction(
      kind: CompanionActionKind.openSubject,
      label: CompanionActionLabel.learnSubject,
      subjectKey: key,
      subjectTitle: info.title,
    );
    if (!info.hasQuiz) return [learn];
    final quiz = _quizAction(
      info,
      'training',
      CompanionActionLabel.subjectQuiz,
    );
    return learnFirst ? [learn, quiz] : [quiz, learn];
  }

  CompanionReplyAction _quizAction(
    CompanionSubjectInfo subject,
    String mode,
    CompanionActionLabel label,
  ) => CompanionReplyAction(
    kind: CompanionActionKind.openQuiz,
    label: label,
    setId: subject.quizSetId,
    mode: mode,
    subjectKey: subject.key,
    subjectTitle: subject.title,
  );

  /// Un quiz court dans la matière la plus probable : celle évoquée, celle du
  /// dernier quiz, celle de la dernière séquence, sinon la première.
  CompanionReplyAction? _quickQuiz({
    required String mode,
    required CompanionActionLabel label,
  }) {
    final subjects = context.quizSubjects;
    if (subjects.isEmpty) return null;
    final preferred = [
      state.recentSubjectKey,
      context.lastQuiz?.subjectKey,
      context.resume?.subjectKey,
    ];
    final pick =
        [
          for (final key in preferred)
            if (key != null) ?context.subject(key),
        ].where((s) => s.hasQuiz).firstOrNull ??
        subjects.first;
    return _quizAction(pick, mode, label);
  }

  Map<String, String> _subjectValues(String key) {
    final name = _subjectName(bank, context, key);
    return {'subjectName': name, 'SubjectName': _capitalize(name)};
  }

  // ── Choix de la variante ──────────────────────────────────────────────

  CompanionReply reply({
    required String intent,
    required String key,
    Map<String, String> values = const {},
    List<CompanionReplyAction> actions = const [],
    List<CompanionReplyAction> pending = const [],
    String? subjectKey,
    CompanionAwaiting awaiting = CompanionAwaiting.nothing,
    bool countTurn = true,
  }) {
    final all = {'firstName': ?context.firstName, ...values};
    final variants = bank.variants(key, personaId);
    final candidates = [
      for (final (index, variant) in variants.indexed)
        if (RegExp(
          r'\{(\w+)\}',
        ).allMatches(variant).every((m) => all.containsKey(m.group(1))))
          index,
    ];
    final pool = candidates.isEmpty
        ? List.generate(variants.length, (i) => i)
        : candidates;
    final recent = state.recentVariants[key] ?? const <int>[];
    final window = pool.length <= 1 ? 0 : (pool.length - 1).clamp(0, 3);
    final avoid = recent.take(window).toSet();
    final start =
        stableHash(
          '$personaId|$key|$text|${state.turn}|${context.studentKey}',
        ) %
        pool.length;
    var chosen = pool[start];
    for (var step = 0; step < pool.length; step++) {
      final candidate = pool[(start + step) % pool.length];
      if (!avoid.contains(candidate)) {
        chosen = candidate;
        break;
      }
    }
    var textOut = variants[chosen];
    for (final entry in all.entries) {
      textOut = textOut.replaceAll('{${entry.key}}', entry.value);
    }
    // Une variante sans ses données (cas limite) ne montre jamais d'accolade.
    textOut = textOut.replaceAll(RegExp(r',?\s*\{\w+\}'), '').trim();
    final recentVariants = {
      ...state.recentVariants,
      key: [chosen, ...recent].take(3).toList(),
    };
    final nextState = countTurn
        ? state.next(
            intent: intent,
            subjectKey: subjectKey,
            awaiting: awaiting,
            pendingActions: pending,
            recentVariants: recentVariants,
          )
        : CompanionConversationState(
            turn: state.turn,
            lastIntent: intent,
            lastSubjectKey: subjectKey ?? state.lastSubjectKey,
            lastSubjectTurn: subjectKey != null
                ? state.turn
                : state.lastSubjectTurn,
            pendingActions: pending.isEmpty
                ? actions.take(1).toList()
                : pending,
            recentVariants: recentVariants,
          );
    return CompanionReply(
      text: textOut,
      responseKey: key,
      intent: intent,
      actions: List.unmodifiable(actions),
      state: nextState,
    );
  }
}
