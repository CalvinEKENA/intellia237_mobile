import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import '../../../core/localization/localization_extensions.dart';
import '../domain/auth_input_validators.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);
    if (mounted && success) setState(() => _emailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final l10n = context.l10n;
    return AuthExperienceScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              eyebrow: l10n.forgotEyebrow,
              title: l10n.forgotTitle,
              subtitle: l10n.forgotSubtitle,
            ),
            const SizedBox(height: 28),
            AuthGlassPanel(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _emailSent
                    ? Column(
                        key: const ValueKey('sent'),
                        children: [
                          const Icon(
                            Icons.mark_email_read_rounded,
                            color: AuthExperienceColors.success,
                            size: 54,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l10n.emailSent,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.checkEmail(_emailController.text.trim()),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AuthExperienceColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          AuthPrimaryButton(
                            label: l10n.backToLogin,
                            onTap: context.pop,
                            icon: Icons.login_rounded,
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('form'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthAnimatedField(
                            controller: _emailController,
                            label: l10n.emailLabel,
                            hint: l10n.emailHint,
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) =>
                                AuthInputValidators.email(value ?? ''),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: 14),
                            AuthErrorBanner(
                              message: auth.error!,
                              onRetry: _submit,
                              onDismiss: controller.clearError,
                            ),
                          ],
                          const SizedBox(height: 18),
                          AuthPrimaryButton(
                            label: l10n.sendLink,
                            onTap: auth.isLoading ? null : _submit,
                            isLoading: auth.isLoading,
                            icon: Icons.send_rounded,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
