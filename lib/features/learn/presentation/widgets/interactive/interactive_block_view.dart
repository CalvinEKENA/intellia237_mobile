import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/interactive_component.dart';
import 'pythagoras_visual.dart';

/// Catalogue des expériences interactives compilées dans l'application.
///
/// Un seul composant y figure aujourd'hui : il sert à prouver que le registre
/// tient — validation, versionnement, repli — et non à ouvrir la bibliothèque
/// interactive. Les clés à venir s'enregistreront ici, sans que rien d'autre
/// ne bouge.
final interactiveComponentRegistryProvider =
    Provider<InteractiveComponentRegistry>(
      (ref) =>
          InteractiveComponentRegistry(const [PythagorasVisualComponent()]),
    );

/// Rend une expérience interactive, ou explique pourquoi elle est indisponible.
///
/// Une clé inconnue n'est pas une panne : c'est une leçon plus récente que
/// l'application installée. L'élève reçoit alors le résumé pédagogique de
/// l'activité plutôt qu'un espace vide ou un message d'erreur.
class InteractiveBlockView extends ConsumerWidget {
  const InteractiveBlockView({required this.spec, super.key});

  final InteractiveComponentSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(interactiveComponentRegistryProvider);
    final refusal = registry.rejectionReason(spec);

    if (refusal != null) {
      return InteractiveFallbackCard(spec: spec, reason: refusal);
    }

    return registry.resolve(spec.componentKey)!.build(context, spec.config);
  }
}

/// Repli lisible : ce que l'activité apporte, et pourquoi elle ne s'affiche pas.
class InteractiveFallbackCard extends StatelessWidget {
  const InteractiveFallbackCard({
    required this.spec,
    required this.reason,
    super.key,
  });

  final InteractiveComponentSpec spec;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = spec.summary;

    return Container(
      key: const ValueKey('interactive-fallback'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_mosaic_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Activité interactive',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (summary != null && summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            // Le contenu pédagogique passe même quand l'interaction ne passe pas.
            Text(summary, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Text(
            reason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
