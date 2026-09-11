import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../flow/domain/flow_item.dart';
import '../../flow/domain/flow_item_mapper.dart';
import '../../flow/domain/flow_subject.dart';
import '../../flow/presentation/widgets/flow_card_view.dart';
import '../application/flow_composer_providers.dart';

/// Composition d'une publication du fil.
///
/// Registre de décisions : le compositeur ne recopie jamais le média source.
/// Une capsule audio de quatre minutes existe une fois, à son emplacement de
/// stockage ; la publication porte une accroche et une référence. C'est ce qui
/// permettra de servir des milliers d'élèves sans dupliquer un octet.
///
/// L'aperçu utilise le **rendu élève réel** — `FlowCardView` — dans un cadre
/// 9:16. Un auteur qui valide ce qu'il voit valide ce que l'élève verra.
class FlowComposerScreen extends ConsumerStatefulWidget {
  const FlowComposerScreen({required this.classLevel, this.initial, super.key});

  final String classLevel;
  final FlowItem? initial;

  @override
  ConsumerState<FlowComposerScreen> createState() => _FlowComposerScreenState();
}

class _FlowComposerScreenState extends ConsumerState<FlowComposerScreen> {
  late final TextEditingController _title;
  late final TextEditingController _hook;
  late final TextEditingController _body;
  late final TextEditingController _lessonRef;
  late final TextEditingController _storagePath;

  late FlowItemType _type;
  late String _subjectId;
  late FlowPedagogicalIntent _intent;
  late int _difficulty;
  late int _durationSeconds;
  late int _priority;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _hook = TextEditingController(text: initial?.hook ?? '');
    _body = TextEditingController(
      text: (initial?.payload['insight'] as String?) ?? '',
    );
    _lessonRef = TextEditingController(text: initial?.ref.lessonId ?? '');
    _storagePath = TextEditingController(text: initial?.ref.storagePath ?? '');
    _type = initial?.type ?? FlowItemType.notion;
    _subjectId = initial?.subjectId ?? FlowSubjects.all.first.id;
    _intent = initial?.pedagogicalIntent ?? FlowPedagogicalIntent.discover;
    _difficulty = initial?.difficulty ?? 3;
    _durationSeconds = initial?.durationSeconds ?? 30;
    _priority = initial?.priority ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _hook.dispose();
    _body.dispose();
    _lessonRef.dispose();
    _storagePath.dispose();
    super.dispose();
  }

  /// Construit la publication telle qu'elle serait enregistrée.
  FlowItem _draft() => FlowItem(
    id: widget.initial?.id ?? '',
    type: _type,
    title: _title.text.trim(),
    hook: _hook.text.trim(),
    subjectId: _subjectId,
    classLevels: [widget.classLevel],
    // Une publication garde son périmètre ; une nouvelle naît dans celui
    // de son auteur.
    scope: widget.initial?.scope ?? ref.read(contentAuthoringScopeProvider),
    pedagogicalIntent: _intent,
    difficulty: _difficulty,
    durationSeconds: _durationSeconds,
    priority: _priority,
    // Les contenus lourds restent où ils sont : seule leur adresse voyage.
    ref: FlowItemRef(
      lessonId: _lessonRef.text.trim().isEmpty ? null : _lessonRef.text.trim(),
      storagePath: _storagePath.text.trim().isEmpty
          ? null
          : _storagePath.text.trim(),
    ),
    payload: <String, Object?>{
      if (_body.text.trim().isNotEmpty) 'insight': _body.text.trim(),
      if (_body.text.trim().isNotEmpty) 'caption': _body.text.trim(),
      if (_body.text.trim().isNotEmpty) 'answer': _body.text.trim(),
    },
    // Une publication naît toujours brouillon : la mise en ligne est un geste
    // distinct, soumis aux permissions.
    status: widget.initial?.status ?? 'draft',
    createdBy: widget.initial?.createdBy,
    createdAt: widget.initial?.createdAt,
  );

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminFlowRepositoryProvider).save(_draft());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft();
    final card = FlowItemMapper.toCard(draft);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Flow'),
        actions: [
          TextButton(
            key: const ValueKey('flow-composer-save'),
            onPressed: _saving || draft.title.isEmpty ? null : _save,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final form = _buildForm(context, card == null);
          final preview = _FlowPreviewFrame(card: card);

          // Sur un écran large, l'auteur voit son texte et son rendu côte à
          // côte ; sur un téléphone, l'aperçu suit le formulaire.
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le formulaire défile aussi en disposition large : il compte
                // une douzaine de champs, et l'écran d'un portable ne les
                // contient pas tous.
                Expanded(child: SingleChildScrollView(child: form)),
                const SizedBox(width: IntelliaSpacing.lg),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(IntelliaSpacing.lg),
                  child: preview,
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            children: [
              form,
              const SizedBox(height: IntelliaSpacing.lg),
              Center(child: preview),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool incomplete) {
    return Padding(
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              key: const ValueKey('flow-composer-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
          ],
          DropdownButtonFormField<FlowItemType>(
            key: const ValueKey('flow-composer-type'),
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final type in FlowItemType.values)
                DropdownMenuItem(value: type, child: Text(type.name)),
            ],
            onChanged: (value) =>
                setState(() => _type = value ?? FlowItemType.notion),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          DropdownButtonFormField<String>(
            key: const ValueKey('flow-composer-subject'),
            initialValue: _subjectId,
            decoration: const InputDecoration(labelText: 'Matière'),
            items: [
              for (final subject in FlowSubjects.all)
                DropdownMenuItem(value: subject.id, child: Text(subject.label)),
            ],
            onChanged: (value) =>
                setState(() => _subjectId = value ?? _subjectId),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          TextField(
            key: const ValueKey('flow-composer-title'),
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titre'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          TextField(
            key: const ValueKey('flow-composer-hook'),
            controller: _hook,
            decoration: const InputDecoration(labelText: 'Accroche'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          TextField(
            key: const ValueKey('flow-composer-body'),
            controller: _body,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Contenu court',
              helperText: 'Les médias lourds passent par une référence.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          TextField(
            key: const ValueKey('flow-composer-lesson-ref'),
            controller: _lessonRef,
            decoration: const InputDecoration(
              labelText: 'Leçon source (identifiant)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          TextField(
            key: const ValueKey('flow-composer-storage-path'),
            controller: _storagePath,
            decoration: const InputDecoration(
              labelText: 'Média référencé (chemin de stockage)',
              helperText:
                  'Le fichier n’est jamais recopié dans la publication.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          DropdownButtonFormField<FlowPedagogicalIntent>(
            initialValue: _intent,
            decoration: const InputDecoration(labelText: 'Intention'),
            items: [
              for (final intent in FlowPedagogicalIntent.values)
                DropdownMenuItem(value: intent, child: Text(intent.name)),
            ],
            onChanged: (value) => setState(() => _intent = value ?? _intent),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          _StepperRow(
            label: 'Difficulté',
            value: _difficulty,
            min: 1,
            max: 5,
            onChanged: (value) => setState(() => _difficulty = value),
          ),
          _StepperRow(
            label: 'Durée (s)',
            value: _durationSeconds,
            min: 10,
            max: 120,
            step: 5,
            onChanged: (value) => setState(() => _durationSeconds = value),
          ),
          _StepperRow(
            label: 'Priorité',
            value: _priority,
            min: -10,
            max: 10,
            onChanged: (value) => setState(() => _priority = value),
          ),
          if (incomplete) ...[
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              'Cette publication n’est pas encore présentable : complète les '
              'champs que son type demande.',
              key: const ValueKey('flow-composer-incomplete'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Cadre 9:16 montrant le rendu élève réel.
class _FlowPreviewFrame extends StatelessWidget {
  const _FlowPreviewFrame({required this.card});

  final dynamic card;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Aperçu élève', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: IntelliaSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520, maxWidth: 293),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(IntelliaRadii.large),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(IntelliaRadii.large),
                ),
                child: card == null
                    ? const Center(
                        key: ValueKey('flow-preview-empty'),
                        child: Padding(
                          padding: EdgeInsets.all(IntelliaSpacing.md),
                          child: Text(
                            'Rien à prévisualiser pour le moment.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : FlowCardView(
                        key: const ValueKey('flow-preview-card'),
                        card: card,
                        onAward: (_) {},
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('$label : $value')),
        IconButton(
          onPressed: value > min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
