import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../auth/domain/app_role.dart';

/// Carte de selection de role avec animations premium :
/// - Scale bounce a la selection
/// - Gradient colore selon le role
/// - Icone animee
/// - Bord lumineux
class AccountTypeCard extends StatefulWidget {
  const AccountTypeCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final AppRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<AccountTypeCard> createState() => _AccountTypeCardState();
}

class _AccountTypeCardState extends State<AccountTypeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.04), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AccountTypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = widget.isSelected;
    final color = widget.color;

    final borderColor =
        selected ? color : theme.colorScheme.outline.withValues(alpha: 0.20);
    final bgColor = selected
        ? color.withValues(alpha: isDark ? 0.14 : 0.06)
        : theme.colorScheme.surfaceContainerLow;

    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) => Transform.scale(
        scale: _bounceScale.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: borderColor,
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icone dans cercle gradient
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.emphasizedDecelerate,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: selected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.22),
                            color.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                  color: selected ? null : color.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: selected ? 1.15 : 1.0,
                    duration: AppMotion.medium,
                    curve: AppMotion.emphasizedDecelerate,
                    child: Icon(widget.icon, color: color, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? color : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),

              // Indicateur de selection
              AnimatedSwitcher(
                duration: AppMotion.fast,
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: selected
                    ? Container(
                        key: const ValueKey('check'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        key: const ValueKey('chevron'),
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
