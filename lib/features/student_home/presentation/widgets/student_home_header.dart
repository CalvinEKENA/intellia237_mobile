import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../../../core/widgets/tab_presentation.dart';

/// En-tête de l'accueil élève.
///
/// Contrat de lisibilité : les couleurs proviennent de [TabSurface] — le texte
/// est sombre sur le backdrop clair (plus de blanc « sauvé » par un halo, plus
/// d'ombre de texte comme substitut de contraste, plus de boucle d'animation
/// permanente).
class StudentHomeHeader extends StatelessWidget {
  const StudentHomeHeader({
    required this.firstName,
    this.onProfileTap,
    this.onNotificationsTap,
    this.unreadNotifications = 0,
    super.key,
  });

  final String firstName;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty ? context.l10n.mySpace : firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xxs),
              Text(
                context.l10n.myLearningSpace,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: s.numberAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: IntelliaSpacing.sm),

        Semantics(
          button: true,
          label: context.l10n.openNotificationsA11y(unreadNotifications),
          child: Tooltip(
            message: context.l10n.notificationsTitle,
            child: IconButton(
              key: const ValueKey('student-notifications-button'),
              onPressed: onNotificationsTap,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(
                  unreadNotifications > 99
                      ? '99+'
                      : unreadNotifications.toString(),
                ),
                child: Icon(
                  unreadNotifications > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: s.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: IntelliaSpacing.xs),

        // Avatar : anneau doré statique (l'entrée est animée par le parent).
        Semantics(
          container: true,
          button: true,
          label: context.l10n.openMyProfile,
          child: IntelliaPressable(
            onTap: onProfileTap,
            child: _AvatarRing(
              initial: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E',
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        gradient: AppGradients.heroGold,
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.heroNavy,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
