import 'package:flutter/material.dart';

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
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AuthExperienceColors.indigo,
        brightness: Brightness.dark,
        primary: AuthExperienceColors.indigo,
        secondary: AuthExperienceColors.purple,
        error: AuthExperienceColors.error,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AuthExperienceColors.indigo,
            width: 1.5,
          ),
        ),
      ),
    );

    return Theme(
      data: darkTheme,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AuthExperienceColors.night,
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
                          tooltip: 'Retour',
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
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
