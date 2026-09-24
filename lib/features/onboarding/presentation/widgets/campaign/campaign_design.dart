import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/widgets/fit_viewport.dart';

abstract final class CampaignColors {
  static const paper = Color(0xFFF4EFE5);
  static const ink = Color(0xFF25233E);
  static const violet = Color(0xFF5444D8);
  static const lilac = Color(0xFFCEC7FA);
  static const brass = Color(0xFFBD955C);
  static const blue = Color(0xFF254EDB);
  static const muted = Color(0xFF716C79);
}

String campaignText(BuildContext context, String fr, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : fr;

TextStyle campaignBody({
  double size = 14,
  Color color = CampaignColors.ink,
  FontWeight weight = FontWeight.w600,
}) => TextStyle(
  fontFamily: 'CampaignBody',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.45,
);

TextStyle campaignDisplay({
  double size = 80,
  Color color = CampaignColors.ink,
}) => TextStyle(
  fontFamily: 'BarlowCondensed',
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: color,
  height: 0.94,
  letterSpacing: -0.6,
);

/// Titles reveal through a fixed mask; the text remains whole for screen readers.
class CampaignHeadline extends StatelessWidget {
  const CampaignHeadline({
    required this.lines,
    required this.animation,
    this.color = CampaignColors.ink,
    this.background = CampaignColors.paper,
    this.accentLine = -1,
    this.accent = CampaignColors.violet,
    this.size = 100,
    super.key,
  });

  final List<String> lines;
  final Animation<double> animation;
  final Color color;
  final Color background;
  final int accentLine;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: lines.join(' '),
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < lines.length; index++)
          ClipRect(
            child: AnimatedBuilder(
              animation: animation,
              child: SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  // Écran court : le titre cède sa hauteur au contenu (le
                  // reste de la scène garde sa taille réelle).
                  constraints: BoxConstraints(
                    maxHeight: CampaignRoom.headlineLineOf(context),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      lines[index],
                      maxLines: 1,
                      style: campaignDisplay(
                        size: size,
                        color: index == accentLine ? accent : color,
                      ).copyWith(backgroundColor: background),
                    ),
                  ),
                ),
              ),
              builder: (_, child) {
                final t = Curves.easeOutCubic.transform(
                  ((animation.value - index * 0.09) / 0.70).clamp(0.0, 1.0),
                );
                return FractionalTranslation(
                  translation: Offset(0, 1.12 * (1 - t)),
                  child: child,
                );
              },
            ),
          ),
      ],
    ),
  );
}

class CampaignButton extends StatefulWidget {
  const CampaignButton({
    required this.label,
    required this.onTap,
    this.color = CampaignColors.ink,
    this.foreground = CampaignColors.paper,
    this.icon = Icons.north_east_rounded,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color foreground;
  final IconData icon;

  @override
  State<CampaignButton> createState() => _CampaignButtonState();
}

class _CampaignButtonState extends State<CampaignButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _pressed && !reduced ? 0.975 : 1,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 140),
      child: FilledButton(
        onPressed: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return widget.color.withValues(alpha: 0.35);
            }
            return widget.color;
          }),
          foregroundColor: WidgetStatePropertyAll(widget.foreground),
          minimumSize: const WidgetStatePropertyAll(Size(0, 58)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStatePropertyAll(
            campaignBody(weight: FontWeight.w800),
          ),
        ),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: Row(
            children: [
              Expanded(child: Text(widget.label)),
              const SizedBox(width: 12),
              Icon(widget.icon, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hauteur de la scène en cours, pour que les grands titres cèdent leur
/// place sur un écran court au lieu de réduire toute la scène.
class CampaignRoom extends InheritedWidget {
  const CampaignRoom({required this.height, required super.child, super.key});

  final double height;

  /// Hauteur de la scène, ou `null` hors d'une [CampaignPage].
  static double? heightOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CampaignRoom>()?.height;

  /// Écran court : les ornements laissent la place à l'essentiel.
  static bool isShort(BuildContext context) =>
      (heightOf(context) ?? double.infinity) < 660;

  /// Hauteur maximale d'une ligne de grand titre.
  static double headlineLineOf(BuildContext context) {
    final height = heightOf(context);
    if (height == null || !height.isFinite) return double.infinity;
    return math.max(40.0, height * 0.095);
  }

  @override
  bool updateShouldNotify(CampaignRoom oldWidget) => height != oldWidget.height;
}

/// Scène fixe : jamais de défilement, bouton toujours visible.
///
/// Registre (QA appareil, 24/09/2026) : réduire toute la scène rendait le
/// texte minuscule et flou. Sur un écran court, ce sont désormais les grands
/// titres qui cèdent leur hauteur ([CampaignRoom]) ; le reste garde sa
/// taille réelle. La réduction d'ensemble ne subsiste qu'en dernier recours
/// (très petit écran avec très grand texte).
class CampaignPage extends StatelessWidget {
  const CampaignPage({required this.builder, super.key});
  final Widget Function(BuildContext context, double height, double width)
  builder;

  /// Hauteur de composition sous laquelle les scènes se chevaucheraient.
  static const compositionFloor = 520.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final minHeight = math.max(
        constraints.maxHeight,
        scale > 1.25 ? 660.0 + (scale - 1.25) * 190 : compositionFloor,
      );
      return CampaignRoom(
        height: constraints.maxHeight,
        child: FitViewport(
          key: const ValueKey('onboarding-scene-fixed'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            // Sous la [CampaignRoom], pour que la scène la voie.
            child: Builder(
              builder: (context) =>
                  builder(context, minHeight, constraints.maxWidth),
            ),
          ),
        ),
      );
    },
  );
}

/// « INTELLIA 237 » : le pays porte le drapeau, sur le papier comme sur l'encre.
///
/// Le nom reste dans l'encre de la surface ; seuls les trois chiffres changent
/// de couleur. Le lecteur d'écran, lui, n'entend qu'un seul mot.
class CampaignWordmark extends StatelessWidget {
  const CampaignWordmark({required this.dark, this.size = 11, super.key});

  final bool dark;
  final double size;

  static const _country = '237';

  @override
  Widget build(BuildContext context) {
    final digits = IntelliaFlag.digits(onInk: dark);
    return Semantics(
      label: 'INTELLIA $_country',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'INTELLIA '),
            for (var index = 0; index < _country.length; index++)
              TextSpan(
                text: _country[index],
                style: TextStyle(color: digits[index]),
              ),
          ],
        ),
        style: campaignBody(
          size: size,
          color: dark ? CampaignColors.paper : CampaignColors.ink,
          weight: FontWeight.w800,
        ).copyWith(letterSpacing: 1.4),
      ),
    );
  }
}

class CampaignEyebrow extends StatelessWidget {
  const CampaignEyebrow(this.text, {this.dark = false, super.key});
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Row(
      children: [
        Container(
          width: 20,
          height: 3,
          color: dark ? CampaignColors.lilac : CampaignColors.violet,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: campaignBody(
              size: 10,
              color: dark ? CampaignColors.lilac : CampaignColors.muted,
              weight: FontWeight.w800,
            ).copyWith(letterSpacing: 1.7),
          ),
        ),
      ],
    ),
  );
}
