import 'package:flutter_test/flutter_test.dart';

import '../../tool/user_facing_jargon_audit.dart';

/// Langage 100 % humain : aucun jargon d'architecture à l'écran, pour aucun
/// public (élève, parent, personnel, visiteur).
void main() {
  test('detects technical jargon in displayed sentences', () {
    expect(findJargonInLine("Text('Erreur Firebase inattendue')"), [
      'Erreur Firebase inattendue',
    ]);
    expect(findJargonInLine("Text('Token expiré, relancez')"), [
      'Token expiré, relancez',
    ]);
    expect(findJargonInLine("Text('HTTP 500 : réessayez')"), [
      'HTTP 500 : réessayez',
    ]);
  });

  test('ignores human uses, logs, keys and interpolated values', () {
    expect(findJargonInLine("Text('Entre le code SMS reçu')"), isEmpty);
    expect(findJargonInLine("Text('J’ai un code élève')"), isEmpty);
    expect(findJargonInLine("debugPrint('Firebase init failed now')"), isEmpty);
    expect(findJargonInLine("collection('users').doc(uid)"), isEmpty);
    expect(findJargonInLine(r"Text('${payload.firstName} arrive')"), isEmpty);
    expect(findJargonInLine('// Firebase renvoie un jeton ici'), isEmpty);
  });

  test('no translation and no displayed string contains jargon', () {
    expect(scanUserFacingJargon(), isEmpty);
  });
}
