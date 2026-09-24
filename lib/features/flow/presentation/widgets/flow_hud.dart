import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../application/flow_controller.dart';

/// Barre supérieure du Flow : niveau, points, série, et fermeture.
///
/// Discrète et toujours présente — l'élève garde le fil de sa progression
/// sans jamais revenir à une liste.
class FlowHud extends ConsumerWidget {
  const FlowHud({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(flowControllerProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.md,
          IntelliaSpacing.xs,
          IntelliaSpacing.md,
          0,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _ExitButton(onTap: onClose),
                const SizedBox(width: IntelliaSpacing.xs),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: [
                        _pill(
                          icon: Icons.bolt_rounded,
                          label: '+${p.sessionPoints} session',
                          color: IntelliaColors.pointsGold,
                          semanticLabel: context.l10n.sessionVerifiedPoints(
                            p.sessionPoints,
                          ),
                        ),
                        const SizedBox(width: IntelliaSpacing.xs),
                        _pill(
                          icon: Icons.verified_rounded,
                          label: p.verifiedTotalPoints == null
                              ? context.l10n.totalPendingShort
                              : context.l10n.totalPointsShort(
                                  p.verifiedTotalPoints!,
                                ),
                          color: IntelliaColors.brandIndigo,
                          semanticLabel: p.verifiedTotalPoints == null
                              ? context.l10n.totalPendingValidation
                              : context.l10n.totalVerifiedPoints(
                                  p.verifiedTotalPoints!,
                                ),
                        ),
                        const SizedBox(width: IntelliaSpacing.xs),
                        if (p.pendingValidationCount > 0)
                          _pill(
                            icon: p.isSyncing
                                ? Icons.sync_rounded
                                : Icons.cloud_upload_outlined,
                            label: context.l10n.pendingValidationShort(
                              p.pendingValidationCount,
                            ),
                            color: IntelliaColors.warning,
                            semanticLabel: context.l10n.offlineActivitiesToSync(
                              p.pendingValidationCount,
                            ),
                            onTap: p.isSyncing
                                ? null
                                : () => ref
                                      .read(flowControllerProvider.notifier)
                                      .retryPending(),
                          )
                        else
                          _pill(
                            icon: Icons.local_fire_department_rounded,
                            label: '${p.streakDays}',
                            color: IntelliaColors.warning,
                            semanticLabel: context.l10n.streakA11y(
                              p.streakDays,
                              '',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Row(
              children: [
                Text(
                  context.l10n.levelShort(p.level),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: IntelliaColors.textSecondary,
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: p.levelProgress),
                      duration: IntelliaMotion.slow,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 5,
                        backgroundColor: Colors.black.withValues(alpha: 0.06),
                        valueColor: const AlwaysStoppedAnimation(
                          IntelliaColors.brandIndigo,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color color,
    required String semanticLabel,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: IntelliaColors.surfaceSolid.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(IntelliaRadii.full),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: IntelliaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: onTap == null
          ? content
          : IntelliaPressable(onTap: onTap, child: content),
    );
  }
}

/// Sortie du Parcours (retour appareil, 24/09/2026) : une petite croix grise
/// passait inaperçue. Une pastille foncée, avec une flèche et le mot
/// « Quitter », se voit du premier coup d'œil.
class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.onTap});

  final VoidCallback onTap;

  static const exitKey = ValueKey('flow-exit');

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.flowExit;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IntelliaPressable(
        key: exitKey,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: BoxDecoration(
            color: IntelliaColors.textPrimary,
            borderRadius: BorderRadius.circular(IntelliaRadii.full),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
