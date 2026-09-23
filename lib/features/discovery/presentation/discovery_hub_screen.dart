import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/widgets/auth_experience_scaffold.dart';

/// Découverte : une identité prouvée sans profil explore l'application.
///
/// Invariants (vérifiés par les tests) : aucune lecture Firestore, aucune
/// Cloud Function, aucun appel Gemini ou Vertex, aucune donnée personnelle ;
/// ce fichier n'importe que Material, Riverpod, go_router, les routes, le
/// contrôleur d'authentification et les couleurs de l'entrée. Le contenu est
/// statique et présenté comme fictif.
///
/// Registre de décisions (refonte Auth V2) : l'aperçu parent montrait
/// « Samuel (Classe de 3ème) », 4 h 15 et 86 % — des chiffres qui se lisent
/// comme ceux d'un vrai élève. Les exemples sont désormais génériques et
/// annoncés comme fictifs.
class DiscoveryHubScreen extends ConsumerWidget {
  const DiscoveryHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AuthExperienceColors.canvas,
      appBar: AppBar(
        backgroundColor: AuthExperienceColors.canvas,
        foregroundColor: AuthExperienceColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AuthExperienceColors.indigo,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.discoveryBadge.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'CampaignBody',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AuthExperienceColors.surface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'INTELLIA237',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'CampaignBody',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const ValueKey('discovery-exit-button'),
            onPressed: auth.exitDiscoveryMode,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(l10n.discoveryExit),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              key: const ValueKey('discovery-hub'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  l10n.discoveryTitle,
                  style: const TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: AuthExperienceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.discoveryIntro,
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    fontSize: 13.5,
                    height: 1.5,
                    color: AuthExperienceColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _Notice(text: l10n.discoveryFictionalNotice),
                const SizedBox(height: 20),
                _Section(
                  key: const ValueKey('discovery-tutors'),
                  icon: Icons.psychology_rounded,
                  title: l10n.discoveryTutorsTitle,
                  children: [
                    _CompanionSample(
                      name: 'Kira',
                      role: l10n.discoveryKiraRole,
                      sample: l10n.discoveryKiraSample,
                    ),
                    const SizedBox(height: 10),
                    _CompanionSample(
                      name: 'Léo',
                      role: l10n.discoveryLeoRole,
                      sample: l10n.discoveryLeoSample,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  key: const ValueKey('discovery-parcours'),
                  icon: Icons.auto_stories_rounded,
                  title: l10n.discoveryParcoursTitle,
                  children: [_Body(l10n.discoveryParcoursBody)],
                ),
                const SizedBox(height: 14),
                _Section(
                  key: const ValueKey('discovery-parent'),
                  icon: Icons.family_restroom_rounded,
                  title: l10n.discoveryParentTitle,
                  children: [
                    _Body(l10n.discoveryParentBody),
                    const SizedBox(height: 10),
                    _Notice(
                      key: const ValueKey('discovery-parent-example'),
                      text: l10n.discoveryParentExample,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.discoveryCreateTitle,
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AuthExperienceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('discovery-cta-parent'),
                  onPressed: () => context.go(AppRoutes.parentRegistration),
                  style: _ctaStyle(filled: true),
                  icon: const Icon(Icons.family_restroom_rounded),
                  label: Text(
                    l10n.discoveryCtaParent,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('discovery-cta-student'),
                  onPressed: () => context.go(AppRoutes.studentRegistration),
                  style: _ctaStyle(filled: false),
                  icon: const Icon(Icons.school_rounded),
                  label: Text(
                    l10n.discoveryCtaStudent,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('discovery-cta-join-code'),
                  onPressed: () => context.push(AppRoutes.studentAccessCode),
                  style: _ctaStyle(filled: false),
                  icon: const Icon(Icons.key_rounded),
                  label: Text(
                    l10n.discoveryCtaCode,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static ButtonStyle _ctaStyle({required bool filled}) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    const minimumSize = Size.fromHeight(52);
    return filled
        ? FilledButton.styleFrom(
            backgroundColor: AuthExperienceColors.indigo,
            foregroundColor: AuthExperienceColors.surface,
            minimumSize: minimumSize,
            padding: padding,
            shape: shape,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: AuthExperienceColors.textPrimary,
            side: const BorderSide(color: AuthExperienceColors.border),
            minimumSize: minimumSize,
            padding: padding,
            shape: shape,
          );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AuthExperienceColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AuthExperienceColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AuthExperienceColors.indigo),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AuthExperienceColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'CampaignBody',
      fontSize: 13,
      height: 1.5,
      color: AuthExperienceColors.textSecondary,
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AuthExperienceColors.surfaceSoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: AuthExperienceColors.gold,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'CampaignBody',
              fontSize: 12.5,
              height: 1.45,
              color: AuthExperienceColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompanionSample extends StatelessWidget {
  const _CompanionSample({
    required this.name,
    required this.role,
    required this.sample,
  });

  final String name;
  final String role;
  final String sample;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: ' · $role'),
          ],
        ),
        style: const TextStyle(
          fontFamily: 'CampaignBody',
          fontSize: 13,
          color: AuthExperienceColors.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AuthExperienceColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AuthExperienceColors.border),
        ),
        child: Text(
          sample,
          style: const TextStyle(
            fontFamily: 'CampaignBody',
            fontSize: 13,
            height: 1.45,
            fontStyle: FontStyle.italic,
            color: AuthExperienceColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}
