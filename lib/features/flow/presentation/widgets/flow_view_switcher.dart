import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../content_engine/presentation/content_style.dart';
import '../../../content_engine/presentation/subject_identity.dart';
import '../../application/flow_view_prefs.dart';

/// Marge haute que les cartes du fil laissent aux commandes superposées
/// (HUD, « Pour toi | Par matière », matières).
class FlowChromeInset extends InheritedWidget {
  const FlowChromeInset({required this.top, required super.child, super.key});

  /// Marge sous la zone sûre de l'écran.
  final double top;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlowChromeInset>()?.top;

  @override
  bool updateShouldNotify(FlowChromeInset old) => old.top != top;
}

/// « Pour toi | Par matière », puis, par matière, le choix de la matière.
class FlowViewSwitcher extends StatelessWidget {
  const FlowViewSwitcher({
    required this.mode,
    required this.subjects,
    required this.selected,
    required this.onMode,
    required this.onSubject,
    super.key,
  });

  final FlowViewMode mode;
  final List<({String key, String label})> subjects;
  final String? selected;
  final ValueChanged<FlowViewMode> onMode;
  final ValueChanged<String> onSubject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = ContentText.label(
      size: 13,
      color: IntelliaColors.textPrimary,
    );
    Widget segment(String label, String key) => Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(label, style: style, textAlign: TextAlign.center),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.md,
        IntelliaSpacing.sm,
        IntelliaSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<FlowViewMode>(
              key: const ValueKey('flow-view-mode'),
              groupValue: mode,
              backgroundColor: IntelliaColors.textPrimary.withValues(
                alpha: 0.06,
              ),
              thumbColor: Colors.white,
              padding: const EdgeInsets.all(3),
              children: {
                FlowViewMode.forYou: segment(l10n.ljFlowForYou, 'flow-for-you'),
                FlowViewMode.bySubject: segment(
                  l10n.ljFlowBySubject,
                  'flow-by-subject',
                ),
              },
              onValueChanged: (value) {
                if (value == null || value == mode) return;
                HapticFeedback.selectionClick();
                onMode(value);
              },
            ),
          ),
          if (mode == FlowViewMode.bySubject && subjects.isNotEmpty) ...[
            const SizedBox(height: IntelliaSpacing.sm),
            SingleChildScrollView(
              key: const ValueKey('flow-subjects'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final subject in subjects) ...[
                    _SubjectPill(
                      subjectKey: subject.key,
                      label: subjectDisplayName(
                        context,
                        subject.key,
                        subject.label,
                      ),
                      selected: subject.key == selected,
                      onTap: () {
                        if (subject.key == selected) return;
                        HapticFeedback.selectionClick();
                        onSubject(subject.key);
                      },
                    ),
                    const SizedBox(width: IntelliaSpacing.xs),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectPill extends StatelessWidget {
  const _SubjectPill({
    required this.subjectKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String subjectKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final identity = SubjectVisualIdentity.of(subjectKey);
    final palette = identity.palette(Brightness.light);
    final foreground = selected ? Colors.white : palette.accent;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        key: ValueKey('flow-subject-$subjectKey'),
        color: selected ? palette.accent : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? palette.accent : palette.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(identity.icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(label, style: ContentText.label(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
