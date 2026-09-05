import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';

class LegalLinks extends StatelessWidget {
  const LegalLinks({this.showEducationalData = false, super.key});

  final bool showEducationalData;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: [
        TextButton(
          onPressed: () => context.push(AppRoutes.legalTerms),
          child: Text(context.l10n.readTerms),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.legalPrivacy),
          child: Text(context.l10n.readPrivacy),
        ),
        if (showEducationalData)
          TextButton(
            onPressed: () => context.push(AppRoutes.legalEducationalData),
            child: Text(context.l10n.readEducationalData),
          ),
      ],
    );
  }
}
