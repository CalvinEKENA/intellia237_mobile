import 'audio_overview_player.dart';
import 'educational_video_player.dart';
import 'lesson_pdf_view.dart';
import 'rich_lesson_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../admin/data/educational_media_service.dart';
import '../../domain/content_block.dart';
import '../../domain/interactive_component.dart';
import 'interactive/interactive_block_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/tab_presentation.dart';

/// Rend un bloc de contenu V2 à l'élève.
///
/// Registre de décisions : un bloc défaillant n'emporte jamais la leçon. Type
/// inconnu, média effacé, composant interactif absent, configuration
/// invalide — chacun de ces cas donne un encart lisible, et le reste de la
/// leçon continue. Une leçon amputée d'un bloc reste une leçon ; une leçon
/// qui s'effondre n'est plus rien.
class ContentBlockView extends StatelessWidget {
  const ContentBlockView({required this.block, super.key});

  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    final current = block;
    if (current is TextBlock) return _TextBlockView(block: current);
    if (current is MediaBlock) return _MediaBlockView(block: current);
    if (current is QuizBlock) return _QuizBlockView(block: current);
    if (current is InteractiveBlock) {
      return InteractiveBlockView(
        spec: InteractiveComponentSpec(
          componentKey: current.componentType,
          config: Map<String, Object?>.from(current.parameters),
          summary: current.parameters['summary'] as String?,
        ),
      );
    }
    // Un type publié par une version plus récente du Studio.
    return const ContentBlockFallbackCard(
      reason: 'Ce contenu demande une version plus récente de l’application.',
    );
  }
}

class _TextBlockView extends StatelessWidget {
  const _TextBlockView({required this.block});

  final TextBlock block;

  @override
  Widget build(BuildContext context) {
    // La typographie reprend celle des sections V1 : une leçon ancienne et
    // une leçon V2 doivent se lire exactement pareil.
    final surface = TabSurface.of(context);
    final title = block.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null && title.trim().isNotEmpty) ...[
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: surface.accent,
              height: 1.25,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              gradient: IntelliaGradients.brand,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
        ],
        // Rendu riche et sûr : l'élève ne voit jamais la syntaxe Markdown brute.
        RichLessonText(
          markdown: block.markdown,
          baseStyle: GoogleFonts.manrope(
            fontSize: 16,
            height: 1.7,
            color: surface.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          linkColor: IntelliaColors.brandIndigo,
        ),
      ],
    );
  }
}

/// Média référencé par son chemin canonique, résolu à l'affichage.
class _MediaBlockView extends ConsumerWidget {
  const _MediaBlockView({required this.block});

  final MediaBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caption = block.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MediaSurface(block: block),
        if (caption != null && caption.trim().isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _MediaSurface extends ConsumerWidget {
  const _MediaSurface({required this.block});

  final MediaBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (block.storagePath.trim().isEmpty) {
      return const ContentBlockFallbackCard(
        reason: 'Cette ressource n’est plus disponible.',
      );
    }

    switch (block.mediaType) {
      case MediaType.image:
        return _RemoteImage(storagePath: block.storagePath);
      case MediaType.audio:
        final caption = block.caption?.trim();
        return AudioOverviewPlayer(
          storagePath: block.storagePath,
          title: (caption != null && caption.isNotEmpty)
              ? caption
              : 'Capsule audio',
        );
      case MediaType.video:
        return EducationalVideoPlayer(
          storagePath: block.storagePath,
          caption: block.caption,
          fileSizeBytes: block.fileSizeBytes,
        );
      case MediaType.pdf:
        return LessonPdfView(
          storagePath: block.storagePath,
          caption: block.caption,
        );
    }
  }
}

/// Image chargée depuis son chemin canonique.
///
/// L'URL est résolue à l'affichage et jamais stockée : c'est ce qui permettra
/// de basculer vers un CDN ou des URLs signées sans migrer les documents.
class _RemoteImage extends ConsumerWidget {
  const _RemoteImage({required this.storagePath});

  final String storagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(educationalMediaServiceProvider);

    return FutureBuilder<String>(
      future: service.resolveUrl(storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _MediaLoading();
        }
        final url = snapshot.data;
        if (snapshot.hasError || url == null) {
          return const ContentBlockFallbackCard(
            key: ValueKey('media-unavailable'),
            reason: 'Cette image n’a pas pu être chargée.',
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ContentBlockFallbackCard(
              key: ValueKey('media-unavailable'),
              reason: 'Cette image n’a pas pu être chargée.',
            ),
          ),
        );
      },
    );
  }
}

class _MediaLoading extends StatelessWidget {
  const _MediaLoading();

  @override
  Widget build(BuildContext context) => Container(
    height: 160,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
    ),
    child: const CircularProgressIndicator(),
  );
}

class _QuizBlockView extends StatelessWidget {
  const _QuizBlockView({required this.block});

  final QuizBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = block.inlineQuestions.length;

    if (count == 0 && (block.quizId?.trim().isEmpty ?? true)) {
      return const ContentBlockFallbackCard(
        reason: 'Ce quiz n’est pas encore disponible.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: IntelliaSpacing.sm),
          Expanded(
            child: Text(
              count > 0
                  ? 'Quiz · $count question${count > 1 ? 's' : ''}'
                  : 'Quiz rattaché à cette leçon',
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Encart affiché à la place d'un bloc qui ne peut pas être rendu.
class ContentBlockFallbackCard extends StatelessWidget {
  const ContentBlockFallbackCard({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('content-block-fallback'),
      width: double.infinity,
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: IntelliaSpacing.sm),
          Expanded(
            child: Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
