import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/fit_viewport.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';

class ProfileRecoveryScreen extends ConsumerWidget {
  const ProfileRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final l10n = context.l10n;
    final needsSetup = auth.status == AuthStatus.needsOnboarding;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authProfileSetupTitle)),
      // Écran fixe, comme toute l'authentification.
      body: FitViewport(
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                needsSetup
                    ? Icons.person_add_alt_1_rounded
                    : Icons.sync_problem,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                needsSetup
                    ? l10n.authCompleteProfileTitle
                    : l10n.authSessionActiveTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              Text(
                needsSetup
                    ? l10n.authChooseProfileBody
                    : l10n.authProfileSyncFailureBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: IntelliaSpacing.lg),
              if (needsSetup) ...[
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.studentRegistration),
                  icon: const Icon(Icons.school_rounded),
                  label: Text(l10n.phoneCreateStudentProfile),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.parentRegistration),
                  icon: const Icon(Icons.family_restroom_rounded),
                  label: Text(l10n.phoneCreateParentProfile),
                ),
              ] else
                FilledButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .retryProfileResolution(),
                  icon: auth.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(l10n.retryLabel),
                ),
              const SizedBox(height: IntelliaSpacing.sm),
              TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signOut(),
                child: Text(l10n.signOutTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
