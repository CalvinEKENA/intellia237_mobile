import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/admin_content_providers.dart';
import '../application/notebook_import_service.dart';
import '../data/educational_media_service.dart';
import '../domain/admin_content_models.dart';
import '../domain/educational_media.dart';

/// Assistant d'import des productions NotebookLM (image / audio / MP4 / PDF).
///
/// Registre de décisions : NotebookLM produit, INTELLIA valide. L'import
/// **persiste réellement** — chaque fichier choisi est téléversé vers son chemin
/// canonique dans Storage, puis rattaché comme bloc à une **leçon brouillon**,
/// enregistrée sans être publiée. Aucun faux succès, aucune donnée fictive :
/// s'il n'y a pas de leçon cible, on le dit et on n'invente rien.
class NotebookLmImportWizardScreen extends ConsumerStatefulWidget {
  const NotebookLmImportWizardScreen({
    required this.classLevel,
    this.targetLesson,
    this.initialFiles = const <PickedNotebookFile>[],
    super.key,
  });

  final String classLevel;
  final AdminLessonModel? targetLesson;

  /// Fichiers déjà choisis. Le sélecteur les fournit en usage réel ; les tests
  /// les injectent directement (avec leurs octets), sans plugin natif.
  final List<PickedNotebookFile> initialFiles;

  @override
  ConsumerState<NotebookLmImportWizardScreen> createState() =>
      _NotebookLmImportWizardScreenState();
}

class _NotebookLmImportWizardScreenState
    extends ConsumerState<NotebookLmImportWizardScreen> {
  late List<PickedNotebookFile> _files = [...widget.initialFiles];
  bool _importing = false;
  String? _error;
  AdminLessonModel? _imported;

  static const _allowedExtensions = <String>[
    'mp4',
    'mp3',
    'm4a',
    'aac',
    'png',
    'jpg',
    'jpeg',
    'webp',
    'pdf',
  ];

  List<PickedNotebookFile> get _accepted => [
    for (final file in _files)
      if (NotebookImportService.mediaTypeFor(file.mimeType) != null) file,
  ];

  List<PickedNotebookFile> get _rejected => [
    for (final file in _files)
      if (NotebookImportService.mediaTypeFor(file.mimeType) == null) file,
  ];

  static String _mimeForExtension(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a')) return 'audio/m4a';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  Future<void> _choose() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );
      if (!mounted || files.isEmpty) return;
      final picked = <PickedNotebookFile>[];
      for (final file in files) {
        picked.add(
          PickedNotebookFile(
            name: file.name,
            bytes: await file.readAsBytes(),
            mimeType: _mimeForExtension(file.name),
          ),
        );
      }
      if (!mounted) return;
      setState(() => _files = [..._files, ...picked]);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'La sélection de fichiers a échoué.');
    }
  }

  Future<void> _import(AdminLessonModel lesson) async {
    if (_accepted.isEmpty) return;
    setState(() {
      _importing = true;
      _error = null;
    });
    try {
      final service = NotebookImportService(
        ref.read(educationalMediaServiceProvider),
      );
      final updated = await service.importInto(lesson, _accepted);
      await ref.read(adminContentActionsProvider).saveLesson(updated);
      if (!mounted) return;
      setState(() {
        _importing = false;
        _imported = updated;
      });
    } on MediaRejectedException catch (error) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _error = error.reason;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _error = 'L’import n’a pas abouti. Réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.targetLesson;
    if (lesson == null) {
      return const _NoTargetLessonView();
    }
    if (lesson.isPublished) {
      return Scaffold(
        appBar: AppBar(title: const Text('Importer depuis NotebookLM')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(IntelliaSpacing.xl),
            child: Text(
              'Choisissez une leçon en brouillon : on n’ajoute jamais de '
              'contenu à une leçon déjà publiée.',
              key: ValueKey('notebook-needs-draft'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Importer depuis NotebookLM')),
      body: SafeArea(
        child: _imported != null
            ? _ImportedView(lesson: _imported!)
            : _PickView(
                lesson: lesson,
                accepted: _accepted,
                rejected: _rejected,
                importing: _importing,
                error: _error,
                onChoose: _choose,
                onRemove: (file) =>
                    setState(() => _files = [..._files]..remove(file)),
                onImport: () => _import(lesson),
              ),
      ),
    );
  }
}

class _PickView extends StatelessWidget {
  const _PickView({
    required this.lesson,
    required this.accepted,
    required this.rejected,
    required this.importing,
    required this.error,
    required this.onChoose,
    required this.onRemove,
    required this.onImport,
  });

  final AdminLessonModel lesson;
  final List<PickedNotebookFile> accepted;
  final List<PickedNotebookFile> rejected;
  final bool importing;
  final String? error;
  final VoidCallback onChoose;
  final ValueChanged<PickedNotebookFile> onRemove;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            children: [
              Text(
                'Les fichiers seront rattachés en brouillon à « ${lesson.title} ». '
                'Formats : image, audio, MP4, PDF.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('notebook-choose-files'),
                onPressed: importing ? null : onChoose,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Choisir des fichiers'),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              if (accepted.isEmpty && rejected.isEmpty)
                const Text(
                  'Aucun fichier choisi pour l’instant.',
                  key: ValueKey('notebook-files-empty'),
                ),
              for (final file in accepted)
                ListTile(
                  key: ValueKey('notebook-accepted-${file.name}'),
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(file.name),
                  subtitle: Text(file.mimeType),
                  trailing: IconButton(
                    onPressed: importing ? null : () => onRemove(file),
                    icon: const Icon(Icons.close),
                  ),
                ),
              for (final file in rejected)
                ListTile(
                  key: ValueKey('notebook-rejected-${file.name}'),
                  leading: Icon(
                    Icons.block,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(file.name),
                  subtitle: const Text('Format non pris en charge'),
                  trailing: IconButton(
                    onPressed: importing ? null : () => onRemove(file),
                    icon: const Icon(Icons.close),
                  ),
                ),
              if (error != null) ...[
                const SizedBox(height: IntelliaSpacing.sm),
                Text(
                  error!,
                  key: const ValueKey('notebook-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('notebook-import'),
                onPressed: (importing || accepted.isEmpty) ? null : onImport,
                child: importing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Importer en brouillon'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportedView extends StatelessWidget {
  const _ImportedView({required this.lesson});

  final AdminLessonModel lesson;

  @override
  Widget build(BuildContext context) {
    final count = lesson.effectiveBlocks.length;
    return Padding(
      padding: const EdgeInsets.all(IntelliaSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt_rounded, size: 48),
          const SizedBox(height: IntelliaSpacing.md),
          Text(
            'Import réussi : la leçon « ${lesson.title} » compte maintenant '
            '$count bloc(s), enregistrée en brouillon.',
            key: const ValueKey('notebook-outcome'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          const Text(
            'Rien n’est publié : ces blocs suivent le parcours éditorial comme '
            'tout autre contenu.',
            key: ValueKey('notebook-draft-notice'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          FilledButton(
            key: const ValueKey('notebook-close'),
            onPressed: () => Navigator.of(context).pop(lesson),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
}

/// État honnête quand aucune leçon brouillon n'est ciblée : on n'invente pas de
/// leçon, on oriente vers l'ouverture d'un brouillon dans le Studio.
class _NoTargetLessonView extends StatelessWidget {
  const _NoTargetLessonView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importer depuis NotebookLM')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 48),
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                'L’import NotebookLM rattache des fichiers à une leçon en '
                'brouillon. Ouvre une leçon en brouillon dans le Studio, puis '
                'choisis « Importer depuis NotebookLM ».',
                key: const ValueKey('notebook-no-lesson'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
