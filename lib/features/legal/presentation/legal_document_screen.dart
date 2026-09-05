import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';

enum LegalDocumentType { terms, privacy, educationalData }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({required this.type, super.key});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final document = _LegalDocument.forType(type, context);
    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPrimary,
      appBar: AppBar(title: Text(document.title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          children: [
            Text(
              document.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              context.l10n.legalVersion,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            for (final section in document.sections) ...[
              Text(
                section.$1,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                section.$2,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
              const SizedBox(height: IntelliaSpacing.lg),
            ],
            Container(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              decoration: BoxDecoration(
                color: IntelliaColors.brandIndigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(IntelliaRadii.large),
              ),
              child: Text(context.l10n.legalContactNotice),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocument {
  const _LegalDocument({required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;

  static _LegalDocument forType(
    LegalDocumentType type,
    BuildContext context,
  ) => switch (type) {
    LegalDocumentType.terms => _LegalDocument(
      title: context.l10n.legalTermsTitle,
      sections: [
        (
          context.l10n.legalServicePurposeTitle,
          context.l10n.legalServicePurposeBody,
        ),
        (
          context.l10n.legalAccountSecurityTitle,
          context.l10n.legalAccountSecurityBody,
        ),
        (
          context.l10n.legalResponsibleUseTitle,
          context.l10n.legalResponsibleUseBody,
        ),
        (context.l10n.availabilityLabel, context.l10n.legalAvailabilityBody),
      ],
    ),
    LegalDocumentType.privacy => _LegalDocument(
      title: context.l10n.legalPrivacyTitle,
      sections: [
        (
          context.l10n.legalCollectedDataTitle,
          context.l10n.legalCollectedDataBody,
        ),
        (
          context.l10n.legalMinorsPrivacyTitle,
          context.l10n.legalMinorsPrivacyBody,
        ),
        (
          context.l10n.legalRetentionAccessTitle,
          context.l10n.legalRetentionAccessBody,
        ),
        (context.l10n.legalYourRightsTitle, context.l10n.legalYourRightsBody),
      ],
    ),
    LegalDocumentType.educationalData => _LegalDocument(
      title: context.l10n.legalEducationalDataTitle,
      sections: [
        (context.l10n.legalPurposeTitle, context.l10n.legalPurposeBody),
        (context.l10n.legalDecisionsTitle, context.l10n.legalDecisionsBody),
        (context.l10n.legalCompanionTitle, context.l10n.legalCompanionBody),
      ],
    ),
  };
}
