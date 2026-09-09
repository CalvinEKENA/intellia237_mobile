import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../learn/domain/content_block.dart';

/// Édition des blocs d'une leçon.
///
/// Registre de décisions : l'éditeur de sections V1 reste en place — il
/// alimente la projection lue par les anciennes versions de l'application.
/// Les blocs viennent à côté, pas à la place : une leçon peut donc porter du
/// texte hérité et des médias V2 sans que rien ne se perde.
///
/// Aucun octet ne transite ici : un bloc média porte le chemin canonique de sa
/// ressource, téléversée par le service dédié.
class LessonBlocksEditor extends StatelessWidget {
  const LessonBlocksEditor({
    required this.blocks,
    required this.onChanged,
    super.key,
  });

  final List<ContentBlock> blocks;
  final ValueChanged<List<ContentBlock>> onChanged;

  void _add(BuildContext context, ContentBlockType type) {
    final order = blocks.length;
    final id = 'block_${DateTime.now().microsecondsSinceEpoch}';
    final block = switch (type) {
      ContentBlockType.text => TextBlock(id: id, order: order, markdown: ''),
      ContentBlockType.media => MediaBlock(
        id: id,
        order: order,
        mediaType: MediaType.image,
        storagePath: '',
      ),
      ContentBlockType.quiz => QuizBlock(id: id, order: order),
      ContentBlockType.interactive => InteractiveBlock(
        id: id,
        order: order,
        componentType: 'pythagoras_visual_v1',
      ),
    };
    onChanged([...blocks, block]);
  }

  void _delete(int index) {
    final next = [...blocks]..removeAt(index);
    onChanged(_reordered(next));
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= blocks.length) return;
    final next = [...blocks];
    final moved = next.removeAt(index);
    next.insert(target, moved);
    onChanged(_reordered(next));
  }

  /// Renumérote après chaque remaniement : l'ordre stocké doit refléter
  /// l'ordre visible, sinon l'élève lirait la leçon dans un autre sens.
  List<ContentBlock> _reordered(List<ContentBlock> source) => [
    for (var i = 0; i < source.length; i++) _withOrder(source[i], i),
  ];

  static ContentBlock _withOrder(ContentBlock block, int order) {
    if (block is TextBlock) {
      return TextBlock(
        id: block.id,
        order: order,
        markdown: block.markdown,
        title: block.title,
      );
    }
    if (block is MediaBlock) {
      return MediaBlock(
        id: block.id,
        order: order,
        mediaType: block.mediaType,
        storagePath: block.storagePath,
        caption: block.caption,
        durationSeconds: block.durationSeconds,
        mimeType: block.mimeType,
        transcriptionText: block.transcriptionText,
        transcriptionVtt: block.transcriptionVtt,
      );
    }
    if (block is QuizBlock) {
      return QuizBlock(
        id: block.id,
        order: order,
        quizId: block.quizId,
        inlineQuestions: block.inlineQuestions,
      );
    }
    if (block is InteractiveBlock) {
      return InteractiveBlock(
        id: block.id,
        order: order,
        componentType: block.componentType,
        parameters: block.parameters,
        assetDependencies: block.assetDependencies,
        minAppVersion: block.minAppVersion,
      );
    }
    return block;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Blocs de contenu (${blocks.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            PopupMenuButton<ContentBlockType>(
              key: const ValueKey('lesson-blocks-add'),
              tooltip: 'Ajouter un bloc',
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ContentBlockType.text,
                  child: Text('Texte / Markdown'),
                ),
                PopupMenuItem(
                  value: ContentBlockType.media,
                  child: Text('Média'),
                ),
                PopupMenuItem(
                  value: ContentBlockType.quiz,
                  child: Text('Quiz'),
                ),
                PopupMenuItem(
                  value: ContentBlockType.interactive,
                  child: Text('Activité interactive'),
                ),
              ],
              onSelected: (type) => _add(context, type),
              child: const Padding(
                padding: EdgeInsets.all(IntelliaSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text('Ajouter un bloc'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        if (blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: IntelliaSpacing.md),
            child: Text(
              'Aucun bloc. Les sections de texte ci-dessus restent lisibles '
              'par toutes les versions de l’application.',
              key: ValueKey('lesson-blocks-empty'),
              style: TextStyle(fontSize: 13),
            ),
          )
        else
          for (var i = 0; i < blocks.length; i++)
            _BlockTile(
              key: ValueKey('lesson-block-${blocks[i].id}'),
              block: blocks[i],
              isFirst: i == 0,
              isLast: i == blocks.length - 1,
              onDelete: () => _delete(i),
              onMoveUp: () => _move(i, -1),
              onMoveDown: () => _move(i, 1),
              onChanged: (updated) {
                final next = [...blocks];
                next[i] = updated;
                onChanged(next);
              },
            ),
      ],
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({
    required this.block,
    required this.isFirst,
    required this.isLast,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onChanged,
    super.key,
  });

  final ContentBlock block;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<ContentBlock> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: IntelliaSpacing.xs),
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_label(block), style: theme.textTheme.labelLarge),
              ),
              IconButton(
                key: ValueKey('block-up-${block.id}'),
                tooltip: 'Monter',
                onPressed: isFirst ? null : onMoveUp,
                icon: const Icon(Icons.arrow_upward, size: 18),
              ),
              IconButton(
                key: ValueKey('block-down-${block.id}'),
                tooltip: 'Descendre',
                onPressed: isLast ? null : onMoveDown,
                icon: const Icon(Icons.arrow_downward, size: 18),
              ),
              IconButton(
                key: ValueKey('block-delete-${block.id}'),
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _editorFor(context),
        ],
      ),
    );
  }

  Widget _editorFor(BuildContext context) {
    final current = block;
    if (current is TextBlock) {
      return TextFormField(
        key: ValueKey('block-text-${current.id}'),
        initialValue: current.markdown,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Texte (Markdown)'),
        onChanged: (value) => onChanged(
          TextBlock(
            id: current.id,
            order: current.order,
            markdown: value,
            title: current.title,
          ),
        ),
      );
    }
    if (current is MediaBlock) {
      return Column(
        children: [
          DropdownButtonFormField<MediaType>(
            key: ValueKey('block-media-type-${current.id}'),
            initialValue: current.mediaType,
            decoration: const InputDecoration(labelText: 'Nature'),
            items: [
              for (final type in MediaType.values)
                DropdownMenuItem(value: type, child: Text(type.name)),
            ],
            onChanged: (value) => onChanged(
              MediaBlock(
                id: current.id,
                order: current.order,
                mediaType: value ?? current.mediaType,
                storagePath: current.storagePath,
                caption: current.caption,
              ),
            ),
          ),
          TextFormField(
            key: ValueKey('block-media-path-${current.id}'),
            initialValue: current.storagePath,
            decoration: const InputDecoration(
              labelText: 'Chemin de stockage',
              helperText:
                  'La ressource reste où elle est ; seule son adresse '
                  'est enregistrée.',
            ),
            onChanged: (value) => onChanged(
              MediaBlock(
                id: current.id,
                order: current.order,
                mediaType: current.mediaType,
                storagePath: value,
                caption: current.caption,
              ),
            ),
          ),
        ],
      );
    }
    if (current is InteractiveBlock) {
      return TextFormField(
        key: ValueKey('block-interactive-${current.id}'),
        initialValue: current.componentType,
        decoration: const InputDecoration(
          labelText: 'Clé du composant',
          helperText:
              'Une clé inconnue affichera un résumé, jamais une erreur.',
        ),
        onChanged: (value) => onChanged(
          InteractiveBlock(
            id: current.id,
            order: current.order,
            componentType: value,
            parameters: current.parameters,
          ),
        ),
      );
    }
    if (current is QuizBlock) {
      return TextFormField(
        key: ValueKey('block-quiz-${current.id}'),
        initialValue: current.quizId ?? '',
        decoration: const InputDecoration(labelText: 'Quiz rattaché'),
        onChanged: (value) => onChanged(
          QuizBlock(
            id: current.id,
            order: current.order,
            quizId: value.trim().isEmpty ? null : value.trim(),
            inlineQuestions: current.inlineQuestions,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  static String _label(ContentBlock block) => switch (block.type) {
    ContentBlockType.text => 'Texte',
    ContentBlockType.media => 'Média',
    ContentBlockType.quiz => 'Quiz',
    ContentBlockType.interactive => 'Activité interactive',
  };
}
