import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/design_tokens.dart';

/// Ce que voit l'élève quand le fil n'a rien à lui proposer.
///
/// Registre de décisions : plutôt qu'un contenu de démonstration servi comme
/// s'il était validé, un fil vide se dit. Le cas se produit hors ligne à la
/// première ouverture, ou quand aucune publication n'a encore été validée
/// pour son niveau. L'écran ne culpabilise pas et laisse une porte de sortie.
class FlowEmptyView extends StatelessWidget {
  const FlowEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                'Le Flow arrive',
                key: const ValueKey('flow-empty-title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              Text(
                'Aucune carte n’est encore publiée pour ta classe. '
                'Reviens après une synchronisation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xl),
              FilledButton(
                key: const ValueKey('flow-empty-exit'),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.studentHome);
                  }
                },
                child: const Text('Revenir à l’accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
