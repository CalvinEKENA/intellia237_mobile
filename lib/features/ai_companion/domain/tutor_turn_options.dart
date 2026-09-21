import 'dart:convert';
import 'dart:math';

/// Paramètres d'un tour de conversation avec le compagnon, hors message.
///
/// [requestId] identifie la question logique : il est généré une fois puis
/// réutilisé tel quel si l'élève relance après une coupure ou un délai
/// dépassé, pour que le serveur renvoie la réponse déjà produite au lieu de
/// consommer une seconde question.
class TutorTurnOptions {
  const TutorTurnOptions({this.requestId});

  final String? requestId;
}

/// Identifiant d'idempotence : 16 octets aléatoires sûrs, en base64 URL.
///
/// Respecte le format accepté par le serveur (`[A-Za-z0-9_-]{8,80}`).
String newTutorRequestId([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
