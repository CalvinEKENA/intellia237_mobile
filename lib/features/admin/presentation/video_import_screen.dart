import '../domain/content_origin.dart';
import '../application/flow_composer_providers.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learn/presentation/widgets/educational_video_player.dart';
import '../application/admin_content_providers.dart';
import '../application/video_import_service.dart';
import '../data/educational_media_service.dart';
import '../domain/admin_content_models.dart';
import '../domain/content_block.dart';
import '../domain/educational_media.dart';

class VideoImportScreen extends ConsumerStatefulWidget {
  const VideoImportScreen({
    required this.lesson,
    this.replacingId,
    this.notebook = false,
    super.key,
  });
  final AdminLessonModel lesson;
  final String? replacingId;
  final bool notebook;
  @override
  ConsumerState<VideoImportScreen> createState() => _VideoImportScreenState();
}

class _VideoImportScreenState extends ConsumerState<VideoImportScreen> {
  final _cancellation = MediaUploadCancellation();
  late final _media = ref.read(educationalMediaServiceProvider);
  final _caption = TextEditingController();
  MediaBlock? _video;
  bool _uploading = false, _saving = false, _saved = false;
  double _progress = 0;
  String? _error;
  Future<void> _pick() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4'],
      );
      if (files.isEmpty || !mounted || _cancellation.isCancelled) return;
      final file = files.first;
      if (await file.length() >
          EducationalMediaPolicy.maxBytes(MediaType.video)) {
        throw const MediaRejectedException(
          '150 MiB maximum. Exportez une vidéo plus légère.',
        );
      }
      final block = await VideoImportService(_media).upload(
        lesson: widget.lesson,
        name: file.name,
        bytes: await file.readAsBytes(),
        cancellation: _cancellation,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      _video = block;
      if (!mounted) {
        await _cleanup();
        return;
      }
      _caption.text = block.caption ?? '';
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _message(Object e) => e is MediaRejectedException
      ? e.reason
      : e is FirebaseFunctionsException
      ? e.message ?? 'Échec du service média.'
      : 'Import interrompu. Vérifiez la connexion puis réessayez.';

  Future<void> _save() async {
    final video = _video;
    if (video == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final block = MediaBlock(
      id: video.id,
      order: video.order,
      mediaType: MediaType.video,
      storagePath: video.storagePath,
      mimeType: 'video/mp4',
      fileSizeBytes: video.fileSizeBytes,
      caption: _caption.text.trim(),
    );
    var lesson = VideoImportService(
      _media,
    ).attach(widget.lesson, block, replacingId: widget.replacingId);
    if (widget.notebook) {
      lesson = lesson.copyWith(
        origin: ContentOrigin(
          source: ContentSourceType.notebooklm,
          sourceDocumentName: video.caption,
          importedAt: DateTime.now(),
          importedByUid: ref.read(contentActorProvider)?.uid,
        ),
      );
    }
    try {
      await ref.read(adminContentActionsProvider).saveLesson(lesson);
      _saved = true;
      // Only the server may delete, and only after the old reference is removed.
      for (final old in widget.lesson.contentBlocks.whereType<MediaBlock>()) {
        if (old.id == widget.replacingId &&
            old.storagePath != block.storagePath) {
          try {
            await _media.deleteAsset(
              storagePath: old.storagePath,
              scope: widget.lesson.scope,
            );
          } catch (_) {
            /* Keep a harmless unreferenced object if cleanup is unavailable. */
          }
        }
      }
      if (mounted) Navigator.pop(context, lesson);
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cleanup() async {
    if (!_saved && _video != null) {
      try {
        await _media.deleteAsset(
          storagePath: _video!.storagePath,
          scope: widget.lesson.scope,
        );
      } catch (_) {
        /* Retry can be performed from Storage after checking references. */
      }
    }
  }

  Future<void> _cancel() async {
    await _cancellation.cancel();
    await _cleanup();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    unawaited(_cancellation.cancel());
    unawaited(_cleanup());
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.notebook ? 'Importer depuis NotebookLM' : 'Ajouter une vidéo',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.lesson.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                widget.notebook
                    ? 'Exportez la vidéo depuis NotebookLM, puis sélectionnez le fichier MP4. Relisez l’aperçu avant de l’enregistrer dans cette leçon en brouillon.'
                    : 'MP4 · H.264 · AAC · 150 MiB maximum. La vidéo sera rattachée à cette leçon.',
              ),
              const SizedBox(height: 24),
              if (_uploading) ...[
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                ),
                Text('Téléversement : ${(_progress * 100).round()} %'),
              ] else if (_video == null)
                FilledButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.video_file_outlined),
                  label: const Text('Choisir un fichier MP4'),
                ),
              if (_video != null) ...[
                EducationalVideoPlayer(
                  storagePath: _video!.storagePath,
                  fileSizeBytes: _video!.fileSizeBytes,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _caption,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Légende'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    widget.lesson.isPublished
                        ? 'Enregistrer la modification'
                        : 'Enregistrer dans le brouillon',
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextButton(
                onPressed: _saving ? null : _cancel,
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
