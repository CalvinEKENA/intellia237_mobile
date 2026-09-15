import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../family_access/domain/family_access_models.dart';
import 'auth_controls.dart';
import 'auth_experience_scaffold.dart';

/// Montre, une seule fois, le code d'accès INTELLIA d'un élève à un adulte
/// responsable (copie « vous »).
///
/// Le serveur ne garde qu'une empreinte du code : une fois cet écran quitté,
/// le code ne peut plus être relu, seulement remplacé par un nouveau. Sans
/// [code] — il a été émis lors d'une tentative précédente —, l'écran le dit
/// au lieu de prétendre le retrouver.
class StudentAccessCodeReveal extends StatelessWidget {
  const StudentAccessCodeReveal({
    required this.studentFirstName,
    required this.code,
    required this.continueLabel,
    required this.onContinue,
    this.busy = false,
    super.key,
  });

  final String studentFirstName;
  final String? code;
  final String continueLabel;
  final VoidCallback onContinue;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = studentFirstName.trim();
    final code = this.code;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.key_rounded,
            color: AuthExperienceColors.indigo,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty
                ? l10n.studentAccessCodeRevealTitleGeneric
                : l10n.studentAccessCodeRevealTitle(name),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (code != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AuthExperienceColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AuthExperienceColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      StudentAccessCodeFormat.format(code),
                      key: const ValueKey('student-access-code-value'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'CampaignBody',
                        color: AuthExperienceColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('student-access-code-copy'),
                    tooltip: l10n.studentAccessCodeCopy,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: StudentAccessCodeFormat.format(code),
                        ),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text(l10n.studentAccessCodeCopied)),
                      );
                    },
                    icon: const Icon(
                      Icons.copy_rounded,
                      color: AuthExperienceColors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name.isEmpty
                  ? l10n.studentAccessCodeRevealBodyGeneric
                  : l10n.studentAccessCodeRevealBody(name),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AuthExperienceColors.textSecondary,
                height: 1.45,
              ),
            ),
          ] else
            Text(
              l10n.studentAccessCodeNotShownAgain,
              key: const ValueKey('student-access-code-not-shown'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AuthExperienceColors.textSecondary,
                height: 1.45,
              ),
            ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('student-access-code-continue'),
            label: continueLabel,
            icon: Icons.arrow_forward_rounded,
            isLoading: busy,
            onTap: busy ? null : onContinue,
          ),
        ],
      ),
    );
  }
}
