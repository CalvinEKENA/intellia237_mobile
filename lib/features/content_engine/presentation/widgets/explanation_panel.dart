import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/mastery.dart';
import '../../domain/pedagogy.dart';
import '../../domain/visual_kind.dart';
import '../content_style.dart';
import '../visuals/concept_visuals.dart';

/// Découpe une explication en idées (une phrase à la fois).
List<String> splitIdeas(String text) => [
  for (final part in text.split(RegExp(r'(?<=[.!?…])\s+(?=\S)')))
    if (part.trim().isNotEmpty) part.trim(),
];

/// Sélecteur Terminale / Simple / Comme si j'avais 12 ans.
///
/// Le changement est instantané (tout est déjà sur l'appareil) et ne touche
/// jamais la difficulté des exercices.
class ExplanationModeSwitch extends StatelessWidget {
  const ExplanationModeSwitch({
    required this.modes,
    required this.selected,
    required this.onSelected,
    this.labels = const {},
    super.key,
  });

  final List<ExplanationMode> modes;
  final ExplanationMode selected;
  final ValueChanged<ExplanationMode> onSelected;

  /// Libellés du pack (langue du contenu), sinon ceux de l'application.
  final Map<ExplanationMode, String> labels;

  @override
  Widget build(BuildContext context) {
    TextStyle style(ExplanationMode mode) => ContentText.label(
      size: 12,
      color: mode == selected ? Colors.white : ContentPalette.ink,
    );
    // Rayon de 24 : une pilule sur une ligne, une carte arrondie si les
    // niveaux s'empilent.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ContentPalette.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: AdaptiveChoiceRow(
        spacing: 2,
        labels: [
          for (final mode in modes) explanationModeLabel(context, mode, labels),
        ],
        labelStyle: style(selected),
        itemBuilder: (context, i, _) {
          final mode = modes[i];
          return Semantics(
            button: true,
            selected: mode == selected,
            child: GestureDetector(
              key: ValueKey('explanation-mode-${mode.key}'),
              onTap: () => onSelected(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: mode == selected
                      ? ContentPalette.mode(mode)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  explanationModeLabel(context, mode, labels),
                  textAlign: TextAlign.center,
                  style: style(mode),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// « Comprendre » : la notion au niveau d'explication choisi.
class ExplanationPanel extends StatefulWidget {
  const ExplanationPanel({
    required this.concept,
    required this.modes,
    required this.preference,
    required this.onModeSelected,
    required this.onToggleLock,
    this.modeLabels = const {},
    super.key,
  });

  final Concept concept;
  final List<ExplanationMode> modes;

  /// Libellés des niveaux donnés par le pack.
  final Map<ExplanationMode, String> modeLabels;
  final ExplanationPreference preference;
  final ValueChanged<ExplanationMode> onModeSelected;
  final VoidCallback onToggleLock;

  @override
  State<ExplanationPanel> createState() => _ExplanationPanelState();
}

class _ExplanationPanelState extends State<ExplanationPanel> {
  int _idea = 0;

  @override
  void didUpdateWidget(ExplanationPanel old) {
    super.didUpdateWidget(old);
    if (old.preference.mode != widget.preference.mode ||
        old.concept.id != widget.concept.id) {
      _idea = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mode = widget.preference.mode;
    final text = widget.concept.explanation(mode);
    final color = ContentPalette.mode(mode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExplanationModeSwitch(
          labels: widget.modeLabels,
          modes: widget.modes,
          selected: mode,
          onSelected: widget.onModeSelected,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey('explanation-lock'),
            onPressed: widget.onToggleLock,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.preference.locked
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.preference.locked
                        ? l10n.ceModeUnlock
                        : l10n.ceModeLock,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey('${widget.concept.id}-${mode.key}'),
            child: text == null
                ? _Missing(mode: mode)
                : mode == ExplanationMode.ultraSimple
                ? _IdeaByIdea(
                    ideas: splitIdeas(text),
                    index: _idea,
                    color: color,
                    concept: widget.concept,
                    onIndex: (i) => setState(() => _idea = i),
                    onOfficial: () =>
                        widget.onModeSelected(ExplanationMode.standard),
                  )
                : _Explanation(
                    text: text,
                    color: color,
                    onOfficial: mode == ExplanationMode.standard
                        ? null
                        : () => widget.onModeSelected(ExplanationMode.standard),
                  ),
          ),
        ),
        if (widget.concept.commonMistakes.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.lg),
          _Bullets(
            title: l10n.ceMistakesTitle,
            icon: Icons.report_gmailerrorred_rounded,
            color: ContentPalette.error,
            items: widget.concept.commonMistakes,
          ),
        ],
        if (widget.concept.prerequisites.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.md),
          _Bullets(
            title: l10n.cePrerequisitesTitle,
            icon: Icons.foundation_rounded,
            color: ContentPalette.inkSoft,
            items: widget.concept.prerequisites,
          ),
        ],
      ],
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.text,
    required this.color,
    this.onOfficial,
  });

  final String text;
  final Color color;
  final VoidCallback? onOfficial;

  @override
  Widget build(BuildContext context) => ContentCard(
    borderColor: color.withValues(alpha: 0.35),
    padding: const EdgeInsets.all(IntelliaSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: ContentText.body(size: 17)),
        if (onOfficial != null) ...[
          const SizedBox(height: IntelliaSpacing.md),
          _OfficialButton(onPressed: onOfficial!),
        ],
      ],
    ),
  );
}

/// « Comme si j'avais 12 ans » : une idée à la fois, le schéma à côté, et
/// toujours la porte vers la formulation officielle.
class _IdeaByIdea extends StatelessWidget {
  const _IdeaByIdea({
    required this.ideas,
    required this.index,
    required this.color,
    required this.concept,
    required this.onIndex,
    required this.onOfficial,
  });

  final List<String> ideas;
  final int index;
  final Color color;
  final Concept concept;
  final ValueChanged<int> onIndex;
  final VoidCallback onOfficial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = index.clamp(0, ideas.length - 1);
    final last = current == ideas.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentCard(
          color: color.withValues(alpha: 0.06),
          borderColor: color.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < ideas.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= current
                              ? color
                              : color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              Text(
                l10n.ceIdeaProgress(current + 1, ideas.length),
                style: ContentText.eyebrow(color: color),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Text(
                  ideas[current],
                  key: ValueKey(current),
                  style: ContentText.body(size: 20, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: IntelliaSpacing.md),
              Row(
                children: [
                  if (current > 0)
                    IconButton(
                      tooltip: l10n.cePreviousIdea,
                      onPressed: () => onIndex(current - 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  const Spacer(),
                  if (!last)
                    Flexible(
                      child: FilledButton.icon(
                        key: const ValueKey('next-idea'),
                        style: FilledButton.styleFrom(backgroundColor: color),
                        onPressed: () => onIndex(current + 1),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.ceNextIdea),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (concept.visualKind != VisualKind.none) ...[
          const SizedBox(height: IntelliaSpacing.md),
          ContentCard(child: ConceptVisual(kind: concept.visualKind)),
        ],
        const SizedBox(height: IntelliaSpacing.md),
        _OfficialButton(onPressed: onOfficial),
      ],
    );
  }
}

class _OfficialButton extends StatelessWidget {
  const _OfficialButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const ValueKey('official-wording'),
    onPressed: onPressed,
    icon: const Icon(Icons.functions_rounded),
    label: Text(context.l10n.ceOfficialWording),
  );
}

class _Missing extends StatelessWidget {
  const _Missing({required this.mode});
  final ExplanationMode mode;

  @override
  Widget build(BuildContext context) => ContentCard(
    child: Text(
      context.l10n.ceExplanationUnavailable,
      style: ContentText.body(color: ContentPalette.inkSoft),
    ),
  );
}

class _Bullets extends StatelessWidget {
  const _Bullets({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title, style: ContentText.label(color: color)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 24),
          child: Text(item, style: ContentText.body(size: 14.5)),
        ),
    ],
  );
}
