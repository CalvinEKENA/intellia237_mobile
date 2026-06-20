import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../../../core/widgets/intellia_brand_mark.dart';
import '../../auth/application/auth_controller.dart';

class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Precache Kira & Leo companion assets for smooth onboarding transition
      await Future.wait([
        precacheImage(const AssetImage('assets/companions/kira.png'), context),
        precacheImage(const AssetImage('assets/companions/leo.png'), context),
      ]);
      if (mounted) {
        await ref.read(authControllerProvider.notifier).completeBootstrap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntelliaScaffold(
      usePremiumBackground: true,
      showTopHalo: true,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1.0),
          duration: IntelliaMotion.slow,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: ((value - 0.94) / 0.06).clamp(0.0, 1.0),
            child: Transform.scale(scale: value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IntelliaBrandMark(size: 96, textSize: 22, showText: true),
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                'Préparer sa rentrée avec méthode et confiance',
                style: IntelliaTypography.caption(brightness: theme.brightness),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: IntelliaSpacing.xxxl),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
