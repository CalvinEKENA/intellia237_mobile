import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/presentation/widgets/auth_controls.dart';
import '../../auth/presentation/widgets/living_pass.dart';
import '../../auth/presentation/widgets/pass_auth_progress.dart';
import '../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../application/family_access_providers.dart';
import '../domain/family_access_models.dart';

final familyEntryChildrenProvider =
    FutureProvider.autoDispose<List<ParentChildSummary>>((ref) {
      final auth = ref.watch(
        authControllerProvider.select(
          (state) => (
            pending: state.familyEntryPending,
            role: state.role,
            uid: state.userId,
          ),
        ),
      );
      if (!auth.pending || auth.role != AppRole.parent) {
        return const [];
      }
      return ref.watch(familyAccessRepositoryProvider).listParentChildren();
    });

/// Choix de personne après preuve du numéro familial, avant toute page parent.
class FamilyEntryScreen extends ConsumerStatefulWidget {
  const FamilyEntryScreen({super.key});

  @override
  ConsumerState<FamilyEntryScreen> createState() => _FamilyEntryScreenState();
}

class _FamilyEntryScreenState extends ConsumerState<FamilyEntryScreen> {
  bool _opening = false;
  bool _failed = false;
  bool _autoTried = false;

  Future<void> _open(String studentId) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    final opened = await ref
        .read(authControllerProvider.notifier)
        .openFamilyChild(studentId);
    if (!mounted) return;
    setState(() {
      _opening = false;
      _failed = !opened;
    });
    if (opened) context.go(AppRoutes.studentHome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final children = ref.watch(familyEntryChildrenProvider);
    return AuthExperienceScaffold(
      showBackButton: false,
      pass: LivingPass(
        seal: PassAuthProgress.session(ref.watch(authControllerProvider)),
        phase: l10n.authFamilyWho,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            title: l10n.authFamilyWho,
            subtitle: l10n.authFamilyChooseBody,
          ),
          const SizedBox(height: 24),
          if (_failed) AuthErrorBanner(message: l10n.authFamilyUnavailable),
          children.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Column(
              children: [
                Text(l10n.authFamilyUnavailable),
                TextButton(
                  onPressed: () => ref.invalidate(familyEntryChildrenProvider),
                  child: Text(l10n.authFamilyRetry),
                ),
              ],
            ),
            data: (items) {
              if (items.length == 1 && !_autoTried) {
                _autoTried = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _open(items.single.studentId);
                });
              }
              return Column(
                children: [
                  if (items.isEmpty) Text(l10n.authFamilyNoChildren),
                  for (final child in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          key: ValueKey('family-child-${child.studentId}'),
                          enabled: !_opening,
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(
                            '${child.firstName} ${child.lastName}'.trim(),
                          ),
                          subtitle: Text(
                            [
                              '${child.classLevel} ${child.series ?? ''}'
                                  .trim(),
                              child.establishmentName,
                            ].where((line) => line.isNotEmpty).join('\n'),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _open(child.studentId),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (_opening) const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _opening
                ? null
                : () => context.go(AppRoutes.parentAccess),
            child: Text(l10n.authParentSpace),
          ),
          TextButton(
            onPressed: _opening
                ? null
                : ref.read(authControllerProvider.notifier).signOut,
            child: Text(l10n.authUseAnotherAccount),
          ),
        ],
      ),
    );
  }
}

/// Aucune bascule locale : l'identité courante est fermée avant la preuve parent.
class ParentAccessScreen extends ConsumerWidget {
  const ParentAccessScreen({super.key});

  Future<void> _authenticate(
    BuildContext context,
    WidgetRef ref,
    String route,
  ) async {
    final router = GoRouter.of(context);
    await ref.read(authControllerProvider.notifier).signOut();
    // La déconnexion peut déjà avoir retiré cet écran de la pile.
    router.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AuthExperienceScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            title: l10n.authParentSpace,
            subtitle: l10n.authParentProofBody,
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            key: const ValueKey('parent-proof-phone'),
            label: l10n.schoolHeadContinuePhone,
            icon: Icons.phone_android_rounded,
            onTap: () => _authenticate(
              context,
              ref,
              AppRoutes.phoneRegistration(AppRole.parent),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('parent-proof-email'),
            onPressed: () => _authenticate(
              context,
              ref,
              AppRoutes.emailSignIn(AppRole.parent),
            ),
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(l10n.schoolHeadContinueEmail),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
