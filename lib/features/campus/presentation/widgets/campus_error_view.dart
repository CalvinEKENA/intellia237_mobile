import 'package:flutter/material.dart';

import '../localization/campus_localizations.dart';
import '../theme/campus_theme_tokens.dart';

class CampusErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const CampusErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = CampusLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CampusTokens.campusSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CampusTokens.campusDivider),
            boxShadow: CampusTokens.subtleCardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 28,
                  color: CampusTokens.severityCritical,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CampusTokens.campusGraphite,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.retryLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CampusTokens.campusBlueAccent,
                  side: const BorderSide(color: CampusTokens.campusBlueAccent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
