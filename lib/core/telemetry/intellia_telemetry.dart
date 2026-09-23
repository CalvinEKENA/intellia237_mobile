import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

/// Télémétrie strictement bornée à des événements produit non sensibles.
///
/// Interdits ici : texte libre, conversation, réponse, nom, e-mail, identifiant
/// utilisateur ou contenu détaillé d'un cours. Firebase reste désactivé tant
/// que l'utilisateur n'a pas activé « Diagnostics anonymes ».
abstract final class IntelliaTelemetry {
  static Future<void> onboardingCompleted() =>
      _log('onboarding_completed', const {});

  static Future<void> registrationCompleted({required String role}) =>
      _log('registration_completed', {'role': role});

  static Future<void> lessonOpened() => _log('lesson_opened', const {});

  static Future<void> lessonCompleted({required int completionPercent}) => _log(
    'lesson_completed',
    {'completion_percent': completionPercent.clamp(0, 100)},
  );

  static Future<void> quizOpened({
    required String mode,
    required int questionCount,
  }) => _log('quiz_opened', {
    'mode': mode == 'training' ? 'training' : 'exam',
    'question_count': questionCount.clamp(0, 500),
  });

  static Future<void> quizSubmitted({
    required int answeredCount,
    required int questionCount,
    int? scorePercent,
  }) {
    final boundedQuestionCount = questionCount.clamp(0, 500);
    return _log('quiz_submitted', {
      'answered_count': answeredCount.clamp(0, boundedQuestionCount),
      'question_count': boundedQuestionCount,
      if (scorePercent != null) 'score_percent': scorePercent.clamp(0, 100),
    });
  }

  static Future<void> flowCardCompleted({required String kind}) =>
      _log('flow_card_completed', {'card_kind': kind});

  static Future<void> flowExerciseAnswered({required bool correct}) =>
      _log('flow_exercise_answered', {'correct': correct ? 1 : 0});

  static Future<void> companionMessageSent() =>
      _log('companion_message_sent', const {});

  static Future<void> resumedLearning() => _log('learning_resumed', const {});

  static Future<void> goalSet({required int sessionsPerWeek}) =>
      _log('goal_set', {'sessions_per_week': sessionsPerWeek.clamp(1, 7)});

  static Future<void> goalWeekCompleted({required int sessionsPerWeek}) => _log(
    'goal_week_completed',
    {'sessions_per_week': sessionsPerWeek.clamp(1, 7)},
  );

  static Future<void> offlineActionQueued({required String kind}) =>
      _log('offline_action_queued', {'action_kind': kind});

  static Future<void> safeScreenError({required String surface}) =>
      _log('screen_error', {'surface': surface});

  static Future<void> _log(String name, Map<String, Object> parameters) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}
