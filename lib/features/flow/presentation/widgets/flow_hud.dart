import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
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
                _circleButton(Icons.close_rounded, onClose),
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
                          semanticLabel:
                              '${p.sessionPoints} points vérifiés dans cette session',
                        ),
                        const SizedBox(width: IntelliaSpacing.xs),
                        _pill(
                          icon: Icons.verified_rounded,
                          label: p.verifiedTotalPoints == null
                              ? 'Total —'
                              : '${p.verifiedTotalPoints} total',
                          color: IntelliaColors.brandIndigo,
                          semanticLabel: p.verifiedTotalPoints == null
                              ? 'Total en attente de validation serveur'
                              : '${p.verifiedTotalPoints} points vérifiés au total',
                        ),
                        const SizedBox(width: IntelliaSpacing.xs),
                        if (p.pendingValidationCount > 0)
                          _pill(
                            icon: p.isSyncing
                                ? Icons.sync_rounded
                                : Icons.cloud_upload_outlined,
                            label: '${p.pendingValidationCount} à valider',
                            color: IntelliaColors.warning,
                            semanticLabel:
                                '${p.pendingValidationCount} activités hors ligne à synchroniser',
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
                            semanticLabel: 'Série de ${p.streakDays} jours',
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
                  'Niv. ${p.level}',
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

  Widget _circleButton(IconData icon, VoidCallback onTap) => IntelliaPressable(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: IntelliaColors.surfaceSolid.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Icon(icon, size: 20, color: IntelliaColors.textPrimary),
    ),
  );

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
