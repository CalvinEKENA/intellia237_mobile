import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/auth_controller.dart';
import '../domain/auth_input_validators.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/living_pass.dart';
import 'widgets/pass_auth_progress.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final _passInputs = Listenable.merge([
    _emailController,
    _passwordController,
  ]);
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(authControllerProvider).isLoading) return;
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
    final l10n = context.l10n;

    return AuthExperienceScaffold(
      showBackButton: false,
      pass: ListenableBuilder(
        listenable: _passInputs,
        builder: (context, _) => LivingPass(
          detail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          phase: context.l10n.passSignIn,
          // L'adresse colore « 2 », le mot de passe « 3 » ; l'espace d'arrivée
          // présente le sceau vérifié.
          progress: PassAuthProgress.emailSignIn(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        ),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                showBrand: false,
                eyebrow: context.l10n.passEmailAccess,
                title: context.l10n.passYourNextChapterAwaits,
                subtitle: context.l10n.passReturnToYourSpaceWithYour,
              ),
              const SizedBox(height: 24),
              AuthGlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthAnimatedField(
                      key: const ValueKey('login-email-field'),
                      controller: _emailController,
                      label: l10n.emailLabel,
                      hint: l10n.emailHint,
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
                      key: const ValueKey('login-password-field'),
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: l10n.passwordLabel,
                      hint: l10n.passwordHint,
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
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
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
                      key: const ValueKey('login-submit'),
                      label: l10n.signIn,
                      onTap: auth.isLoading ? null : _submit,
                      isLoading: auth.isLoading,
                      icon: Icons.login_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.noAccount,
                    style: const TextStyle(
                      color: AuthExperienceColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => context.push(AppRoutes.register),
                    style: TextButton.styleFrom(
                      foregroundColor: AuthExperienceColors.gold,
                    ),
                    child: Text(
                      l10n.createAccountLink,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                key: const ValueKey('login-change-profile'),
                onPressed: auth.isLoading
                    ? null
                    : () => context.go(AppRoutes.authGateway),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(context.l10n.passChooseAnotherWayIn),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
