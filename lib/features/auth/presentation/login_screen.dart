import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../application/auth_controller.dart';
import '../domain/auth_input_validators.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return AuthExperienceScaffold(
      showBackButton: false,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              const AuthHeader(
                eyebrow: 'Votre espace personnel',
                title: 'Heureux de vous\nretrouver.',
                subtitle:
                    'Reprenez votre progression et retrouvez votre compagnon.',
              ),
              const SizedBox(height: 30),
              AuthGlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthAnimatedField(
                      controller: _emailController,
                      label: 'Adresse e-mail',
                      hint: 'prenom.nom@exemple.com',
                      icon: Icons.alternate_email_rounded,
                      enabled: !auth.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          AuthInputValidators.email(value ?? ''),
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),
                    AuthAnimatedField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: 'Mot de passe',
                      hint: 'Votre mot de passe',
                      icon: Icons.lock_outline_rounded,
                      enabled: !auth.isLoading,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) =>
                          AuthInputValidators.password(value ?? ''),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          foregroundColor: AuthExperienceColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: auth.error == null
                          ? const SizedBox.shrink()
                          : Padding(
                              key: ValueKey(auth.error),
                              padding: const EdgeInsets.only(bottom: 14),
                              child: AuthErrorBanner(
                                message: auth.error!,
                                onRetry: _submit,
                                onDismiss: controller.clearError,
                              ),
                            ),
                    ),
                    AuthPrimaryButton(
                      label: 'Se connecter',
                      onTap: auth.isLoading ? null : _submit,
                      isLoading: auth.isLoading,
                      icon: Icons.login_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Pas encore de compte ?',
                      style: TextStyle(
                        color: AuthExperienceColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => context.push(AppRoutes.register),
                    style: TextButton.styleFrom(
                      foregroundColor: AuthExperienceColors.gold,
                    ),
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
