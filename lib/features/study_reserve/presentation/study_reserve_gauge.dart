import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../domain/study_reserve.dart';

/// Jauge product-safe de la « Réserve d'étude », partagée par l'espace élève et
/// les cartes enfant côté parent. Affiche une jauge 100→0 %, le pourcentage
/// restant, un statut lisible et la date de renouvellement — jamais de terme
/// technique (token, XP, crédit).
class StudyReserveGauge extends StatelessWidget {
  const StudyReserveGauge({
    required this.reserve,
    this.compact = false,
    super.key,
  });

  final StudyReserve reserve;
  final bool compact;

  Color _color() => switch (reserve.status) {
    StudyReserveStatus.healthy => IntelliaColors.success,
    StudyReserveStatus.warning => IntelliaColors.warning,
    StudyReserveStatus.low => IntelliaColors.warning,
    StudyReserveStatus.critical => IntelliaColors.error,
    StudyReserveStatus.depleted => IntelliaColors.error,
  };

  String _statusLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (reserve.status) {
      StudyReserveStatus.healthy => l10n.studyReserveStatusHealthy,
      StudyReserveStatus.warning => l10n.studyReserveStatusWarning,
      StudyReserveStatus.low => l10n.studyReserveStatusLow,
      StudyReserveStatus.critical => l10n.studyReserveStatusCritical,
      StudyReserveStatus.depleted => l10n.studyReserveStatusDepleted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = _color();
    final date = reserve.cycleEnd;
    return Container(
      key: const ValueKey('study-reserve-gauge'),
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.battery_charging_full_rounded, size: 18, color: color),
              const SizedBox(width: IntelliaSpacing.xs),
              Expanded(
                child: Text(
                  l10n.studyReserveTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                l10n.studyReserveRemaining(reserve.percentRemaining),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(IntelliaRadii.full),
            child: LinearProgressIndicator(
              value: reserve.percentRemaining / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            _statusLabel(context),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          if (reserve.isDepleted && !compact) ...[
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              l10n.studyReserveDepletedHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (date != null && !compact) ...[
            const SizedBox(height: IntelliaSpacing.xxs),
            Text(
              l10n.studyReserveRenews(_formatDate(date)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: IntelliaColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}
