import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../admin/data/educational_media_service.dart';

/// Consultation sécurisée d'un document PDF référencé par son chemin canonique.
///
/// Le PDF n'est jamais exposé par une URL permanente : à chaque ouverture, une
/// URL **signée et temporaire** est résolue à la demande, puis ouverte dans une
/// vue navigateur intégrée. Rien n'est stocké côté client. Chargement, erreur
/// et réessai sont explicites.
class LessonPdfView extends ConsumerStatefulWidget {
  const LessonPdfView({
    required this.storagePath,
    this.caption,
    this.launcher,
    super.key,
  });

  final String storagePath;
  final String? caption;

  /// Ouvre l'URL (siège de test). Par défaut, une vue navigateur intégrée.
  final Future<bool> Function(Uri url)? launcher;

  @override
  ConsumerState<LessonPdfView> createState() => _LessonPdfViewState();
}

class _LessonPdfViewState extends ConsumerState<LessonPdfView> {
  bool _busy = false;
  String? _error;

  Future<bool> _launch(Uri url) {
    final launcher = widget.launcher;
    if (launcher != null) return launcher(url);
    // Vue intégrée : le document reste dans l'application, l'URL signée expire.
    return launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _open() async {
    if (widget.storagePath.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // URL fraîche à chaque ouverture : jamais mémorisée, toujours signée.
      final url = await ref
          .read(educationalMediaServiceProvider)
          .resolveUrl(widget.storagePath);
      final opened = await _launch(Uri.parse(url));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = opened ? null : 'Impossible d’ouvrir le document.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Le document n’a pas pu être ouvert. Réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = widget.caption?.trim();
    return Container(
      key: const ValueKey('lesson-pdf-view'),
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Expanded(
                child: Text(
                  (caption != null && caption.isNotEmpty)
                      ? caption
                      : 'Document PDF',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          if (_error != null) ...[
            Text(
              _error!,
              key: const ValueKey('lesson-pdf-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
          ],
          Semantics(
            button: true,
            label: 'Ouvrir le document PDF',
            child: FilledButton.icon(
              key: const ValueKey('lesson-pdf-open'),
              onPressed: _busy ? null : _open,
              icon: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new_rounded),
              label: Text(_error != null ? 'Réessayer' : 'Ouvrir le document'),
            ),
          ),
        ],
      ),
    );
  }
}
