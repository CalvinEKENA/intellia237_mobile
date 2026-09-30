import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../rewards/domain/haptic_pattern.dart';
import '../../application/user_preferences_controller.dart';

/// Cupertino grouping with INTELLIA's paper, ink and indigo. Content keeps its
/// natural height: large Android fonts never have to fit an iOS-sized row.
class IntelliaProfileSection extends StatelessWidget {
  const IntelliaProfileSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CupertinoTheme(
    data: CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: IntelliaColors.brandIndigo,
      textTheme: CupertinoTextThemeData(
        textStyle: IntelliaTypography.body(),
        actionTextStyle: IntelliaTypography.body().copyWith(
          color: IntelliaColors.brandIndigo,
        ),
      ),
    ),
    child: CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      decoration: BoxDecoration(
        color: IntelliaColors.surfaceElevated,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: const Color(0x0F5856D6)),
        boxShadow: IntelliaShadows.card(IntelliaColors.textPrimary),
      ),
      header: Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(title, style: IntelliaTypography.title3()),
        ),
      ),
      hasLeading: false,
      dividerMargin: 16,
      additionalDividerMargin: 0,
      children: children,
    ),
  );
}

/// Deliberately wraps text instead of the fixed-line CupertinoListTile.
/// Controls move beneath the copy on narrow / large-text devices.
class IntelliaProfileTile extends ConsumerWidget {
  const IntelliaProfileTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.selected = false,
    this.stackTrailing = false,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool selected;
  final bool stackTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = destructive
        ? const Color(0xFFAD2838)
        : IntelliaColors.textPrimary;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: IntelliaTypography.body().copyWith(
            color: ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          child: title,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          DefaultTextStyle.merge(
            style: IntelliaTypography.caption().copyWith(
              color: IntelliaColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
            child: subtitle!,
          ),
        ],
      ],
    );
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: LayoutBuilder(
        builder: (context, box) {
          final stacked =
              stackTrailing &&
              (box.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3);
          final end =
              trailing ??
              (onTap == null
                  ? null
                  : const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: IntelliaColors.textSecondary,
                    ));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (destructive ? ink : IntelliaColors.brandIndigo)
                            .withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          size: 20,
                          color: destructive ? ink : IntelliaColors.brandIndigo,
                        ),
                        child: leading!,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: copy),
                  if (!stacked && end != null) ...[
                    const SizedBox(width: 10),
                    end,
                  ],
                ],
              ),
              if (stacked && end != null) ...[
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: end),
              ],
            ],
          );
        },
      ),
    );
    if (onTap == null) return body;
    return Semantics(
      selected: selected ? true : null,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        onPressed: () {
          profileSelectionHaptic(ref);
          onTap!();
        },
        child: body,
      ),
    );
  }
}

class IntelliaProfileSwitch extends ConsumerWidget {
  const IntelliaProfileSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IntelliaProfileTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    stackTrailing: true,
    trailing: Semantics(
      label: title,
      child: CupertinoSwitch(
        value: value,
        activeTrackColor: IntelliaColors.brandIndigo,
        onChanged: (next) {
          profileSelectionHaptic(ref);
          onChanged(next);
        },
      ),
    ),
  );
}

void profileSelectionHaptic(WidgetRef ref) {
  if (ref.read(userPreferencesProvider).haptics != HapticMode.off) {
    HapticFeedback.selectionClick();
  }
}

bool profileMotionReduced(BuildContext context, WidgetRef ref) =>
    ref.read(userPreferencesProvider).reduceMotion ||
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context);

AnimationStyle profileDialogAnimation(BuildContext context, WidgetRef ref) =>
    profileMotionReduced(context, ref)
    ? AnimationStyle.noAnimation
    : const AnimationStyle(
        duration: Duration(milliseconds: 180),
        reverseDuration: Duration(milliseconds: 120),
      );

/// The standard Cupertino sheet uses a fixed slide duration. This adapter
/// keeps its native focus/barrier semantics while honoring Reduce Motion.
class ProfileActionSheetRoute<T> extends CupertinoModalPopupRoute<T> {
  ProfileActionSheetRoute({required super.builder, required this.reduced})
    : super(semanticsDismissible: true);
  final bool reduced;

  @override
  Duration get transitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 180);

  @override
  Duration get reverseTransitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 120);
}
