import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/fit_viewport.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Guide de l'espace parent (retour propriétaire, 24/09/2026).
///
/// Un parent se perdait entre les codes (code parent, code d'accès), l'ajout
/// d'un enfant et le passage au compte de l'enfant sur le même téléphone.
/// Six étapes courtes, illustrées, qu'on fait défiler : chacune dit où
/// toucher, avec les libellés exacts de l'application.
///
/// Ouvert une fois à la première visite du parent sur cet appareil, puis à
/// tout moment par la boussole en haut de l'espace ou depuis Profil.
abstract final class ParentGuide {
  static const sheetKey = ValueKey('parent-guide');
  static const nextKey = ValueKey('parent-guide-next');
  static const skipKey = ValueKey('parent-guide-skip');
  static const openKey = ValueKey('parent-guide-open');

  static String _seenKey(String uid) => 'parent_guide_seen_v1_$uid';

  static List<({IconData icon, String title, String body})> steps(
    AppLocalizations l10n,
  ) => [
    (
      icon: Icons.family_restroom_rounded,
      title: l10n.parentGuideWelcomeTitle,
      body: l10n.parentGuideWelcomeBody,
    ),
    (
      icon: Icons.person_add_alt_1_rounded,
      title: l10n.parentGuideAddTitle,
      body: l10n.parentGuideAddBody,
    ),
    (
      icon: Icons.link_rounded,
      title: l10n.parentGuideLinkTitle,
      body: l10n.parentGuideLinkBody,
    ),
    (
      icon: Icons.key_rounded,
      title: l10n.parentGuideAccessTitle,
      body: l10n.parentGuideAccessBody,
    ),
    (
      icon: Icons.swap_horiz_rounded,
      title: l10n.parentGuideSwitchTitle,
      body: l10n.parentGuideSwitchBody,
    ),
    (
      icon: Icons.explore_rounded,
      title: l10n.parentGuideAgainTitle,
      body: l10n.parentGuideAgainBody,
    ),
  ];

  /// Montre le guide la première fois que ce parent arrive sur cet appareil.
  static Future<void> maybeShowOnce(BuildContext context, String uid) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_seenKey(uid)) ?? false) return;
      if (!context.mounted) return;
      await show(context);
      await preferences.setBool(_seenKey(uid), true);
    } catch (_) {
      // Sans stockage local, le guide reste accessible par la boussole.
    }
  }

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ParentGuideSheet(),
  );
}

class _ParentGuideSheet extends StatefulWidget {
  const _ParentGuideSheet();

  @override
  State<_ParentGuideSheet> createState() => _ParentGuideSheetState();
}

class _ParentGuideSheetState extends State<_ParentGuideSheet> {
  final _pages = PageController();
  var _index = 0;

  static const _ink = Color(0xFF25233E);
  static const _paper = Color(0xFFFBF8F1);
  static const _accent = IntelliaColors.brandIndigo;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next(int count) {
    if (_index >= count - 1) {
      Navigator.of(context).pop();
      return;
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    _pages.animateToPage(
      _index + 1,
      duration: reduced
          ? const Duration(milliseconds: 1)
          : IntelliaMotion.medium,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = ParentGuide.steps(l10n);
    final last = _index == steps.length - 1;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Container(
      key: ParentGuide.sheetKey,
      height: height,
      decoration: const BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _ink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.parentGuideProgress(_index + 1, steps.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: _accent,
                  ),
                ),
              ),
              if (!last)
                TextButton(
                  key: ParentGuide.skipKey,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.parentGuideSkip),
                ),
            ],
          ),
          // Trait d'encre : il se dessine jusqu'à l'étape en cours.
          LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (_index + 1) / steps.length),
                duration: reduced ? Duration.zero : IntelliaMotion.medium,
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Container(
                  height: 4,
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: steps.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => _GuideStep(
                icon: steps[index].icon,
                title: steps[index].title,
                body: steps[index].body,
                active: index == _index,
                reduced: reduced,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ParentGuide.nextKey,
              onPressed: () => _next(steps.length),
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                last ? l10n.parentGuideDone : l10n.parentGuideNext,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.active,
    required this.reduced,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool active;
  final bool reduced;

  static const _ink = Color(0xFF25233E);
  static const _accent = IntelliaColors.brandIndigo;

  @override
  Widget build(BuildContext context) {
    // Le médaillon se pose d'un léger rebond quand l'étape arrive.
    final medallion = Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent,
            Color.lerp(_accent, IntelliaColors.brandPurple, 0.6)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 42),
    );
    return Semantics(
      container: true,
      liveRegion: active,
      // Écran fixe : sous un très grand texte, l'étape se réduit pour tenir.
      child: FitViewport(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reduced)
                medallion
              else
                TweenAnimationBuilder<double>(
                  key: ValueKey(active),
                  tween: Tween(begin: active ? 0.6 : 1, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: medallion,
                ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF4A4658),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
