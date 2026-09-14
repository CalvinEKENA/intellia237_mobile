import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../data/study_reserve_service.dart';
import 'study_reserve_gauge.dart';

/// Carte « Réserve d'étude » prête à poser : lit [studyReserveProvider] et rend
/// la jauge. [studentId] null = l'élève courant ; un UID = un enfant lié (parent).
///
/// Trois états distincts, jamais une donnée fictive :
/// - chargement → cadre « Réserve d'étude » avec barre indéterminée ;
/// - échec d'appel (réseau, service) → message de chargement + « Réessayer » ;
/// - réponse serveur « unavailable » → la jauge l'affiche explicitement.
class StudyReserveCard extends ConsumerWidget {
  const StudyReserveCard({this.studentId, this.compact = false, super.key});

  final String? studentId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studyReserveProvider(studentId));
    return async.when(
      loading: () => const _StudyReserveFrame(
        key: ValueKey('study-reserve-loading'),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(IntelliaRadii.full)),
          child: LinearProgressIndicator(minHeight: 8),
        ),
      ),
      error: (_, _) => _StudyReserveFrame(
        key: const ValueKey('study-reserve-error'),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: IntelliaSpacing.xs,
          children: [
            Text(
              context.l10n.studyReserveLoadError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: IntelliaColors.textTertiary,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(studyReserveProvider(studentId)),
              child: Text(context.l10n.retryLabel),
            ),
          ],
        ),
      ),
      data: (reserve) => StudyReserveGauge(reserve: reserve, compact: compact),
    );
  }
}

/// Cadre neutre partagé par les états chargement/erreur.
class _StudyReserveFrame extends StatelessWidget {
  const _StudyReserveFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const color = IntelliaColors.textTertiary;
    return Container(
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
              const Icon(
                Icons.battery_charging_full_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: IntelliaSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.studyReserveTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          child,
        ],
      ),
    );
  }
}
