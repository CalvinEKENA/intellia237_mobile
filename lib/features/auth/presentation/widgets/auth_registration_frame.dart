import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import 'auth_choices.dart';
import 'auth_controls.dart';
import 'auth_experience_scaffold.dart';

class AuthRegistrationFrame extends StatelessWidget {
  const AuthRegistrationFrame({
    required this.title,
    required this.currentStep,
    required this.labels,
    required this.content,
    required this.actions,
    required this.onBack,
    this.pass,
    this.errorMessage,
    this.onRetry,
    this.onDismissError,
    super.key,
  });

  final String title;
  final int currentStep;
  final List<String> labels;
  final Widget content;
  final Widget actions;
  final VoidCallback onBack;
  final Widget? pass;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AuthExperienceColors.indigo,
        brightness: Brightness.light,
        primary: AuthExperienceColors.indigo,
        secondary: AuthExperienceColors.purple,
        error: AuthExperienceColors.error,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AuthExperienceColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.small),
          borderSide: const BorderSide(color: AuthExperienceColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.small),
          borderSide: const BorderSide(color: AuthExperienceColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.small),
          borderSide: const BorderSide(
            color: AuthExperienceColors.indigo,
            width: 1.5,
          ),
        ),
      ),
    );

    if (pass != null) {
      // The PASS, form and actions share one scroll position. A keyboard or
      // large type therefore never steals the form's remaining fixed height.
      return Theme(
        data: lightTheme.copyWith(
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: AuthExperienceColors.textPrimary,
            displayColor: AuthExperienceColors.textPrimary,
          ),
        ),
        child: Semantics(
          label: title,
          container: true,
          child: AuthExperienceScaffold(
            onBack: onBack,
            pass: pass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthStepIndicator(currentStep: currentStep, labels: labels),
                const SizedBox(height: 22),
                content,
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(
                    message: errorMessage!,
                    onRetry: onRetry,
                    onDismiss: onDismissError,
                  ),
                ],
                const SizedBox(height: 20),
                actions,
              ],
            ),
          ),
        ),
      );
    }

    return Theme(
      data: lightTheme,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AuthExperienceColors.canvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AuthAmbientBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 20, 14),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: context.l10n.backLabel,
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AuthExperienceColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AuthStepIndicator(
                      currentStep: currentStep,
                      labels: labels,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: content),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: AuthErrorBanner(
                        message: errorMessage!,
                        onRetry: onRetry,
                        onDismiss: onDismissError,
                      ),
                    ),
                  actions,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
