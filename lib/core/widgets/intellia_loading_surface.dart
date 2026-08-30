import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';
import '../assets/intellia_assets.dart';
import '../localization/localization_extensions.dart';

class IntelliaLoadingSurface extends StatefulWidget {
  const IntelliaLoadingSurface({super.key});

  @override
  State<IntelliaLoadingSurface> createState() => _IntelliaLoadingSurfaceState();
}

class _IntelliaLoadingSurfaceState extends State<IntelliaLoadingSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final identity = Image.asset(
      IntelliaBrandAssets.identityMaster,
      key: const Key('intellia-loading-identity'),
      width: 112,
      height: 112,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.school_rounded,
        size: 54,
        color: IntelliaColors.brandIndigo,
      ),
    );

    return ColoredBox(
      key: const Key('intellia-loading-surface'),
      color: IntelliaColors.backgroundPrimary,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reduceMotion)
                identity
              else
                AnimatedBuilder(
                  animation: _controller,
                  child: identity,
                  builder: (context, child) {
                    final value = Curves.easeInOut.transform(_controller.value);
                    return Transform.translate(
                      offset: Offset(0, -2 * value),
                      child: Opacity(
                        opacity: 0.88 + 0.12 * value,
                        child: child,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              Text(
                context.l10n.preparingYourSpace,
                key: const Key('intellia-loading-message'),
                style: const TextStyle(
                  color: IntelliaColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
