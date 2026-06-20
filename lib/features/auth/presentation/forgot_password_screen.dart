import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../../../core/widgets/intellia_brand_mark.dart';
import '../../../core/widgets/intellia_card.dart';
import '../../../core/widgets/intellia_text_field.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../application/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailCtrl.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _emailSent = success;
    });

    if (!success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: Text(
                    'Impossible d\'envoyer l\'email. Vérifiez l\'adresse.',
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(IntelliaRadii.small),
            ),
            margin: const EdgeInsets.all(IntelliaSpacing.md),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntelliaScaffold(
      usePremiumBackground: true,
      showTopHalo: true,
      appBar: AppBar(
        leading: IntelliaIconButton(
          icon: Icons.arrow_back_rounded,
          backgroundColor: Colors.transparent,
          onTap: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.lg,
            vertical: IntelliaSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IntelliaBrandMark(size: 80, showText: true, textSize: 24),
              const SizedBox(height: IntelliaSpacing.lg),

              AnimatedSwitcher(
                duration: IntelliaMotion.medium,
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: _emailSent
                    ? IntelliaCard(
                        key: const ValueKey('success'),
                        variant: IntelliaCardVariant.elevated,
                        padding: const EdgeInsets.all(IntelliaSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: IntelliaColors.success,
                              size: 64,
                            ),
                            const SizedBox(height: IntelliaSpacing.md),
                            Text(
                              'Email envoyé !',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: IntelliaSpacing.sm),
                            Text(
                              'Un lien de réinitialisation de mot de passe a été envoyé à :\n${_emailCtrl.text}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? IntelliaColors.textSecondaryDark
                                    : IntelliaColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: IntelliaSpacing.lg),
                            IntelliaPrimaryButton(
                              onTap: () => context.pop(),
                              child: const Text('Retour à la connexion'),
                            ),
                          ],
                        ),
                      )
                    : IntelliaCard(
                        key: const ValueKey('form'),
                        variant: IntelliaCardVariant.elevated,
                        padding: const EdgeInsets.all(IntelliaSpacing.lg),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Récupérer le mot de passe',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: IntelliaSpacing.xxs),
                              Text(
                                'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
                                style: TextStyle(
                                  color: isDark
                                      ? IntelliaColors.textSecondaryDark
                                      : IntelliaColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: IntelliaSpacing.xl),

                              IntelliaTextField(
                                controller: _emailCtrl,
                                label: 'Adresse email',
                                hint: 'exemple@intellia237.cm',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'L\'email est requis';
                                  }
                                  if (!RegExp(
                                    r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$',
                                  ).hasMatch(v.trim())) {
                                    return 'Entrez un email valide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: IntelliaSpacing.xl),

                              IntelliaPrimaryButton(
                                onTap: _isLoading ? null : _submit,
                                isLoading: _isLoading,
                                child: const Text('Envoyer le lien'),
                              ),
                            ],
                          ),
                        ),
                      ),
              ).animate().fadeIn(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
