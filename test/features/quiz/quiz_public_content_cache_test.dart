import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/quiz/data/quiz_public_content_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'conserve uniquement le payload public pour un usage réseau dégradé',
    () async {
      final cache = QuizPublicContentCache();
      final quiz = <String, dynamic>{
        'id': 'quiz-a',
        'title': 'Équations',
        'mode': 'exam',
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'q1',
            'prompt': '2 + 2',
            'options': <String>['4', '5'],
          },
        ],
      };

      await cache.writeQuiz('quiz-a', quiz);
      await cache.writeList(
        classLevel: '3eme',
        series: null,
        quizzes: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'quiz-a',
            'title': 'Équations',
            'questionCount': 1,
          },
        ],
      );

      expect(await cache.readQuiz('quiz-a'), quiz);
      expect(
        await cache.readList(classLevel: '3eme', series: null),
        hasLength(1),
      );
    },
  );

  test('ignore proprement un cache corrompu', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'quiz_public_content_v1_quiz-a': '{pas du json',
    });
    final cache = QuizPublicContentCache();

    expect(await cache.readQuiz('quiz-a'), isNull);
  });
}
