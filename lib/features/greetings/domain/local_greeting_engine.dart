import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum GreetingEvent {
  morning,
  midday,
  afternoon,
  evening,
  returnAfterRecentStudy,
  returnAfterSeveralDays,
  beginningSession,
  afterProgress,
  afterQuizSuccess,
  afterDifficultAttempt,
  neutral,
}

class GreetingContext {
  const GreetingContext({
    required this.learnerId,
    required this.companionId,
    required this.languageCode,
    this.firstName,
    this.classLevel,
    this.event,
    this.hasProgress = false,
  });

  final String learnerId;
  final String companionId;
  final String languageCode;
  final String? firstName;
  final String? classLevel;
  final GreetingEvent? event;
  final bool hasProgress;
}

class LocalGreeting {
  const LocalGreeting({required this.id, required this.text});

  final String id;
  final String text;
}

/// Moteur local de salutations : aucun réseau, aucune donnée sensible et une
/// petite mémoire par élève pour éviter les répétitions immédiates.
abstract final class LocalGreetingEngine {
  static const _historyWindow = 4;

  static Future<LocalGreeting> select(
    GreetingContext context, {
    DateTime? now,
    SharedPreferences? preferences,
  }) async {
    final clock = now ?? DateTime.now();
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final event = context.event ?? _eventFor(context, clock, prefs);
    final level = _levelGroup(context.classLevel);
    final variants = _variants(context: context, event: event, level: level);
    final historyKey = _historyKey(context.learnerId);
    final recent = _decodeHistory(prefs.getString(historyKey));
    final available = variants
        .where((candidate) => !recent.contains(candidate.id))
        .toList(growable: false);
    final pool = available.isEmpty ? variants : available;
    final seed = Object.hash(
      context.learnerId,
      context.companionId,
      clock.year,
      clock.month,
      clock.day,
      clock.hour,
      recent.length,
      event.index,
    );
    final selected = pool[seed.abs() % pool.length];
    final nextHistory = <String>[
      selected.id,
      ...recent,
    ].take(_historyWindow).toList(growable: false);
    await prefs.setString(historyKey, jsonEncode(nextHistory));
    await prefs.setString(
      _lastSeenKey(context.learnerId),
      clock.toUtc().toIso8601String(),
    );
    return selected;
  }

  static String fallback(GreetingContext context, {DateTime? now}) {
    final english = context.languageCode.toLowerCase().startsWith('en');
    final name = _cleanName(context.firstName);
    final prefix = english
        ? (name == null ? 'Welcome back.' : 'Welcome back, $name.')
        : (name == null ? 'Bon retour.' : 'Bon retour, $name.');
    final companion = context.companionId == 'leo'
        ? (english
              ? 'We can start with one concrete step.'
              : 'On peut commencer par une étape concrète.')
        : (english
              ? 'Let’s choose the priority that will help you most.'
              : 'Choisissons la priorité qui t’aidera le plus.');
    return '$prefix $companion';
  }

  static GreetingEvent _eventFor(
    GreetingContext context,
    DateTime now,
    SharedPreferences preferences,
  ) {
    final raw = preferences.getString(_lastSeenKey(context.learnerId));
    final previous = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (previous == null) return GreetingEvent.beginningSession;
    final elapsed = now.difference(previous);
    if (elapsed.inDays >= 3) return GreetingEvent.returnAfterSeveralDays;
    if (elapsed.inHours < 12 && context.hasProgress) {
      return GreetingEvent.returnAfterRecentStudy;
    }
    if (now.hour >= 5 && now.hour < 11) return GreetingEvent.morning;
    if (now.hour >= 11 && now.hour < 14) return GreetingEvent.midday;
    if (now.hour >= 14 && now.hour < 18) return GreetingEvent.afternoon;
    return GreetingEvent.evening;
  }

  static List<LocalGreeting> _variants({
    required GreetingContext context,
    required GreetingEvent event,
    required _LevelGroup level,
  }) {
    final english = context.languageCode.toLowerCase().startsWith('en');
    final name = _cleanName(context.firstName);
    final openings = english
        ? _englishOpenings(event, name)
        : _frenchOpenings(event, name);
    final levelLines = english
        ? _englishLevelLines(level)
        : _frenchLevelLines(level);
    final personalityLines = english
        ? _englishPersonalityLines(context.companionId)
        : _frenchPersonalityLines(context.companionId);

    return List<LocalGreeting>.generate(6, (index) {
      final text = <String>[
        openings[index % openings.length],
        levelLines[(index + event.index) % levelLines.length],
        personalityLines[(index + level.index) % personalityLines.length],
      ].join(' ');
      return LocalGreeting(
        id:
            '${english ? 'en' : 'fr'}-${context.companionId}-'
            '${event.name}-${level.name}-$index',
        text: text,
      );
    });
  }

  static List<String> _frenchOpenings(GreetingEvent event, String? name) {
    final named = name == null ? '' : ' $name';
    return switch (event) {
      GreetingEvent.morning => [
        'Bonjour$named.',
        'Une nouvelle matinée commence$named.',
        'Content de te retrouver ce matin$named.',
      ],
      GreetingEvent.midday => [
        'Bonjour$named.',
        'Une pause utile dans ta journée$named ?',
        'On se retrouve pour avancer un peu$named.',
      ],
      GreetingEvent.afternoon => [
        'Bon après-midi$named.',
        'Prêt à reprendre le fil$named ?',
        'On garde un bon rythme cet après-midi$named.',
      ],
      GreetingEvent.evening => [
        'Bonsoir$named.',
        'Terminons la journée avec une séance bien ciblée$named.',
        'Bon retour pour cette session du soir$named.',
      ],
      GreetingEvent.returnAfterRecentStudy => [
        'Bon retour$named. Tu as encore tes derniers progrès en tête.',
        'Te revoilà$named. On peut consolider ce que tu viens de travailler.',
        'Belle régularité$named. Reprenons sans perdre le fil.',
      ],
      GreetingEvent.returnAfterSeveralDays => [
        'Heureux de te revoir$named. On reprend sans pression.',
        'Bon retour$named. Une courte séance suffit pour retrouver le rythme.',
        'Cela faisait quelques jours$named. Commençons simplement.',
      ],
      GreetingEvent.beginningSession => [
        'Bienvenue$named.',
        'On commence cette première séance ensemble$named.',
        'Ravi de t’accompagner pour cette session$named.',
      ],
      GreetingEvent.afterProgress => [
        'Beau progrès$named.',
        'Tu viens de franchir une étape$named.',
        'Ce chapitre avance bien$named.',
      ],
      GreetingEvent.afterQuizSuccess => [
        'Très bon résultat$named.',
        'Ce quiz montre de solides acquis$named.',
        'Belle réussite sur ce quiz$named.',
      ],
      GreetingEvent.afterDifficultAttempt => [
        'Cette tentative était exigeante$named, et c’est utile pour apprendre.',
        'Pas besoin de tout réussir du premier coup$named.',
        'Ce quiz a révélé un point à renforcer$named.',
      ],
      GreetingEvent.neutral => [
        'Bon retour$named.',
        'On avance ensemble aujourd’hui$named ?',
        'Quelle direction veux-tu prendre$named ?',
      ],
    };
  }

  static List<String> _englishOpenings(GreetingEvent event, String? name) {
    final named = name == null ? '' : ', $name';
    return switch (event) {
      GreetingEvent.morning => [
        'Good morning$named.',
        'A fresh morning, and a good moment to make progress$named.',
        'Welcome back this morning$named.',
      ],
      GreetingEvent.midday => [
        'Good afternoon$named.',
        'A focused break can go a long way$named.',
        'Let’s make this part of the day count$named.',
      ],
      GreetingEvent.afternoon => [
        'Good afternoon$named.',
        'Ready to pick up where you left off$named?',
        'There is still time for one useful step today$named.',
      ],
      GreetingEvent.evening => [
        'Good evening$named.',
        'Let’s close the day with a focused session$named.',
        'Welcome back for an evening study session$named.',
      ],
      GreetingEvent.returnAfterRecentStudy => [
        'Welcome back$named. Your recent work is still fresh.',
        'You are back at it$named. Let’s build on the last session.',
        'Good consistency$named. We can continue without losing momentum.',
      ],
      GreetingEvent.returnAfterSeveralDays => [
        'It’s good to see you again$named. We can ease back in.',
        'Welcome back$named. One short session can restore the rhythm.',
        'It has been a few days$named. Let’s start with something manageable.',
      ],
      GreetingEvent.beginningSession => [
        'Welcome$named.',
        'Let’s begin this first session together$named.',
        'It’s good to join you for this study session$named.',
      ],
      GreetingEvent.afterProgress => [
        'That was real progress$named.',
        'You have just moved one step forward$named.',
        'This topic is taking shape$named.',
      ],
      GreetingEvent.afterQuizSuccess => [
        'Strong result$named.',
        'That quiz shows solid understanding$named.',
        'Well done on that quiz$named.',
      ],
      GreetingEvent.afterDifficultAttempt => [
        'That was a demanding attempt$named, and it gave us useful clues.',
        'You do not need to get everything right first time$named.',
        'That quiz uncovered one area worth strengthening$named.',
      ],
      GreetingEvent.neutral => [
        'Welcome back$named.',
        'Shall we move one step forward today$named?',
        'What would you like to work on$named?',
      ],
    };
  }

  static List<String> _frenchLevelLines(_LevelGroup level) => switch (level) {
    _LevelGroup.earlySecondary => [
      'Choisissons une matière et avançons tranquillement.',
      'On peut prendre le temps de comprendre chaque étape.',
      'Un petit défi à la fois, avec des explications claires.',
    ],
    _LevelGroup.middleSecondary => [
      'À toi de choisir le défi : comprendre, t’entraîner ou te tester.',
      'Tu peux mener la séance ; je t’aide à aller au fond des choses.',
      'On vise un progrès précis et tu gardes la main sur le rythme.',
    ],
    _LevelGroup.transition => [
      'Au lycée, une bonne méthode fait déjà une grande différence.',
      'On peut organiser la séance autour d’un objectif clair.',
      'Comprendre le cours et savoir l’utiliser : travaillons les deux.',
    ],
    _LevelGroup.premiere => [
      'Régularité, méthode et maîtrise : choisissons le bon point à renforcer.',
      'Une séance ciblée peut consolider durablement ce chapitre.',
      'Travaillons la précision sans perdre la vue d’ensemble.',
    ],
    _LevelGroup.finalYear => [
      'Gardons le cap sur tes objectifs, sans pression inutile.',
      'Révision, méthode ou préparation d’épreuve : ciblons l’essentiel.',
      'Une séance bien délimitée peut beaucoup apporter à ta préparation.',
    ],
    _LevelGroup.unknown => [
      'Choisissons un objectif utile et avançons à ton rythme.',
      'On peut revoir un point précis ou poursuivre ton cours.',
      'Dis-moi ce qui mérite le plus ton attention aujourd’hui.',
    ],
  };

  static List<String> _englishLevelLines(_LevelGroup level) => switch (level) {
    _LevelGroup.earlySecondary => [
      'Choose one subject and we will take it step by step.',
      'We can slow down and make every part clear.',
      'One manageable challenge at a time works well.',
    ],
    _LevelGroup.middleSecondary => [
      'You choose the challenge: understand, practise, or test yourself.',
      'Take the lead and I will help you examine the tricky parts.',
      'Let’s aim for one clear improvement while you set the pace.',
    ],
    _LevelGroup.transition => [
      'This stage rewards good organisation as much as hard work.',
      'We can shape the session around one clear outcome.',
      'Let’s connect the idea, the method, and how to use both.',
    ],
    _LevelGroup.premiere => [
      'Consistency and sound method will turn understanding into mastery.',
      'A focused session can make this topic much more secure.',
      'Let’s improve precision without losing the bigger picture.',
    ],
    _LevelGroup.finalYear => [
      'Keep your goals in view without adding unnecessary pressure.',
      'Revision, exam practice, or one difficult point: let’s target it.',
      'One well-defined session can strengthen your exam preparation.',
    ],
    _LevelGroup.unknown => [
      'Choose a useful goal and we will work at your pace.',
      'We can revisit one point or continue your course.',
      'Tell me what deserves your attention most today.',
    ],
  };

  static List<String> _frenchPersonalityLines(String companionId) =>
      companionId == 'leo'
      ? [
          'On démarre par un exercice concret ?',
          'Je te propose de passer rapidement à l’action.',
          'Choisis le premier pas et lançons-nous.',
        ]
      : [
          'On choisit d’abord la priorité qui t’aidera le plus ?',
          'Je peux t’aider à structurer les idées avant de pratiquer.',
          'Commençons par clarifier ce qui compte vraiment.',
        ];

  static List<String> _englishPersonalityLines(String companionId) =>
      companionId == 'leo'
      ? [
          'Shall we start with one concrete exercise?',
          'I suggest we put the idea into practice straight away.',
          'Choose the first step and let’s get moving.',
        ]
      : [
          'Shall we choose the priority that will help you most?',
          'I can help organise the ideas before we practise.',
          'Let’s first make the essential point completely clear.',
        ];

  static _LevelGroup _levelGroup(String? value) {
    final normalized = (value ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if ({'6eme', '6e', '5eme', '5e', 'form1', 'form2'}.contains(normalized)) {
      return _LevelGroup.earlySecondary;
    }
    if ({
      '4eme',
      '4e',
      '3eme',
      '3e',
      'form3',
      'form4',
      'form5',
    }.contains(normalized)) {
      return _LevelGroup.middleSecondary;
    }
    if ({'2nde', 'seconde', 'lowersixth'}.contains(normalized)) {
      return _LevelGroup.transition;
    }
    if ({'1ere', 'premiere'}.contains(normalized)) {
      return _LevelGroup.premiere;
    }
    if ({'terminale', 'uppersixth'}.contains(normalized)) {
      return _LevelGroup.finalYear;
    }
    return _LevelGroup.unknown;
  }

  static String? _cleanName(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static List<String> _decodeHistory(String? value) {
    if (value == null) return const [];
    try {
      return (jsonDecode(value) as List<dynamic>).whereType<String>().toList(
        growable: false,
      );
    } catch (_) {
      return const [];
    }
  }

  static String _historyKey(String learnerId) =>
      'local_greeting_history_v1_$learnerId';
  static String _lastSeenKey(String learnerId) =>
      'local_greeting_last_seen_v1_$learnerId';
}

enum _LevelGroup {
  earlySecondary,
  middleSecondary,
  transition,
  premiere,
  finalYear,
  unknown,
}
