import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/app_theme.dart';
import 'package:intellia237/core/widgets/intellia_card.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_choices.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_entry_card.dart';
import 'package:intellia237/features/intellia_pass/domain/household_profile.dart';
import 'package:intellia237/features/intellia_pass/presentation/widgets/household_learner_selector.dart';
import 'package:intellia237/features/onboarding/presentation/widgets/account_type_card.dart';
import 'package:intellia237/features/quiz/domain/quiz_question.dart';
import 'package:intellia237/features/quiz/domain/quiz_type.dart';
import 'package:intellia237/features/quiz/presentation/widgets/qcm_question_card.dart';
import 'package:intellia237/features/quiz/presentation/widgets/short_answer_question_card.dart';
import 'package:intellia237/features/quiz/presentation/widgets/true_false_question_card.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_home/presentation/widgets/daily_challenges_section.dart';
import 'package:intellia237/features/student_home/presentation/widgets/progress_overview_card.dart';
import 'package:intellia237/features/student_home/presentation/widgets/recommendations_section.dart';
import 'package:intellia237/features/student_home/presentation/widgets/resume_course_card.dart';
import 'package:intellia237/features/student_home/presentation/widgets/streak_motivation_card.dart';
import 'package:intellia237/features/campus/presentation/widgets/campus_kpi_card.dart';
import 'package:intellia237/features/student_home/presentation/widgets/subjects_carousel.dart';

const _viewport = Size(360, 1200);
const _textScale = 1.5;

const _coveredPublicCardTypes = {
  'IntelliaCard',
  'IntelliaGlassCard',
  'AuthChoiceCard',
  'CompanionSelectionCard',
  'AccountTypeCard',
  'QcmQuestionCard',
  'TrueFalseQuestionCard',
  'ShortAnswerQuestionCard',
  'FlowEntryCard',
  'ProgressOverviewCard',
  'ResumeCourseCard',
  'StreakMotivationCard',
  'WeeklyGoalCard',
  'ChapterOfflineActionCard',
  'StudentProfileTutorCard',
  // Dedicated FR/EN matrix: test/features/mastery/mastery_widget_test.dart.
  'MasterySubjectCard',
  'CampusKpiCard',
};

const _longQuestion = QuizQuestion(
  id: 'question-responsive',
  type: QuizQuestionType.qcm,
  prompt:
      'Quelle proposition explique correctement ce phénomène scientifique ?',
  options: [
    'Une réponse volontairement longue qui doit revenir naturellement à la ligne.',
    'Une seconde réponse possible.',
  ],
  explanation: '',
  pointsReward: 5,
);

void main() {
  final cases = <({String name, Widget child})>[
    (
      name: 'IntelliaCard avec action adjacente',
      child: IntelliaCard(
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Une information éditoriale suffisamment longue pour revenir à la ligne.',
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _noop, child: const Text('Ouvrir')),
          ],
        ),
      ),
    ),
    (
      name: 'IntelliaGlassCard',
      child: const IntelliaGlassCard(
        child: Text(
          'Une carte vitrée garde une largeur de lecture confortable sur mobile.',
        ),
      ),
    ),
    (
      name: 'AuthChoiceCard',
      child: AuthChoiceCard(
        title: 'Créer un compte élève',
        description:
            'Accéder aux cours, aux exercices et au compagnon pédagogique.',
        icon: Icons.school_outlined,
        isSelected: false,
        onTap: _noop,
      ),
    ),
    (
      name: 'AccountTypeCard',
      child: AccountTypeCard(
        role: AppRole.student,
        title: 'Je suis un élève',
        subtitle:
            'Je souhaite apprendre avec un parcours scolaire personnalisé.',
        icon: Icons.school_outlined,
        color: Colors.indigo,
        isSelected: true,
        onTap: _noop,
      ),
    ),
    (
      name: 'CompanionSelectionCard',
      child: CompanionSelectionCard(
        name: 'Léo',
        description:
            'Un compagnon dynamique qui encourage les progrès au quotidien.',
        assetPath: 'assets/companions/leo.png',
        accent: Colors.indigo,
        isSelected: true,
        onTap: _noop,
      ),
    ),
    (
      name: 'QcmQuestionCard',
      child: QcmQuestionCard(
        question: _longQuestion,
        selectedIndex: 0,
        onSelected: _ignoreInt,
      ),
    ),
    (
      name: 'TrueFalseQuestionCard',
      child: TrueFalseQuestionCard(
        question: _longQuestion,
        selectedValue: true,
        onSelected: _ignoreBool,
      ),
    ),
    (
      name: 'ShortAnswerQuestionCard',
      child: ShortAnswerQuestionCard(
        question: _longQuestion,
        value: '',
        onChanged: _ignoreString,
      ),
    ),
    (name: 'FlowEntryCard', child: FlowEntryCard(onTap: _noop)),
    (
      name: 'ProgressOverviewCard',
      child: ProgressOverviewCard(
        globalProgress: 0.64,
        level: 7,
        currentPoints: 1250,
        onTap: _noop,
      ),
    ),
    (
      name: 'ResumeCourseCard',
      child: ResumeCourseCard(
        resume: const ResumeTarget(
          subjectId: 'science',
          chapterId: 'living-world',
          lessonId: 'lesson-1',
          lessonTitle:
              'Comprendre les relations entre les êtres vivants et leur milieu',
          subjectTitle: 'Sciences de la vie et de la Terre',
          progress: 0.42,
        ),
        onResume: _noop,
      ),
    ),
    (
      name: 'StreakMotivationCard',
      child: const StreakMotivationCard(
        streakDays: 12,
        message: 'Une progression régulière construite à ton propre rythme.',
      ),
    ),
    (
      name: 'RecommendationsSection',
      child: RecommendationsSection(
        items: const [
          RecommendationItem(
            title: 'Revoir les relations entre les êtres vivants',
            subtitle:
                'Une recommandation personnalisée avec une description détaillée.',
            estimatedMinutes: 25,
          ),
        ],
        onItemTap: _ignoreRecommendation,
      ),
    ),
    (
      name: 'DailyChallengesSection',
      child: DailyChallengesSection(
        items: const [
          DailyChallengeItem(
            title: 'Répondre à cinq questions de sciences sans se précipiter',
            rewardPoints: 20,
            completed: false,
          ),
        ],
        onItemTap: _ignoreChallenge,
      ),
    ),
    (
      name: 'SubjectsCarousel',
      child: SubjectsCarousel(
        subjects: const [
          SubjectOverview(
            id: 'science',
            title: 'Sciences de la vie et de la Terre',
            progress: 0.55,
            colorHex: 0xFF1451E1,
            iconKey: 'science',
          ),
        ],
        onSubjectTap: _ignoreSubject,
      ),
    ),
    (
      name: 'HouseholdLearnerSelector',
      child: HouseholdLearnerSelector(
        household: HouseholdProfiles(const [
          LearnerProfileSummary(
            id: 'learner-1',
            displayName: 'Élève au nom volontairement très détaillé',
            levelLabel: 'Classe de troisième francophone',
          ),
        ]),
        onLearnerSelected: _ignoreLearner,
        onAddLearner: _noop,
        onOpenParentArea: _noop,
      ),
    ),
    (
      name: 'CampusKpiCard',
      child: const CampusKpiCard(
        category: 'Programme',
        metric: '78 %',
        label: 'Taux d’avancement',
        subtitle: 'Synthèse déterministe',
      ),
    ),
  ];

  for (final cardCase in cases) {
    testWidgets('${cardCase.name} reste lisible à 360 px et textScale 1.5', (
      tester,
    ) async {
      tester.view.physicalSize = _viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('fr'),
          home: MediaQuery(
            data: const MediaQueryData(
              size: _viewport,
              textScaler: TextScaler.linear(_textScale),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: TabSurface(
                palette: const TabPalette(TabPresentationMode.embeddedLight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: cardCase.child,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      _expectTextGeometry(tester, cardCase.name);
    });
  }

  test('chaque composant Card public possède un test mobile accessible', () {
    final publicCards = <String>{};
    final declaration = RegExp(
      r'class\s+([A-Z]\w*Card)\s+extends\s+'
      r'(?:StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget)',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match in declaration.allMatches(entity.readAsStringSync())) {
        publicCards.add(match.group(1)!);
      }
    }

    expect(
      _coveredPublicCardTypes,
      containsAll(publicCards),
      reason:
          'Toute nouvelle carte textuelle publique doit rejoindre le catalogue '
          '360 px / textScale 1.5 ou disposer d’un test dédié.',
    );
  });
}

void _expectTextGeometry(WidgetTester tester, String cardName) {
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final content = (widget.data ?? widget.textSpan?.toPlainText() ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final renderBox = element.renderObject as RenderBox;
    final left = renderBox.localToGlobal(Offset.zero).dx;
    final right = left + renderBox.size.width;

    expect(left, greaterThanOrEqualTo(-0.01), reason: '$cardName: "$content"');
    expect(
      right,
      lessThanOrEqualTo(_viewport.width + 0.01),
      reason: '$cardName: "$content" sort horizontalement de l’écran.',
    );
    if (content.length >= 12) {
      expect(
        renderBox.size.width,
        greaterThan(48),
        reason: '$cardName: "$content" est comprimé en colonne de caractères.',
      );
    }
  }
}

void _noop() {}
void _ignoreInt(int _) {}
void _ignoreBool(bool _) {}
void _ignoreString(String _) {}
void _ignoreRecommendation(RecommendationItem _) {}
void _ignoreChallenge(DailyChallengeItem _) {}
void _ignoreSubject(SubjectOverview _) {}
void _ignoreLearner(LearnerProfileSummary _) {}
