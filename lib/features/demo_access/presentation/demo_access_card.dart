import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../application/demo_access_providers.dart';
import '../domain/demo_access.dart';

/// Sur l'accueil du compte démo : la classe explorée et « Changer de
/// classe ». Au premier passage sur l'appareil, le message d'accueil
/// s'ouvre. Pour tout autre compte, rien.
class DemoAccessCard extends ConsumerStatefulWidget {
  const DemoAccessCard({super.key});

  @override
  ConsumerState<DemoAccessCard> createState() => _DemoAccessCardState();
}

class _DemoAccessCardState extends ConsumerState<DemoAccessCard> {
  bool _welcomeChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_welcomeChecked || !ref.read(isDemoAccessProvider)) return;
    _welcomeChecked = true;
    unawaited(_welcomeOnce());
  }

  Future<void> _welcomeOnce() async {
    final memory = ref.read(demoWelcomeMemoryProvider);
    if (await memory.seen() || !mounted) return;
    await memory.markSeen();
    if (!mounted) return;
    await showDemoWelcome(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isDemoAccessProvider)) return const SizedBox.shrink();
    final l10n = context.l10n;
    final surface = TabSurface.of(context);
    final current = ref.watch(demoCurrentClassProvider).valueOrNull;
    final card = Container(
      key: const ValueKey('demo-access-card'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: surface.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IntelliaFlag.yellow.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: IntelliaFlag.yellow.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF9A6B00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.demoCardEyebrow,
                  style: GoogleFonts.montserrat(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                    color: const Color(0xFF9A6B00),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.demoCardTitle(current?.label ?? '…'),
                  key: const ValueKey('demo-access-current'),
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: surface.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.demoCardSubtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    height: 1.35,
                    color: surface.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const ValueKey('demo-access-change'),
                  style: TextButton.styleFrom(
                    foregroundColor: surface.accent,
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: AlignmentDirectional.centerStart,
                  ),
                  onPressed: () => showDemoClassPicker(context, ref),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: Text(
                    l10n.demoCardAction,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: IntelliaSpacing.md),
      child: card,
    );
  }
}

/// Le message d'accueil de l'accès démo.
Future<void> showDemoWelcome(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _DemoWelcomeSheet(
        onStart: () async {
          Navigator.of(sheetContext).pop();
          final current = ref.read(demoCurrentClassProvider).valueOrNull;
          if (current != DemoAccess.recommended && context.mounted) {
            await _applyClass(context, ref, DemoAccess.recommended);
          }
        },
        onChooseOther: () async {
          Navigator.of(sheetContext).pop();
          if (context.mounted) await showDemoClassPicker(context, ref);
        },
      ),
    );

class _DemoWelcomeSheet extends StatelessWidget {
  const _DemoWelcomeSheet({required this.onStart, required this.onChooseOther});

  final VoidCallback onStart;
  final VoidCallback onChooseOther;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    TextStyle body() => GoogleFonts.manrope(
      fontSize: 15,
      height: 1.5,
      color: scheme.onSurface.withValues(alpha: 0.82),
    );
    return SingleChildScrollView(
      key: const ValueKey('demo-welcome'),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.demoWelcomeEyebrow,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: const Color(0xFF9A6B00),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              l10n.demoWelcomeTitle,
              style: GoogleFonts.manrope(
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(l10n.demoWelcomeBody, style: body()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IntelliaFlag.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: IntelliaFlag.green.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: IntelliaFlag.green,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.demoWelcomeTip, style: body())),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.demoWelcomeChangeLater, style: body()),
          const SizedBox(height: 22),
          FilledButton(
            key: const ValueKey('demo-welcome-start'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onStart,
            child: Text(
              l10n.demoWelcomeStart,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('demo-welcome-other'),
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: onChooseOther,
            child: Text(
              l10n.demoWelcomeOther,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toutes les classes ; la Terminale D est mise en avant.
Future<void> showDemoClassPicker(BuildContext context, WidgetRef ref) async {
  final choice = await showModalBottomSheet<DemoClassOption>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _DemoClassPicker(
      current: ref.read(demoCurrentClassProvider).valueOrNull,
    ),
  );
  if (choice != null && context.mounted) {
    await _applyClass(context, ref, choice);
  }
}

Future<void> _applyClass(
  BuildContext context,
  WidgetRef ref,
  DemoClassOption option,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await changeDemoClass(ref, option);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.demoClassChanged(option.label))),
    );
  } catch (_) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.demoClassChangeFailed)),
    );
  }
}

class _DemoClassPicker extends StatelessWidget {
  const _DemoClassPicker({required this.current});

  final DemoClassOption? current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final options = DemoAccess.options;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        key: const ValueKey('demo-class-picker'),
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.demoPickerTitle,
              style: GoogleFonts.manrope(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.demoPickerSubtitle,
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 14),
          _ClassTile(
            option: DemoAccess.recommended,
            highlighted: true,
            badge: l10n.demoPickerRecommended,
            current: current == DemoAccess.recommended,
            currentLabel: l10n.demoPickerCurrent,
          ),
          section(l10n.demoPickerFrancophone),
          for (final option in options.where((o) => !o.isAnglophone))
            if (option != DemoAccess.recommended)
              _ClassTile(
                option: option,
                current: current == option,
                currentLabel: l10n.demoPickerCurrent,
              ),
          section(l10n.demoPickerAnglophone),
          for (final option in options.where((o) => o.isAnglophone))
            _ClassTile(
              option: option,
              current: current == option,
              currentLabel: l10n.demoPickerCurrent,
            ),
        ],
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.option,
    required this.current,
    required this.currentLabel,
    this.highlighted = false,
    this.badge,
  });

  final DemoClassOption option;
  final bool current;
  final String currentLabel;
  final bool highlighted;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = highlighted ? IntelliaFlag.green : scheme.primary;
    final tag = current ? currentLabel : badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: highlighted
            ? IntelliaFlag.green.withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: current || highlighted
                ? accent.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.4,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(
            'demo-class-${option.classLevel}-${option.seriesValue ?? '-'}',
          ),
          onTap: () => Navigator.of(context).pop(option),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  if (current) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle_rounded, color: accent, size: 22),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
