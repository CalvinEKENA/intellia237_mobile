import 'video_import_screen.dart';
import '../domain/admin_content_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../learn/domain/content_block.dart';
import '../application/flow_composer_providers.dart';
import '../domain/educational_media.dart';
import '../domain/notebooklm_import.dart';

/// Assistant d'import des productions NotebookLM.
///
/// Registre de décisions : NotebookLM produit, INTELLIA valide. L'assistant ne
/// suppose donc aucune structure d'export — l'auteur désigne ses fichiers, les
/// classe, déclare leur provenance, vérifie ce qui sera créé, puis importe.
///
/// Rien n'entre publié. Un artefact importé arrive en brouillon et suit le
/// même parcours éditorial que le reste : c'est ce qui distingue un atelier
/// d'un canal de diffusion directe.
class NotebookLmImportWizardScreen extends ConsumerStatefulWidget {
  const NotebookLmImportWizardScreen({
    required this.classLevel,
    this.targetLesson,
    this.artifacts = const <NotebookArtifact>[],
    super.key,
  });

  final String classLevel;
  final AdminLessonModel? targetLesson;

  /// Artefacts déjà choisis. Le sélecteur de fichiers les fournit en usage
  /// réel ; les tests les injectent directement.
  final List<NotebookArtifact> artifacts;

  @override
  ConsumerState<NotebookLmImportWizardScreen> createState() =>
      _NotebookLmImportWizardScreenState();
}

class _NotebookLmImportWizardScreenState
    extends ConsumerState<NotebookLmImportWizardScreen> {
  late List<NotebookArtifact> _artifacts = widget.artifacts;
  int _step = 0;

  final _subject = TextEditingController();
  final _chapter = TextEditingController();
  final _lesson = TextEditingController();
  final _notebookId = TextEditingController();
  final _sourceTitle = TextEditingController();
  final _model = TextEditingController();
  final _notes = TextEditingController();

  final bool _importing = false;
  String? _outcome;

  @override
  void dispose() {
    for (final controller in [
      _subject,
      _chapter,
      _lesson,
      _notebookId,
      _sourceTitle,
      _model,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<NotebookArtifact> get _accepted => [
    for (final artifact in _artifacts)
      if (NotebookImportPolicy.inspect(artifact).isAccepted) artifact,
  ];

  List<NotebookArtifact> get _rejected => [
    for (final artifact in _artifacts)
      if (!NotebookImportPolicy.inspect(artifact).isAccepted) artifact,
  ];

  String _storagePathFor(
    NotebookArtifact artifact,
  ) => EducationalAssetPath.build(
    scope: ref.read(contentAuthoringScopeProvider),
    classLevel: widget.classLevel,
    subjectId: _subject.text.trim().isEmpty ? 'divers' : _subject.text.trim(),
    lessonId: _lesson.text.trim().isEmpty ? 'sans-lecon' : _lesson.text.trim(),
    assetId: 'nb-${artifact.fileName.hashCode.abs()}',
    fileName: artifact.fileName,
  );

  List<ContentBlock> get _plannedBlocks => NotebookImportPolicy.plannedBlocks(
    artifacts: _accepted,
    storagePathFor: _storagePathFor,
  );

  bool get _canContinue => switch (_step) {
    0 => _accepted.isNotEmpty,
    1 => _subject.text.trim().isNotEmpty,
    _ => true,
  };

  Future<void> _import() async {
    setState(() {
      _outcome =
          'Aucun fichier enregistré. Ouvrez une leçon en brouillon dans le Studio, puis choisissez « Importer depuis NotebookLM ».';
      _step = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetLesson case final lesson?) {
      if (lesson.isPublished) {
        return const Scaffold(
          body: Center(child: Text('Choisissez une leçon en brouillon.')),
        );
      }
      return VideoImportScreen(lesson: lesson, notebook: true);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Importer depuis NotebookLM')),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: switch (_step) {
                0 => _FilesStep(
                  accepted: _accepted,
                  rejected: _rejected,
                  onRemove: (artifact) => setState(
                    () => _artifacts = [..._artifacts]..remove(artifact),
                  ),
                ),
                1 => _ClassificationStep(
                  classLevel: widget.classLevel,
                  subject: _subject,
                  chapter: _chapter,
                  lesson: _lesson,
                  onChanged: () => setState(() {}),
                ),
                2 => _ProvenanceStep(
                  notebookId: _notebookId,
                  sourceTitle: _sourceTitle,
                  model: _model,
                  notes: _notes,
                ),
                3 => _PreviewStep(blocks: _plannedBlocks),
                _ => _DoneStep(message: _outcome ?? ''),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              // Les libellés grandissent avec l'échelle de texte : une ligne
              // rigide déborderait sur un téléphone étroit.
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: IntelliaSpacing.sm,
                runSpacing: IntelliaSpacing.xs,
                children: [
                  if (_step > 0 && _step < 4)
                    TextButton(
                      key: const ValueKey('notebook-back'),
                      onPressed: () => setState(() => _step -= 1),
                      child: const Text('Retour'),
                    ),
                  if (_step < 3)
                    FilledButton(
                      key: const ValueKey('notebook-next'),
                      onPressed: _canContinue
                          ? () => setState(() => _step += 1)
                          : null,
                      child: const Text('Continuer'),
                    )
                  else if (_step == 3)
                    FilledButton(
                      key: const ValueKey('notebook-import'),
                      onPressed: _importing ? null : _import,
                      child: const Text('Importer en brouillon'),
                    )
                  else
                    FilledButton(
                      key: const ValueKey('notebook-close'),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Terminer'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  static const _labels = [
    'Fichiers',
    'Classement',
    'Provenance',
    'Aperçu',
    'Import',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: IntelliaSpacing.md,
      vertical: IntelliaSpacing.sm,
    ),
    child: Row(
      children: [
        for (var i = 0; i < _labels.length; i++)
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[i],
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _FilesStep extends StatelessWidget {
  const _FilesStep({
    required this.accepted,
    required this.rejected,
    required this.onRemove,
  });

  final List<NotebookArtifact> accepted;
  final List<NotebookArtifact> rejected;
  final ValueChanged<NotebookArtifact> onRemove;

  @override
  Widget build(BuildContext context) {
    if (accepted.isEmpty && rejected.isEmpty) {
      return const Text(
        'Choisis les fichiers exportés depuis NotebookLM : Audio Overview, '
        'infographie, fiche de synthèse, vidéo.',
        key: ValueKey('notebook-files-empty'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final artifact in accepted)
          ListTile(
            key: ValueKey('notebook-accepted-${artifact.fileName}'),
            leading: const Icon(Icons.check_circle_outline),
            title: Text(artifact.fileName),
            subtitle: Text(artifact.mimeType),
            trailing: IconButton(
              onPressed: () => onRemove(artifact),
              icon: const Icon(Icons.close),
            ),
          ),
        if (rejected.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            'Non importables',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final artifact in rejected)
            ListTile(
              key: ValueKey('notebook-rejected-${artifact.fileName}'),
              leading: Icon(
                Icons.block,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(artifact.fileName),
              subtitle: Text(
                NotebookImportPolicy.inspect(artifact).rejection ?? '',
              ),
            ),
        ],
      ],
    );
  }
}

class _ClassificationStep extends StatelessWidget {
  const _ClassificationStep({
    required this.classLevel,
    required this.subject,
    required this.chapter,
    required this.lesson,
    required this.onChanged,
  });

  final String classLevel;
  final TextEditingController subject;
  final TextEditingController chapter;
  final TextEditingController lesson;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        decoration: InputDecoration(
          labelText: 'Niveau',
          hintText: classLevel,
          enabled: false,
        ),
      ),
      TextField(
        key: const ValueKey('notebook-subject'),
        controller: subject,
        decoration: const InputDecoration(labelText: 'Matière'),
        onChanged: (_) => onChanged(),
      ),
      TextField(
        key: const ValueKey('notebook-chapter'),
        controller: chapter,
        decoration: const InputDecoration(labelText: 'Chapitre'),
      ),
      TextField(
        key: const ValueKey('notebook-lesson'),
        controller: lesson,
        decoration: const InputDecoration(
          labelText: 'Leçon existante, ou vide pour une nouvelle',
        ),
      ),
    ],
  );
}

class _ProvenanceStep extends StatelessWidget {
  const _ProvenanceStep({
    required this.notebookId,
    required this.sourceTitle,
    required this.model,
    required this.notes,
  });

  final TextEditingController notebookId;
  final TextEditingController sourceTitle;
  final TextEditingController model;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ce qui n’est pas connu reste vide : la provenance ne se devine pas.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: IntelliaSpacing.xs),
      TextField(
        key: const ValueKey('notebook-id'),
        controller: notebookId,
        decoration: const InputDecoration(labelText: 'Notebook source'),
      ),
      TextField(
        key: const ValueKey('notebook-source-title'),
        controller: sourceTitle,
        decoration: const InputDecoration(labelText: 'Titre source'),
      ),
      TextField(
        key: const ValueKey('notebook-model'),
        controller: model,
        decoration: const InputDecoration(labelText: 'Modèle utilisé'),
      ),
      TextField(
        key: const ValueKey('notebook-notes'),
        controller: notes,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Notes internes'),
      ),
    ],
  );
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({required this.blocks});

  final List<ContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Text(
        'Aucun bloc ne sera créé : vérifie les fichiers choisis.',
        key: ValueKey('notebook-preview-empty'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${blocks.length} bloc(s) seront créés en brouillon.',
          key: const ValueKey('notebook-preview-count'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        for (final block in blocks)
          ListTile(
            key: ValueKey('notebook-preview-${block.id}'),
            leading: const Icon(Icons.widgets_outlined),
            title: Text(block.type.name),
            subtitle: Text(
              block is MediaBlock ? block.storagePath : 'Bloc de texte',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        message,
        key: const ValueKey('notebook-outcome'),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: IntelliaSpacing.xs),
      const Text(
        'Rien n’est publié : ces blocs suivent le parcours éditorial comme '
        'tout autre contenu.',
        key: ValueKey('notebook-draft-notice'),
      ),
    ],
  );
}
