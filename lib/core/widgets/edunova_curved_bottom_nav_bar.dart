import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Item de navigation pour la barre courbe EduNova.
class EduNovaCurvedNavItem {
  const EduNovaCurvedNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
}

/// Barre de navigation premium avec courbe fluide, glow animé,
/// bulle flottante sur l'item actif et retour haptique.
class EduNovaCurvedBottomNavBar extends StatefulWidget {
  const EduNovaCurvedBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.height = 72,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 10),
    this.showLabels = true,
  }) : assert(
          items.length >= 2,
          'Au moins 2 items de navigation sont requis.',
        );

  final List<EduNovaCurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final EdgeInsets margin;
  final bool showLabels;

  @override
  State<EduNovaCurvedBottomNavBar> createState() =>
      _EduNovaCurvedBottomNavBarState();
}

class _EduNovaCurvedBottomNavBarState extends State<EduNovaCurvedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: widget.margin,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: widget.currentIndex.toDouble()),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          builder: (context, animatedIndex, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final itemWidth = barWidth / widget.items.length;
                final centerX = itemWidth * (animatedIndex + 0.5);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Barre principale avec fond glassmorphism
                    ClipPath(
                      clipper: _SmoothCurveClipper(centerX: centerX),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          height: widget.height,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF101828).withValues(alpha: 0.88)
                                : scheme.surface.withValues(alpha: 0.92),
                            border: Border(
                              top: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.7),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Glow animé sous l'item actif
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, _) {
                        final glowIntensity =
                            0.15 + 0.12 * _glowController.value;
                        return Positioned(
                          left: centerX - 32,
                          top: -4,
                          child: IgnorePointer(
                            child: Container(
                              width: 64,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withValues(
                                      alpha: glowIntensity.clamp(0.0, 1.0),
                                    ),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Items de navigation
                    SizedBox(
                      height: widget.height,
                      child: Row(
                        children: [
                          for (int i = 0; i < widget.items.length; i++)
                            Expanded(
                              child: _AnimatedNavItem(
                                item: widget.items[i],
                                isSelected: widget.currentIndex == i,
                                animProgress: (1 - (animatedIndex - i).abs())
                                    .clamp(0.0, 1.0),
                                showLabel: widget.showLabels,
                                primaryColor: scheme.primary,
                                onSurfaceColor: scheme.onSurface,
                                onTap: () {
                                  if (widget.currentIndex != i) {
                                    HapticFeedback.selectionClick();
                                  }
                                  widget.onTap(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Indicateur pill actif (point lumineux sous l'icone)
                    Positioned(
                      bottom: widget.showLabels ? 6 : 10,
                      left: centerX - 16,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: scheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Item de navigation avec micro-animations (scale bounce, color fade).
class _AnimatedNavItem extends StatefulWidget {
  const _AnimatedNavItem({
    required this.item,
    required this.isSelected,
    required this.animProgress,
    required this.showLabel,
    required this.primaryColor,
    required this.onSurfaceColor,
    required this.onTap,
  });

  final EduNovaCurvedNavItem item;
  final bool isSelected;
  final double animProgress;
  final bool showLabel;
  final Color primaryColor;
  final Color onSurfaceColor;
  final VoidCallback onTap;

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(_AnimatedNavItem old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.animProgress;
    final iconColor = Color.lerp(
      widget.onSurfaceColor.withValues(alpha: 0.48),
      widget.primaryColor,
      t,
    )!;
    final labelColor = Color.lerp(
      widget.onSurfaceColor.withValues(alpha: 0.48),
      widget.primaryColor,
      t,
    )!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, _) {
          // Bounce : scale up → overshoot → settle
          final bounceVal = _bounceController.value;
          final scale = bounceVal < 0.5
              ? 1.0 + 0.18 * Curves.easeOut.transform(bounceVal * 2)
              : 1.0 +
                  0.18 *
                      Curves.easeIn.transform(2 - bounceVal * 2);

          // Léger translate Y vers le haut quand actif
          final yShift = widget.isSelected ? -2.0 * t : 0.0;

          return Transform.translate(
            offset: Offset(0, yShift),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: widget.isSelected ? scale : 1.0,
                  child: Icon(
                    widget.isSelected
                        ? (widget.item.activeIcon ?? widget.item.icon)
                        : widget.item.icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      fontSize: widget.isSelected ? 10.5 : 10,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: labelColor,
                      letterSpacing: widget.isSelected ? 0.1 : 0,
                    ),
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Clipper avec courbe organique fluide (smooth notch).
class _SmoothCurveClipper extends CustomClipper<Path> {
  _SmoothCurveClipper({required this.centerX});

  final double centerX;

  @override
  Path getClip(Size size) {
    // Courbe plus douce et organique qu'un simple cubic
    const notchDepth = 14.0;
    const notchWidth = 72.0;
    const cornerRadius = 22.0;

    final halfNotch = notchWidth / 2;
    final safeCX = centerX.clamp(halfNotch, size.width - halfNotch);

    final path = Path();

    // Coin haut-gauche arrondi
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Ligne vers le début de la courbe
    path.lineTo(safeCX - halfNotch, 0);

    // Courbe smooth (3 segments pour un rendu organique)
    path.cubicTo(
      safeCX - halfNotch * 0.55,
      0,
      safeCX - halfNotch * 0.35,
      -notchDepth,
      safeCX,
      -notchDepth,
    );
    path.cubicTo(
      safeCX + halfNotch * 0.35,
      -notchDepth,
      safeCX + halfNotch * 0.55,
      0,
      safeCX + halfNotch,
      0,
    );

    // Ligne vers le coin droit
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Descente droite
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // Bas
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SmoothCurveClipper old) =>
      old.centerX != centerX;
}
