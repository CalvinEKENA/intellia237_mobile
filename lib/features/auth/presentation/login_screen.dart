import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../../../core/widgets/intellia_brand_mark.dart';
import '../../../core/widgets/intellia_card.dart';
import '../../../core/widgets/intellia_text_field.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import '../domain/auth_input_validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: _emailCtrl.text, password: _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Error listener
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: IntelliaSpacing.sm),
                  Expanded(child: Text(next.error!)),
                ],
              ),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(IntelliaRadii.small),
              ),
              margin: const EdgeInsets.all(IntelliaSpacing.md),
            ),
          );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return IntelliaScaffold(
      usePremiumBackground: true,
      showTopHalo: true,
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

              IntelliaCard(
                variant: IntelliaCardVariant.elevated,
                padding: const EdgeInsets.all(IntelliaSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bon retour !',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: IntelliaSpacing.xxs),
                      Text(
                        'Connectez-vous pour continuer votre apprentissage',
                        style: TextStyle(
                          color: isDark
                              ? IntelliaColors.textSecondaryDark
                              : IntelliaColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: IntelliaSpacing.xl),

                      // Email input
                      IntelliaTextField(
                        controller: _emailCtrl,
                        label: 'Adresse email',
                        hint: 'exemple@intellia237.cm',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        validator: (v) => AuthInputValidators.email(v ?? ''),
                      ),
                      const SizedBox(height: IntelliaSpacing.md),

                      // Password input
                      IntelliaPasswordField(
                        controller: _passwordCtrl,
                        label: 'Mot de passe',
                        hint: 'Saisissez votre mot de passe',
                        enabled: !isLoading,
                        validator: (v) => AuthInputValidators.password(v ?? ''),
                      ),

                      // Forgot password button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push(AppRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: IntelliaSpacing.md),

                      // Sign in button
                      IntelliaPrimaryButton(
                        onTap: isLoading ? null : _submit,
                        isLoading: isLoading,
                        child: const Text('Se connecter'),
                      ),
                      const SizedBox(height: IntelliaSpacing.lg),

                      // Separator
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.outline,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: IntelliaSpacing.md,
                            ),
                            child: Text(
                              'Nouveau sur INTELLIA237 ?',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? IntelliaColors.textSecondaryDark
                                    : IntelliaColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.outline,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: IntelliaSpacing.lg),

                      // Register button
                      IntelliaOutlineButton(
                        onTap: isLoading
                            ? null
                            : () => context.push(AppRoutes.register),
                        child: const Text('Créer un compte'),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
