import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/design_tokens.dart';
import '../../flow/domain/flow_subject.dart';
import '../application/admin_content_providers.dart';
import '../application/flow_composer_providers.dart';
import '../data/course_page_import_service.dart';
import '../domain/admin_content_models.dart';
import '../domain/course_page_import.dart';

enum _ImportStep { pages, reading, review, done }

/// Pages de cours photographiées ou scannées → leçon, QCM, exercices, FLOW.
///
/// Registre de décisions : l'assistant ne publie rien. Gemini lit les pages,
/// l'auteur relit tout — il corrige, écarte — puis crée des brouillons, qui
/// suivent ensuite le parcours éditorial habituel. Les droits sur les pages
/// sont déclarés avant toute lecture.
class CoursePageImportScreen extends ConsumerStatefulWidget {
  const CoursePageImportScreen({
    required this.chapter,
    this.initialPages = const <CoursePageFile>[],
    super.key,
  });

  final AdminChapterModel chapter;

  /// Pages déjà choisies. L'appareil photo et le sélecteur les fournissent en
  /// usage réel ; les tests les injectent directement.
  final List<CoursePageFile> initialPages;

  @override
  ConsumerState<CoursePageImportScreen> createState() =>
      _CoursePageImportScreenState();
}

class _CoursePageImportScreenState
    extends ConsumerState<CoursePageImportScreen> {
  late final List<CoursePageFile> _pages = [...widget.initialPages];
  final _picker = ImagePicker();

  _ImportStep _step = _ImportStep.pages;
  bool _rightsConfirmed = false;
  String? _flowSubjectId;
  String _language = 'fr';
  String _progress = '';
  String? _error;
  bool _creating = false;
  CoursePageImportDraft? _draft;
  CoursePageImportOutcome? _outcome;

  String get _subjectLabel {
    final subjects = ref
        .watch(adminSubjectsProvider(widget.chapter.classLevel))
        .valueOrNull;
    for (final subject in subjects ?? const <AdminSubjectModel>[]) {
      if (subject.id == widget.chapter.subjectId) return subject.title;
    }
    return '';
  }

  String get _effectiveFlowSubject =>
      _flowSubjectId ?? CoursePageDraftPlanner.flowSubjectIdFor(_subjectLabel);

  int get _totalBytes =>
      _pages.fold<int>(0, (sum, page) => sum + page.bytes.lengthInBytes);

  // ── Pages ────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (photo != null) await _addPickedImage(photo);
  }

  Future<void> _pickPhotos() async {
    final photos = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2000,
    );
    for (final photo in photos) {
      await _addPickedImage(photo);
    }
  }

  Future<void> _addPickedImage(XFile photo) async {
    final bytes = await photo.readAsBytes();
    _addPage(
      CoursePageFile(
        name: photo.name,
        bytes: bytes,
        // L'appareil photo rend du JPEG quand il compresse.
        mimeType: _mimeFor(photo.name) ?? 'image/jpeg',
      ),
    );
  }

  Future<void> _pickDocuments() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    for (final file in files) {
      final mimeType = _mimeFor(file.name);
      if (mimeType == null) continue;
      _addPage(
        CoursePageFile(
          name: file.name,
          bytes: await file.readAsBytes(),
          mimeType: mimeType,
        ),
      );
    }
  }

  void _addPage(CoursePageFile page) {
    if (!mounted) return;
    if (_pages.length >= CoursePageImportService.maxPages) {
      setState(
        () => _error =
            '${CoursePageImportService.maxPages} pages au plus par import.',
      );
      return;
    }
    setState(() {
      _pages.add(page);
      _error = null;
    });
  }

  void _move(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _pages.length) return;
    setState(() {
      final page = _pages.removeAt(index);
      _pages.insert(target, page);
    });
  }

  static String? _mimeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  // ── Lecture et création ──────────────────────────────────

  Future<void> _read() async {
    setState(() {
      _step = _ImportStep.reading;
      _error = null;
      _progress = 'Dépôt des pages…';
    });
    try {
      final draft = await ref
          .read(coursePageImportServiceProvider)
          .read(
            scope: ref.read(contentAuthoringScopeProvider),
            classLevel: widget.chapter.classLevel,
            subjectId: widget.chapter.subjectId,
            subjectLabel: _subjectLabel,
            chapterTitle: widget.chapter.title,
            pages: List.unmodifiable(_pages),
            language: _language,
            onUploaded: (done, total) {
              if (!mounted) return;
              setState(
                () => _progress = done < total
                    ? 'Dépôt des pages : $done/$total'
                    : 'Lecture des pages par Gemini… jusqu’à deux minutes.',
              );
            },
          );
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _step = _ImportStep.review;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _step = _ImportStep.pages;
        _error = _readingError(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _step = _ImportStep.pages;
        _error = '$error';
      });
    }
  }

  static String _readingError(FirebaseFunctionsException error) =>
      switch (error.code) {
        'resource-exhausted' =>
          'Le quota de lecture du jour est atteint. Réessayez demain.',
        'permission-denied' =>
          'Ce compte ne peut pas importer de pages pour ce périmètre.',
        'invalid-argument' =>
          'Ces fichiers ne peuvent pas être lus : images JPEG, PNG ou WebP, '
              'ou PDF, 14 Mo au plus ensemble.',
        'deadline-exceeded' || 'unavailable' =>
          'La lecture a pris trop de temps. Réessayez avec moins de pages.',
        _ => 'La lecture a échoué (${error.code}). Réessayez.',
      };

  Future<void> _create() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(coursePageImportServiceProvider)
          .createDrafts(
            draft: draft,
            chapter: widget.chapter,
            subjectLabel: _subjectLabel,
            flowSubjectId: _effectiveFlowSubject,
            scope: ref.read(contentAuthoringScopeProvider),
            authorUid: ref.read(contentActorProvider)?.uid ?? '',
            pageCount: _pages.length,
            contentActions: ref.read(adminContentActionsProvider),
            flowRepository: ref.read(adminFlowRepositoryProvider),
          );
      ref.invalidate(adminFlowItemsProvider(widget.chapter.classLevel));
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _step = _ImportStep.done;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  // ── Écran ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importer des pages de cours')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              children: [
                _ContextCard(
                  classLevel: widget.chapter.classLevel,
                  subject: _subjectLabel,
                  chapter: widget.chapter.title,
                ),
                const SizedBox(height: IntelliaSpacing.md),
                if (_error != null) ...[
                  Text(
                    _error!,
                    key: const ValueKey('page-import-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                ],
                ...switch (_step) {
                  _ImportStep.pages => _pagesStep(context),
                  _ImportStep.reading => [
                    const SizedBox(height: IntelliaSpacing.xl),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: IntelliaSpacing.md),
                    Text(
                      _progress,
                      key: const ValueKey('page-import-progress'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  _ImportStep.review => _reviewStep(context, _draft!),
                  _ImportStep.done => _doneStep(context, _outcome!),
                },
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Align(
                alignment: Alignment.centerRight,
                child: switch (_step) {
                  _ImportStep.pages => FilledButton.icon(
                    key: const ValueKey('page-import-read'),
                    onPressed:
                        _pages.isEmpty ||
                            !_rightsConfirmed ||
                            _totalBytes > CoursePageImportService.maxTotalBytes
                        ? null
                        : _read,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Lire les pages'),
                  ),
                  _ImportStep.reading => const SizedBox.shrink(),
                  _ImportStep.review => FilledButton.icon(
                    key: const ValueKey('page-import-create'),
                    onPressed: _creating ? null : _create,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Créer les brouillons'),
                  ),
                  _ImportStep.done => FilledButton(
                    key: const ValueKey('page-import-close'),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Terminer'),
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _pagesStep(BuildContext context) {
    final theme = Theme.of(context);
    final megabytes = (_totalBytes / (1024 * 1024)).toStringAsFixed(1);
    return [
      Text(
        'Photographiez les pages à plat, bien éclairées, une page par photo. '
        'Un PDF peut en contenir plusieurs.',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: IntelliaSpacing.sm),
      Wrap(
        spacing: IntelliaSpacing.sm,
        runSpacing: IntelliaSpacing.xs,
        children: [
          FilledButton.tonalIcon(
            key: const ValueKey('page-import-camera'),
            onPressed: _takePhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Photographier une page'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('page-import-gallery'),
            onPressed: _pickPhotos,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choisir des photos'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('page-import-files'),
            onPressed: _pickDocuments,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF ou image'),
          ),
        ],
      ),
      const SizedBox(height: IntelliaSpacing.md),
      for (var index = 0; index < _pages.length; index++)
        Card(
          child: ListTile(
            key: ValueKey('page-import-page-$index'),
            leading: _pages[index].isPdf
                ? const Icon(Icons.picture_as_pdf_outlined, size: 36)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(IntelliaRadii.small),
                    child: Image.memory(
                      _pages[index].bytes,
                      width: 40,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_outlined),
                    ),
                  ),
            title: Text('Page ${index + 1}'),
            subtitle: Text(
              '${_pages[index].name} · '
              '${(_pages[index].bytes.lengthInBytes / 1024).round()} Ko',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Monter',
                  onPressed: index == 0 ? null : () => _move(index, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Descendre',
                  onPressed: index == _pages.length - 1
                      ? null
                      : () => _move(index, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  key: ValueKey('page-import-remove-$index'),
                  tooltip: 'Retirer',
                  onPressed: () => setState(() => _pages.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      if (_pages.isNotEmpty) ...[
        Text(
          '${_pages.length} fichier(s) · $megabytes Mo sur 14 Mo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _totalBytes > CoursePageImportService.maxTotalBytes
                ? theme.colorScheme.error
                : null,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
      ],
      DropdownButtonFormField<String>(
        key: const ValueKey('page-import-flow-subject'),
        initialValue: _effectiveFlowSubject,
        decoration: const InputDecoration(
          labelText: 'Matière des cartes FLOW et des exercices',
        ),
        items: [
          for (final subject in FlowSubjects.all)
            DropdownMenuItem(value: subject.id, child: Text(subject.label)),
        ],
        onChanged: (value) => setState(() => _flowSubjectId = value),
      ),
      const SizedBox(height: IntelliaSpacing.sm),
      DropdownButtonFormField<String>(
        key: const ValueKey('page-import-language'),
        initialValue: _language,
        decoration: const InputDecoration(labelText: 'Langue des contenus'),
        items: const [
          DropdownMenuItem(value: 'fr', child: Text('Français')),
          DropdownMenuItem(value: 'en', child: Text('English')),
        ],
        onChanged: (value) => setState(() => _language = value ?? 'fr'),
      ),
      const SizedBox(height: IntelliaSpacing.sm),
      CheckboxListTile(
        key: const ValueKey('page-import-rights'),
        contentPadding: EdgeInsets.zero,
        value: _rightsConfirmed,
        onChanged: (value) => setState(() => _rightsConfirmed = value ?? false),
        title: const Text(
          'Je détiens les droits sur ces pages, ou leur usage pédagogique dans '
          'INTELLIA237 est autorisé.',
        ),
        subtitle: const Text(
          'Les pages d’un manuel publié appartiennent à son éditeur.',
        ),
      ),
    ];
  }

  List<Widget> _reviewStep(BuildContext context, CoursePageImportDraft draft) {
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(
        top: IntelliaSpacing.lg,
        bottom: IntelliaSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    Widget field({
      required String keyName,
      required String label,
      required String value,
      required ValueChanged<String> onChanged,
      int maxLines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(top: IntelliaSpacing.xs),
      child: TextFormField(
        key: ValueKey(keyName),
        initialValue: value,
        minLines: 1,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );

    return [
      Text(
        'Relisez tout : Gemini peut mal lire une formule ou une page floue. '
        'Rien n’est publié — ce que vous gardez devient brouillon.',
        style: theme.textTheme.bodyMedium,
      ),
      if (draft.warnings.isNotEmpty)
        Card(
          key: const ValueKey('page-import-warnings'),
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final warning in draft.warnings) Text('• $warning'),
              ],
            ),
          ),
        ),

      heading('Leçon'),
      SwitchListTile(
        key: const ValueKey('page-import-include-lesson'),
        contentPadding: EdgeInsets.zero,
        value: draft.includeLesson,
        onChanged: (value) => setState(() => draft.includeLesson = value),
        title: const Text('Créer la leçon dans ce chapitre'),
      ),
      if (draft.includeLesson) ...[
        field(
          keyName: 'page-import-lesson-title',
          label: 'Titre',
          value: draft.lessonTitle,
          onChanged: (value) => draft.lessonTitle = value,
        ),
        field(
          keyName: 'page-import-lesson-summary',
          label: 'Résumé',
          value: draft.lessonSummary,
          onChanged: (value) => draft.lessonSummary = value,
          maxLines: 3,
        ),
        for (var index = 0; index < draft.sections.length; index++)
          ExpansionTile(
            key: ValueKey('page-import-section-$index'),
            tilePadding: EdgeInsets.zero,
            title: Text(
              draft.sections[index].title.isEmpty
                  ? 'Section ${index + 1}'
                  : draft.sections[index].title,
            ),
            children: [
              field(
                keyName: 'page-import-section-title-$index',
                label: 'Titre de section',
                value: draft.sections[index].title,
                onChanged: (value) => draft.sections[index].title = value,
              ),
              field(
                keyName: 'page-import-section-body-$index',
                label: 'Contenu',
                value: draft.sections[index].body,
                onChanged: (value) => draft.sections[index].body = value,
                maxLines: 12,
              ),
            ],
          ),
      ],

      heading('QCM (${draft.quizQuestions.length})'),
      SwitchListTile(
        key: const ValueKey('page-import-quiz-lesson'),
        contentPadding: EdgeInsets.zero,
        value: draft.attachQuizToLesson,
        onChanged: (value) => setState(() => draft.attachQuizToLesson = value),
        title: const Text('Mini-quiz à la fin de la leçon'),
      ),
      SwitchListTile(
        key: const ValueKey('page-import-quiz-hub'),
        contentPadding: EdgeInsets.zero,
        value: draft.addQuizToHub,
        onChanged: (value) => setState(() => draft.addQuizToHub = value),
        title: const Text('Quiz d’entraînement dans l’onglet Quiz'),
      ),
      for (var index = 0; index < draft.quizQuestions.length; index++)
        _ReviewCard(
          keyName: 'page-import-quiz-$index',
          included: draft.quizQuestions[index].include,
          label: 'Question ${index + 1}',
          onIncluded: (value) =>
              setState(() => draft.quizQuestions[index].include = value),
          children: [
            field(
              keyName: 'page-import-quiz-prompt-$index',
              label: 'Question',
              value: draft.quizQuestions[index].prompt,
              onChanged: (value) => draft.quizQuestions[index].prompt = value,
              maxLines: 3,
            ),
            for (
              var option = 0;
              option < draft.quizQuestions[index].options.length;
              option++
            )
              Row(
                children: [
                  IconButton(
                    tooltip: 'Bonne réponse',
                    onPressed: () => setState(
                      () => draft.quizQuestions[index].correctIndex = option,
                    ),
                    icon: Icon(
                      draft.quizQuestions[index].correctIndex == option
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: draft.quizQuestions[index].correctIndex == option
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: draft.quizQuestions[index].options[option],
                      decoration: InputDecoration(
                        labelText: 'Option ${option + 1}',
                      ),
                      onChanged: (value) =>
                          draft.quizQuestions[index].options[option] = value,
                    ),
                  ),
                ],
              ),
            field(
              keyName: 'page-import-quiz-explanation-$index',
              label: 'Explication',
              value: draft.quizQuestions[index].explanation,
              onChanged: (value) =>
                  draft.quizQuestions[index].explanation = value,
              maxLines: 3,
            ),
          ],
        ),

      heading('Exercices (${draft.exercises.length})'),
      Text(
        'Chaque exercice devient une carte FLOW : l’élève cherche, puis '
        'découvre le corrigé.',
        style: theme.textTheme.bodySmall,
      ),
      for (var index = 0; index < draft.exercises.length; index++)
        _ReviewCard(
          keyName: 'page-import-exercise-$index',
          included: draft.exercises[index].include,
          label: 'Exercice ${index + 1}',
          onIncluded: (value) =>
              setState(() => draft.exercises[index].include = value),
          children: [
            field(
              keyName: 'page-import-exercise-statement-$index',
              label: 'Énoncé',
              value: draft.exercises[index].statement,
              onChanged: (value) => draft.exercises[index].statement = value,
              maxLines: 6,
            ),
            field(
              keyName: 'page-import-exercise-solution-$index',
              label: 'Corrigé',
              value: draft.exercises[index].solution,
              onChanged: (value) => draft.exercises[index].solution = value,
              maxLines: 10,
            ),
          ],
        ),

      heading('Cartes FLOW (${draft.flowCards.length})'),
      for (var index = 0; index < draft.flowCards.length; index++)
        _ReviewCard(
          keyName: 'page-import-flow-$index',
          included: draft.flowCards[index].include,
          label: switch (draft.flowCards[index].kind) {
            PageFlowCardKind.notion => 'Notion',
            PageFlowCardKind.question => 'Question',
            PageFlowCardKind.quiz => 'Mini-quiz',
          },
          onIncluded: (value) =>
              setState(() => draft.flowCards[index].include = value),
          children: [
            field(
              keyName: 'page-import-flow-title-$index',
              label: 'Titre',
              value: draft.flowCards[index].title,
              onChanged: (value) => draft.flowCards[index].title = value,
            ),
            ...switch (draft.flowCards[index].kind) {
              PageFlowCardKind.notion => [
                field(
                  keyName: 'page-import-flow-insight-$index',
                  label: 'Idée clé',
                  value: draft.flowCards[index].insight,
                  onChanged: (value) => draft.flowCards[index].insight = value,
                  maxLines: 3,
                ),
              ],
              PageFlowCardKind.question => [
                field(
                  keyName: 'page-import-flow-question-$index',
                  label: 'Question',
                  value: draft.flowCards[index].question,
                  onChanged: (value) =>
                      draft.flowCards[index].question = value,
                  maxLines: 3,
                ),
                field(
                  keyName: 'page-import-flow-answer-$index',
                  label: 'Réponse',
                  value: draft.flowCards[index].answer,
                  onChanged: (value) => draft.flowCards[index].answer = value,
                  maxLines: 4,
                ),
              ],
              PageFlowCardKind.quiz => [
                field(
                  keyName: 'page-import-flow-question-$index',
                  label: 'Question',
                  value: draft.flowCards[index].question,
                  onChanged: (value) =>
                      draft.flowCards[index].question = value,
                  maxLines: 3,
                ),
                for (
                  var option = 0;
                  option < draft.flowCards[index].options.length;
                  option++
                )
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Bonne réponse',
                        onPressed: () => setState(
                          () => draft.flowCards[index].correctIndex = option,
                        ),
                        icon: Icon(
                          draft.flowCards[index].correctIndex == option
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: draft.flowCards[index].options[option],
                          decoration: InputDecoration(
                            labelText: 'Option ${option + 1}',
                          ),
                          onChanged: (value) =>
                              draft.flowCards[index].options[option] = value,
                        ),
                      ),
                    ],
                  ),
              ],
            },
          ],
        ),
    ];
  }

  List<Widget> _doneStep(BuildContext context, CoursePageImportOutcome outcome) {
    final theme = Theme.of(context);
    return [
      Icon(
        Icons.task_alt_rounded,
        size: 44,
        color: theme.colorScheme.primary,
      ),
      const SizedBox(height: IntelliaSpacing.sm),
      Text(
        'Brouillons créés',
        key: const ValueKey('page-import-done'),
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: IntelliaSpacing.sm),
      if (outcome.lessonId != null)
        const Text('• La leçon, dans ce chapitre.'),
      if (outcome.quizCreated)
        const Text('• Le quiz d’entraînement, dans Quiz.'),
      if (outcome.flowItemsCreated > 0)
        Text(
          '• ${outcome.flowItemsCreated} carte(s) FLOW et exercice(s), dans '
          'Flow.',
        ),
      const SizedBox(height: IntelliaSpacing.md),
      Text(
        'Rien n’est encore visible pour les élèves : relisez, puis publiez '
        'chaque contenu depuis le Studio.',
        style: theme.textTheme.bodyMedium,
      ),
      if (outcome.failures.isNotEmpty) ...[
        const SizedBox(height: IntelliaSpacing.md),
        Text(
          'Non créé :',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        for (final failure in outcome.failures)
          Text(
            '• $failure',
            style: TextStyle(color: theme.colorScheme.error),
          ),
      ],
    ];
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.classLevel,
    required this.subject,
    required this.chapter,
  });

  final String classLevel;
  final String subject;
  final String chapter;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(chapter),
      subtitle: Text(
        [classLevel, if (subject.isNotEmpty) subject].join(' · '),
      ),
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.keyName,
    required this.included,
    required this.label,
    required this.onIncluded,
    required this.children,
  });

  final String keyName;
  final bool included;
  final String label;
  final ValueChanged<bool> onIncluded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey(keyName),
    child: Padding(
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            key: ValueKey('$keyName-include'),
            contentPadding: EdgeInsets.zero,
            value: included,
            onChanged: (value) => onIncluded(value ?? false),
            title: Text(label),
            subtitle: included ? null : const Text('Écarté'),
          ),
          if (included) ...children,
        ],
      ),
    ),
  );
}
