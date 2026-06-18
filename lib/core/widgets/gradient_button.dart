import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/design_tokens.dart';

/// Bouton avec fond dégradé, ombre colorée et état de chargement.
/// Remplace [FilledButton] sur les écrans sombres (auth, inscription, quiz résultat).
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.onPressed,
    required this.child,
    this.gradient = AppGradients.heroNavy,
    this.height = 52.0,
    this.borderRadius = 14.0,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final LinearGradient gradient;
  final double height;
  final double borderRadius;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isLoading || isDisabled)
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  },
            child: Ink(
              decoration: BoxDecoration(
                gradient: isDisabled ? null : gradient,
                color: isDisabled
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: isDisabled
                    ? null
                    : AppShadows.glow(gradient.colors.first, intensity: 0.25),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
