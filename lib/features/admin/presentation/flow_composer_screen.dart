import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../flow/domain/flow_item.dart';
import '../../flow/domain/flow_item_mapper.dart';
import '../../flow/domain/flow_subject.dart';
import '../../flow/presentation/widgets/flow_card_view.dart';
import '../application/flow_composer_providers.dart';

/// Libellé d'un type de publication, tel que l'auteur le lit.
String flowItemTypeLabel(FlowItemType type) => switch (type) {
  FlowItemType.notion => 'Notion',
  FlowItemType.question => 'Exercice (question et réponse)',
  FlowItemType.quiz => 'Mini-quiz (QCM)',
  FlowItemType.image => 'Image commentée',
  FlowItemType.infographic => 'Infographie',
  FlowItemType.audio => 'Capsule audio',
  FlowItemType.shortVideo => 'Capsule vidéo',
  FlowItemType.interactiveNative => 'Activité interactive',
};

/// Ce qui manque encore pour que l'élève voie la publication, ou null.
///
/// Registre de décisions : le fil écarte en silence une carte incomplète —
/// mieux vaut un fil plus court qu'une carte fausse. Le Studio doit donc dire,
/// lui, ce qui manque ; sans quoi l'auteur publie et l'élève ne reçoit rien.
String? flowItemMissingParts(FlowItem item) {
  if (FlowItemMapper.toCard(item) != null) return null;
  if (FlowSubjects.byId(item.subjectId) == null) return 'Choisis une matière.';
  return switch (item.type) {
    FlowItemType.notion ||
    FlowItemType.infographic => 'Il lui faut une idée clé ou des points clés.',
    FlowItemType.question => 'Il lui faut une question et sa réponse.',
    FlowItemType.quiz =>
      'Il lui faut une question, au moins deux options et une bonne réponse.',
    FlowItemType.image => 'Il lui faut un média référencé et une légende.',
    FlowItemType.audio ||
    FlowItemType.shortVideo => 'Il lui faut un média référencé.',
    FlowItemType.interactiveNative =>
      'Il lui faut une activité enregistrée et son résumé.',
  };
}

/// Composition d'une publication du fil.
///
/// Registre de décisions : le compositeur ne recopie jamais le média source.
/// Une capsule audio de quatre minutes existe une fois, à son emplacement de
/// stockage ; la publication porte une accroche et une référence. C'est ce qui
/// permettra de servir des milliers d'élèves sans dupliquer un octet.
///
/// Chaque type a ses propres champs, ceux que le rendu élève lit réellement :
/// un mini-quiz porte ses options et sa bonne réponse, un exercice sa question
/// et sa réponse. L'aperçu utilise le **rendu élève réel** — `FlowCardView` —
/// dans un cadre 9:16. Un auteur qui valide ce qu'il voit valide ce que
/// l'élève verra.
class FlowComposerScreen extends ConsumerStatefulWidget {
  const FlowComposerScreen({required this.classLevel, this.initial, super.key});

  final String classLevel;
  final FlowItem? initial;

  @override
  ConsumerState<FlowComposerScreen> createState() => _FlowComposerScreenState();
}

class _FlowComposerScreenState extends ConsumerState<FlowComposerScreen> {
  static const _maxOptions = 6;

  late final TextEditingController _title;
  late final TextEditingController _hook;
  late final TextEditingController _body;
  late final TextEditingController _question;
  late final TextEditingController _points;
  late final TextEditingController _explanation;
  late final TextEditingController _lessonRef;
  late final TextEditingController _storagePath;
  late final List<TextEditingController> _options;

  late FlowItemType _type;
  late String _subjectId;
  late FlowPedagogicalIntent _intent;
  late int _difficulty;
  late int _durationSeconds;
  late int _priority;
  late int _optionCount;
  late int _correctIndex;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final payload = initial?.payload ?? const <String, Object?>{};
    String text(String key) => (payload[key] as String?) ?? '';
    final initialOptions = ((payload['options'] as List?) ?? const [])
        .whereType<String>()
        .toList(growable: false);

    _type = initial?.type ?? FlowItemType.notion;
    _title = TextEditingController(text: initial?.title ?? '');
    _hook = TextEditingController(text: initial?.hook ?? '');
    _body = TextEditingController(
      text: switch (_type) {
        FlowItemType.question => text('answer'),
        FlowItemType.image => text('caption'),
        _ => text('insight').isNotEmpty ? text('insight') : text('caption'),
      },
    );
    _question = TextEditingController(text: text('question'));
    _points = TextEditingController(
      text: ((payload['points'] as List?) ?? const []).whereType<String>().join(
        '\n',
      ),
    );
    _explanation = TextEditingController(text: text('explanation'));
    _options = List.generate(
      _maxOptions,
      (index) => TextEditingController(
        text: index < initialOptions.length ? initialOptions[index] : '',
      ),
    );
    _optionCount = initialOptions.length.clamp(2, _maxOptions);
    _correctIndex = (payload['correctIndex'] as num?)?.toInt() ?? 0;
    _lessonRef = TextEditingController(text: initial?.ref.lessonId ?? '');
    _storagePath = TextEditingController(text: initial?.ref.storagePath ?? '');
    _subjectId = initial?.subjectId ?? FlowSubjects.all.first.id;
    _intent = initial?.pedagogicalIntent ?? FlowPedagogicalIntent.discover;
    _difficulty = initial?.difficulty ?? 3;
    _durationSeconds = initial?.durationSeconds ?? 30;
    _priority = initial?.priority ?? 0;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _hook,
      _body,
      _question,
      _points,
      _explanation,
      _lessonRef,
      _storagePath,
      ..._options,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _usesMedia => switch (_type) {
    FlowItemType.image ||
    FlowItemType.infographic ||
    FlowItemType.audio ||
    FlowItemType.shortVideo => true,
    _ => false,
  };

  /// Ce que le rendu élève lit, et rien d'autre, pour le type choisi.
  Map<String, Object?> _payload() {
    String clean(TextEditingController controller) => controller.text.trim();
    switch (_type) {
      case FlowItemType.notion:
      case FlowItemType.infographic:
        final points = _points.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(growable: false);
        return <String, Object?>{
          if (clean(_body).isNotEmpty) 'insight': clean(_body),
          if (points.isNotEmpty) 'points': points,
        };
      case FlowItemType.question:
        return <String, Object?>{
          if (clean(_question).isNotEmpty) 'question': clean(_question),
          if (clean(_body).isNotEmpty) 'answer': clean(_body),
        };
      case FlowItemType.quiz:
        // Une option laissée vide disparaît ; la bonne réponse suit sa place.
        final options = <String>[];
        var correct = -1;
        for (var index = 0; index < _optionCount; index++) {
          final option = clean(_options[index]);
          if (option.isEmpty) continue;
          if (index == _correctIndex) correct = options.length;
          options.add(option);
        }
        return <String, Object?>{
          if (clean(_question).isNotEmpty) 'question': clean(_question),
          'options': options,
          if (correct >= 0) 'correctIndex': correct,
          if (clean(_explanation).isNotEmpty)
            'explanation': clean(_explanation),
        };
      case FlowItemType.image:
        return <String, Object?>{
          if (clean(_body).isNotEmpty) 'caption': clean(_body),
        };
      case FlowItemType.audio:
      case FlowItemType.shortVideo:
        return const <String, Object?>{};
      case FlowItemType.interactiveNative:
        // L'activité vient du registre ASTRA : le compositeur la transporte
        // sans la réécrire.
        return widget.initial?.payload ?? const <String, Object?>{};
    }
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
      storagePath: !_usesMedia || _storagePath.text.trim().isEmpty
          ? null
          : _storagePath.text.trim(),
    ),
    payload: _payload(),
    // Une publication naît toujours brouillon : la mise en ligne est un geste
    // distinct, soumis aux permissions.
    status: widget.initial?.status ?? 'draft',
    tags: widget.initial?.tags ?? const <String>[],
    origin: widget.initial?.origin ?? 'manual',
    createdBy: widget.initial == null
        ? ref.read(contentActorProvider)?.uid
        : widget.initial!.createdBy,
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
          final form = _buildForm(context, flowItemMissingParts(draft));
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

  Widget _field({
    required String keyName,
    required TextEditingController controller,
    required String label,
    String? helper,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: IntelliaSpacing.sm),
      child: TextField(
        key: ValueKey(keyName),
        controller: controller,
        minLines: 1,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, helperText: helper),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  List<Widget> _typeFields() => switch (_type) {
    FlowItemType.notion || FlowItemType.infographic => [
      _field(
        keyName: 'flow-composer-body',
        controller: _body,
        label: 'Idée clé',
        helper: 'Une ou deux phrases que l’élève retiendra.',
        maxLines: 3,
      ),
      _field(
        keyName: 'flow-composer-points',
        controller: _points,
        label: 'Points clés (un par ligne)',
        maxLines: 5,
      ),
    ],
    FlowItemType.question => [
      _field(
        keyName: 'flow-composer-question',
        controller: _question,
        label: 'Question posée à l’élève',
        maxLines: 3,
      ),
      _field(
        keyName: 'flow-composer-body',
        controller: _body,
        label: 'Réponse (révélée à l’élève)',
        maxLines: 4,
      ),
    ],
    FlowItemType.quiz => [
      _field(
        keyName: 'flow-composer-question',
        controller: _question,
        label: 'Question du mini-quiz',
        maxLines: 3,
      ),
      const SizedBox(height: IntelliaSpacing.sm),
      Text(
        'Options — touche le rond de la bonne réponse',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      for (var index = 0; index < _optionCount; index++)
        Row(
          children: [
            IconButton(
              key: ValueKey('flow-composer-correct-$index'),
              tooltip: 'Bonne réponse',
              onPressed: () => setState(() => _correctIndex = index),
              icon: Icon(
                index == _correctIndex
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: index == _correctIndex
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            Expanded(
              child: TextField(
                key: ValueKey('flow-composer-option-$index'),
                controller: _options[index],
                decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      Wrap(
        spacing: IntelliaSpacing.sm,
        children: [
          if (_optionCount < _maxOptions)
            TextButton.icon(
              key: const ValueKey('flow-composer-add-option'),
              onPressed: () => setState(() => _optionCount += 1),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une option'),
            ),
          if (_optionCount > 2)
            TextButton.icon(
              key: const ValueKey('flow-composer-remove-option'),
              onPressed: () => setState(() {
                _optionCount -= 1;
                _options[_optionCount].clear();
                if (_correctIndex >= _optionCount) _correctIndex = 0;
              }),
              icon: const Icon(Icons.remove),
              label: const Text('Retirer la dernière'),
            ),
        ],
      ),
      _field(
        keyName: 'flow-composer-explanation',
        controller: _explanation,
        label: 'Explication (après la réponse)',
        maxLines: 3,
      ),
    ],
    FlowItemType.image => [
      _field(
        keyName: 'flow-composer-body',
        controller: _body,
        label: 'Légende',
        maxLines: 3,
      ),
    ],
    FlowItemType.audio ||
    FlowItemType.shortVideo ||
    FlowItemType.interactiveNative => const <Widget>[],
  };

  Widget _buildForm(BuildContext context, String? missing) {
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
                // Une activité interactive vient du registre ASTRA : on la
                // relit, on ne la crée pas ici.
                if (type != FlowItemType.interactiveNative ||
                    widget.initial?.type == FlowItemType.interactiveNative)
                  DropdownMenuItem(
                    value: type,
                    child: Text(flowItemTypeLabel(type)),
                  ),
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
          _field(
            keyName: 'flow-composer-title',
            controller: _title,
            label: 'Titre',
          ),
          _field(
            keyName: 'flow-composer-hook',
            controller: _hook,
            label: 'Accroche',
          ),
          ..._typeFields(),
          _field(
            keyName: 'flow-composer-lesson-ref',
            controller: _lessonRef,
            label: 'Leçon source (identifiant)',
          ),
          if (_usesMedia)
            _field(
              keyName: 'flow-composer-storage-path',
              controller: _storagePath,
              label: 'Média référencé (chemin de stockage)',
              helper: 'Le fichier n’est jamais recopié dans la publication.',
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
          if (missing != null) ...[
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              'L’élève ne verra pas encore cette publication. $missing',
              key: const ValueKey('flow-composer-incomplete'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
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
