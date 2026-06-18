
import '../domain/learn_chapter.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_subject.dart';
import 'learn_repository.dart';

class MockLearnRepository implements LearnRepository {
  static const _allClasses = <String>[
    '6eme',
    '5eme',
    '4eme',
    '3eme',
    'Seconde',
    'Premiere',
    'Terminale',
  ];

  final Map<String, Map<String, _LessonRuntimeState>> _runtimeByUser = {};

  @override
  Future<List<LearnSubject>> fetchSubjects({
    required String userId,
    required String classLevel,
    required String? series,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final seeds = _subjectsFor(classLevel: classLevel, series: series);

    return seeds
        .map(
          (seed) => LearnSubject(
            id: seed.id,
            title: seed.title,
            description: seed.description,
            colorHex: seed.colorHex,
            iconKey: seed.iconKey,
            chapters: seed.chapters
                .map(
                  (chapter) => LearnChapterSummary(
                    id: chapter.id,
                    title: chapter.title,
                    description: chapter.description,
                    lessonsCount: chapter.lessons.length,
                    completion: _chapterCompletion(
                      userId: userId,
                      subjectId: seed.id,
                      chapter: chapter,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<LearnSubjectDetail> fetchSubjectDetail({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final seed = _subjectsFor(classLevel: classLevel, series: series)
        .firstWhere(
          (item) => item.id == subjectId,
          orElse: () => throw StateError('Matiere introuvable: $subjectId'),
        );

    return LearnSubjectDetail(
      id: seed.id,
      title: seed.title,
      description: seed.description,
      colorHex: seed.colorHex,
      iconKey: seed.iconKey,
      chapters: seed.chapters
          .map(
            (chapter) => LearnChapter(
              id: chapter.id,
              subjectId: seed.id,
              title: chapter.title,
              description: chapter.description,
              lessons: chapter.lessons
                  .map(
                    (lesson) => _buildLessonPreview(
                      userId: userId,
                      subjectId: seed.id,
                      chapterId: chapter.id,
                      lesson: lesson,
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<LearnChapter> fetchChapter({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
    required String chapterId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final subject = _subjectsFor(classLevel: classLevel, series: series)
        .firstWhere(
          (item) => item.id == subjectId,
          orElse: () => throw StateError('Matiere introuvable: $subjectId'),
        );
    final chapter = subject.chapters.firstWhere(
      (item) => item.id == chapterId,
      orElse: () => throw StateError('Chapitre introuvable: $chapterId'),
    );

    return LearnChapter(
      id: chapter.id,
      subjectId: subjectId,
      title: chapter.title,
      description: chapter.description,
      lessons: chapter.lessons
          .map(
            (lesson) => _buildLessonPreview(
              userId: userId,
              subjectId: subjectId,
              chapterId: chapterId,
              lesson: lesson,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<LearnLesson> fetchLesson({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final subject = _subjectsFor(classLevel: classLevel, series: series)
        .firstWhere(
          (item) => item.id == subjectId,
          orElse: () => throw StateError('Matiere introuvable: $subjectId'),
        );
    final chapter = subject.chapters.firstWhere(
      (item) => item.id == chapterId,
      orElse: () => throw StateError('Chapitre introuvable: $chapterId'),
    );
    final lesson = chapter.lessons.firstWhere(
      (item) => item.id == lessonId,
      orElse: () => throw StateError('Lecon introuvable: $lessonId'),
    );

    final runtime = _runtimeStateFor(
      userId: userId,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
    );

    return LearnLesson(
      id: lesson.id,
      title: lesson.title,
      summary: lesson.summary,
      estimatedMinutes: lesson.estimatedMinutes,
      progress: runtime.progress,
      isFavorite: runtime.isFavorite,
      contentSections: lesson.sections,
      miniQuiz: lesson.miniQuiz,
    );
  }

  @override
  Future<void> toggleLessonFavorite({
    required String userId,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) async {
    final runtime = _runtimeStateFor(
      userId: userId,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
    );
    runtime.isFavorite = !runtime.isFavorite;
  }

  @override
  Future<void> setLessonProgress({
    required String userId,
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required double progress,
  }) async {
    final runtime = _runtimeStateFor(
      userId: userId,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
    );
    runtime.progress = progress.clamp(0, 1);
  }

  List<_SubjectSeed> _subjectsFor({
    required String classLevel,
    required String? series,
  }) {
    return _subjectSeeds
        .where((subject) {
          if (!subject.allowedClasses.contains(classLevel)) {
            return false;
          }

          if (subject.allowedSeries.isEmpty) {
            return true;
          }

          if (series == null || series.isEmpty) {
            return false;
          }

          return subject.allowedSeries.contains(series);
        })
        .toList(growable: false);
  }

  LearnLessonPreview _buildLessonPreview({
    required String userId,
    required String subjectId,
    required String chapterId,
    required _LessonSeed lesson,
  }) {
    final runtime = _runtimeStateFor(
      userId: userId,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lesson.id,
    );

    return LearnLessonPreview(
      id: lesson.id,
      title: lesson.title,
      summary: lesson.summary,
      estimatedMinutes: lesson.estimatedMinutes,
      progress: runtime.progress,
      isFavorite: runtime.isFavorite,
    );
  }

  double _chapterCompletion({
    required String userId,
    required String subjectId,
    required _ChapterSeed chapter,
  }) {
    if (chapter.lessons.isEmpty) {
      return 0;
    }

    final total = chapter.lessons.fold<double>(
      0,
      (sum, lesson) =>
          sum +
          _runtimeStateFor(
            userId: userId,
            subjectId: subjectId,
            chapterId: chapter.id,
            lessonId: lesson.id,
          ).progress,
    );
    return total / chapter.lessons.length;
  }

  _LessonRuntimeState _runtimeStateFor({
    required String userId,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) {
    final byLesson = _runtimeByUser.putIfAbsent(userId, () => {});
    final key = '$subjectId::$chapterId::$lessonId';
    return byLesson.putIfAbsent(
      key,
      () => _LessonRuntimeState(
        progress: _initialProgressFor(lessonId),
        isFavorite: false,
      ),
    );
  }

  double _initialProgressFor(String lessonId) {
    return switch (lessonId) {
      'eq_1' => 0.72,
      'eq_2' => 0.35,
      'acid_1' => 0.45,
      _ => 0,
    };
  }

  static final List<_SubjectSeed> _subjectSeeds = [
    _SubjectSeed(
      id: 'math',
      title: 'Mathematiques',
      description: 'Algebre, geometrie, logique et resolution de problemes.',
      colorHex: 0xFF1451E1,
      iconKey: 'math',
      allowedClasses: _allClasses,
      chapters: [
        _ChapterSeed(
          id: 'equations',
          title: 'Equations et inconnues',
          description: 'Maitriser les methodes de resolution pas a pas.',
          lessons: [
            _LessonSeed(
              id: 'eq_1',
              title: 'Equation du premier degre',
              summary: 'Isoler l\'inconnue et verifier le resultat.',
              estimatedMinutes: 18,
              sections: [
                LessonContentSection(
                  title: 'Concept cle',
                  body:
                      'Une equation du premier degre se ramene a la forme ax + b = 0 avec a non nul.',
                ),
                LessonContentSection(
                  title: 'Methode premium',
                  body:
                      'Regroupe les termes en x, puis les constantes, ensuite divise par le coefficient de x.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'eq1_q1',
                  prompt: 'Resoudre 3x + 6 = 0',
                  options: const ['x = -2', 'x = 2', 'x = -3'],
                  correctIndex: 0,
                  explanation: '3x = -6 donc x = -2.',
                ),
                LessonMiniQuizQuestion(
                  id: 'eq1_q2',
                  prompt: 'Resoudre 5x - 10 = 0',
                  options: const ['x = -2', 'x = 2', 'x = 5'],
                  correctIndex: 1,
                  explanation: '5x = 10 donc x = 2.',
                ),
              ],
            ),
            _LessonSeed(
              id: 'eq_2',
              title: 'Problemes menant a une equation',
              summary: 'Transformer un enonce en equation simple.',
              estimatedMinutes: 22,
              sections: [
                LessonContentSection(
                  title: 'Strategie',
                  body:
                      'Identifie la grandeur inconnue, puis ecris les relations sous forme mathematique.',
                ),
                LessonContentSection(
                  title: 'Verification',
                  body:
                      'Remplace la solution dans l\'enonce pour verifier sa coherence.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'eq2_q1',
                  prompt:
                      'Le double d\'un nombre plus 3 vaut 11. Ce nombre est:',
                  options: const ['4', '5', '7'],
                  correctIndex: 0,
                  explanation: '2x + 3 = 11 donc 2x = 8 puis x = 4.',
                ),
              ],
            ),
          ],
        ),
        _ChapterSeed(
          id: 'functions',
          title: 'Fonctions affines',
          description:
              'Lire et interpreter les fonctions lineaires et affines.',
          lessons: [
            _LessonSeed(
              id: 'func_1',
              title: 'Identifier pente et ordonnee a l\'origine',
              summary: 'Comprendre y = ax + b visuellement.',
              estimatedMinutes: 16,
              sections: [
                LessonContentSection(
                  title: 'Lecture graphique',
                  body:
                      'La pente indique la variation de y quand x augmente de 1 unite.',
                ),
                LessonContentSection(
                  title: 'Application',
                  body:
                      'Plus a est grand, plus la droite est inclinee vers le haut.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'func1_q1',
                  prompt: 'Dans y = 2x + 3, l\'ordonnee a l\'origine vaut:',
                  options: const ['2', '3', '5'],
                  correctIndex: 1,
                  explanation: 'Le terme constant b vaut 3.',
                ),
              ],
            ),
            _LessonSeed(
              id: 'func_2',
              title: 'Tracer une droite affine',
              summary: 'Tracer rapidement a partir de deux points.',
              estimatedMinutes: 20,
              sections: [
                LessonContentSection(
                  title: 'Procedure',
                  body:
                      'Place d\'abord le point d\'ordonnee a l\'origine, puis utilise la pente pour obtenir un second point.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'func2_q1',
                  prompt: 'Pour y = -x + 4, un point de la droite est:',
                  options: const ['(0,4)', '(1,4)', '(4,0)'],
                  correctIndex: 0,
                  explanation: 'Si x = 0, alors y = 4.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _SubjectSeed(
      id: 'fr',
      title: 'Francais',
      description: 'Comprendre, rediger, argumenter avec precision.',
      colorHex: 0xFF7C3AED,
      iconKey: 'french',
      allowedClasses: _allClasses,
      chapters: [
        _ChapterSeed(
          id: 'argumentation',
          title: 'Argumentation',
          description: 'Construire une idee et la defendre clairement.',
          lessons: [
            _LessonSeed(
              id: 'arg_1',
              title: 'Structure d\'un paragraphe argumente',
              summary: 'Idee directrice, explication, exemple.',
              estimatedMinutes: 15,
              sections: [
                LessonContentSection(
                  title: 'Schema gagnant',
                  body:
                      'Annonce l\'idee, developpe-la en deux phrases, puis illustre avec un exemple concret.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'arg1_q1',
                  prompt: 'Quel element vient en premier?',
                  options: const ['Exemple', 'Idee directrice', 'Conclusion'],
                  correctIndex: 1,
                  explanation: 'Le paragraphe commence par l\'idee directrice.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _SubjectSeed(
      id: 'phys',
      title: 'Physique-Chimie',
      description: 'Modeliser les phenomenes et raisonner scientifiquement.',
      colorHex: 0xFF0F766E,
      iconKey: 'physic',
      allowedClasses: const ['Seconde', 'Premiere', 'Terminale'],
      allowedSeries: const ['A', 'C', 'D'],
      chapters: [
        _ChapterSeed(
          id: 'electricity',
          title: 'Electricite',
          description: 'Tension, intensite, resistance et circuits.',
          lessons: [
            _LessonSeed(
              id: 'elec_1',
              title: 'Loi d\'Ohm',
              summary: 'Relier U, I et R dans un circuit simple.',
              estimatedMinutes: 19,
              sections: [
                LessonContentSection(
                  title: 'Formule',
                  body:
                      'U = R x I. Chaque grandeur possede son unite: volt, ohm, ampere.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'elec1_q1',
                  prompt: 'Si R = 5 ohms et I = 2 A, U vaut:',
                  options: const ['2 V', '10 V', '7 V'],
                  correctIndex: 1,
                  explanation: 'U = 5 x 2 = 10 volts.',
                ),
              ],
            ),
          ],
        ),
        _ChapterSeed(
          id: 'acid-base',
          title: 'Acides et bases',
          description: 'Comprendre le pH et les reactions simples.',
          lessons: [
            _LessonSeed(
              id: 'acid_1',
              title: 'Lecture de l\'echelle de pH',
              summary: 'Identifier acide, neutre ou basique.',
              estimatedMinutes: 17,
              sections: [
                LessonContentSection(
                  title: 'Repere',
                  body: 'pH < 7 acide, pH = 7 neutre, pH > 7 basique.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'acid1_q1',
                  prompt: 'Un liquide de pH 3 est:',
                  options: const ['Neutre', 'Acide', 'Basique'],
                  correctIndex: 1,
                  explanation: 'Un pH inferieur a 7 indique un acide.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _SubjectSeed(
      id: 'anglais',
      title: 'Anglais',
      description: 'Developper expression orale et ecrite.',
      colorHex: 0xFF0EA5E9,
      iconKey: 'english',
      allowedClasses: _allClasses,
      chapters: [
        _ChapterSeed(
          id: 'grammar',
          title: 'Grammar essentials',
          description: 'Temps simples et structures de phrases.',
          lessons: [
            _LessonSeed(
              id: 'gram_1',
              title: 'Present simple vs present continuous',
              summary: 'Savoir quand utiliser chaque temps.',
              estimatedMinutes: 14,
              sections: [
                LessonContentSection(
                  title: 'Rule',
                  body:
                      'Present simple for habits, present continuous for actions happening now.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'gram1_q1',
                  prompt: 'I ___ football every Saturday.',
                  options: const ['am playing', 'play', 'plays'],
                  correctIndex: 1,
                  explanation: 'Habit: present simple -> play.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _SubjectSeed(
      id: 'history',
      title: 'Histoire-Geographie',
      description: 'Analyser les evenements et dynamiques territoriales.',
      colorHex: 0xFFB45309,
      iconKey: 'history',
      allowedClasses: _allClasses,
      chapters: [
        _ChapterSeed(
          id: 'civilizations',
          title: 'Civilisations et echanges',
          description: 'Repere chronologique et grands changements.',
          lessons: [
            _LessonSeed(
              id: 'hist_1',
              title: 'Routes commerciales historiques',
              summary: 'Comprendre l\'impact des echanges sur les societes.',
              estimatedMinutes: 13,
              sections: [
                LessonContentSection(
                  title: 'Synthese',
                  body:
                      'Les routes commerciales ont accelere la circulation des idees, des techniques et des cultures.',
                ),
              ],
              miniQuiz: [
                LessonMiniQuizQuestion(
                  id: 'hist1_q1',
                  prompt: 'Quel effet majeur des routes commerciales?',
                  options: const [
                    'Isolement culturel',
                    'Circulation des idees',
                    'Suppression des villes',
                  ],
                  correctIndex: 1,
                  explanation:
                      'Elles favorisent les echanges et la diffusion des idees.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

class _LessonRuntimeState {
  _LessonRuntimeState({required this.progress, required this.isFavorite});

  double progress;
  bool isFavorite;
}

class _SubjectSeed {
  const _SubjectSeed({
    required this.id,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconKey,
    required this.allowedClasses,
    this.allowedSeries = const [],
    required this.chapters,
  });

  final String id;
  final String title;
  final String description;
  final int colorHex;
  final String iconKey;
  final List<String> allowedClasses;
  final List<String> allowedSeries;
  final List<_ChapterSeed> chapters;
}

class _ChapterSeed {
  const _ChapterSeed({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
  });

  final String id;
  final String title;
  final String description;
  final List<_LessonSeed> lessons;
}

class _LessonSeed {
  const _LessonSeed({
    required this.id,
    required this.title,
    required this.summary,
    required this.estimatedMinutes,
    required this.sections,
    required this.miniQuiz,
  });

  final String id;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final List<LessonContentSection> sections;
  final List<LessonMiniQuizQuestion> miniQuiz;
}
