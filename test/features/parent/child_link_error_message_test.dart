import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/parent/presentation/widgets/add_child_button.dart';
import 'package:intellia237/l10n/generated/app_localizations_en.dart';
import 'package:intellia237/l10n/generated/app_localizations_fr.dart';

/// La liaison enfant mappe des **codes stables** vers des messages FR/EN dans le
/// client — jamais de message figé dans une seule langue.
void main() {
  final fr = AppLocalizationsFr();
  final en = AppLocalizationsEn();

  test('not-found is localized in both languages', () {
    expect(
      childLinkErrorMessage(fr, 'not-found'),
      'Ce code enfant est introuvable. Vérifie-le avec ton enfant.',
    );
    expect(
      childLinkErrorMessage(en, 'not-found'),
      'This child code was not found. Check it with your child.',
    );
  });

  test('rate-limit code maps to the friendly too-many message', () {
    expect(
      childLinkErrorMessage(fr, 'resource-exhausted'),
      'Trop de tentatives. Réessaie un peu plus tard.',
    );
    expect(
      childLinkErrorMessage(en, 'resource-exhausted'),
      'Too many attempts. Try again a little later.',
    );
  });

  test('unknown codes fall back to a generic localized message', () {
    expect(
      childLinkErrorMessage(fr, 'weird-server-code'),
      'La liaison n’a pas abouti. Réessaie dans un instant.',
    );
    expect(
      childLinkErrorMessage(en, 'weird-server-code'),
      'Linking failed. Try again in a moment.',
    );
  });
}
