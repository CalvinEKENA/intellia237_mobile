import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../tour_guide/domain/role_tour_steps.dart';
import '../../tour_guide/domain/tour_guide_target_ids.dart';
import '../../tour_guide/presentation/contextual_tour_guide.dart';

class RolePlaceholderScreen extends ConsumerStatefulWidget {
  const RolePlaceholderScreen({required this.role, super.key});

  final AppRole role;

  @override
  ConsumerState<RolePlaceholderScreen> createState() =>
      _RolePlaceholderScreenState();
}

class _RolePlaceholderScreenState extends ConsumerState<RolePlaceholderScreen> {
  late final Map<String, GlobalKey> _tourTargets = {
    TourGuideTargetIds.roleHero: GlobalKey(
      debugLabel: TourGuideTargetIds.roleHero,
    ),
    TourGuideTargetIds.roleSignOut: GlobalKey(
      debugLabel: TourGuideTargetIds.roleSignOut,
    ),
  };

  bool _tourLaunchRequested = false;

  @override
  Widget build(BuildContext context) {
    _scheduleTourGuide();

    final textTheme = Theme.of(context).textTheme;
    final roleColor = AppRoleColors.byRole(widget.role);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.label} Space'),
        actions: [
          IconButton(
            key: _tourTargets[TourGuideTargetIds.roleSignOut],
            tooltip: 'Se deconnecter',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          KeyedSubtree(
            key: _tourTargets[TourGuideTargetIds.roleHero],
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  colors: [
                    roleColor.withValues(alpha: 0.18),
                    roleColor.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue dans l\'espace ${widget.role.label}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Consultez les options disponibles pour votre profil.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Le placeholder reste guide pour les roles non-student durant la phase MVP.
  void _scheduleTourGuide() {
    if (_tourLaunchRequested) return;

    _tourLaunchRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowContextualTourGuide(
        context: context,
        ref: ref,
        expectedRole: widget.role,
        targets: _tourTargets,
        steps: roleTourSteps(widget.role),
      );
    });
  }
}
