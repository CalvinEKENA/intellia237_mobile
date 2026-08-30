import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

extension IntelliaLocalizationContext on BuildContext {
  /// Uses the generated catalogue while remaining safe in small widget tests
  /// that intentionally omit localization delegates.
  AppLocalizations get l10n {
    final localized = Localizations.of<AppLocalizations>(
      this,
      AppLocalizations,
    );
    return localized ?? lookupAppLocalizations(const Locale('fr'));
  }
}
