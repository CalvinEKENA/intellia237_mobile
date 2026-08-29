import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';

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
          child: const Text('Lire les conditions'),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.legalPrivacy),
          child: const Text('Lire la confidentialité'),
        ),
        if (showEducationalData)
          TextButton(
            onPressed: () => context.push(AppRoutes.legalEducationalData),
            child: const Text('Comprendre les données pédagogiques'),
          ),
      ],
    );
  }
}
