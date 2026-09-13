import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Résultat d'une liaison enfant réussie (retour du callable serveur).
class ChildLinkResult {
  const ChildLinkResult({
    required this.studentId,
    required this.firstName,
    required this.classLevel,
    required this.alreadyLinked,
  });

  final String studentId;
  final String firstName;
  final String classLevel;

  /// Vrai si le lien approuvé existait déjà (opération idempotente).
  final bool alreadyLinked;
}

/// Erreur de liaison portant un code stable et un message prêt à afficher.
class ChildLinkException implements Exception {
  const ChildLinkException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ChildLinkException($code): $message';
}

/// Appelle les callables de liaison parent↔enfant, autoritaires côté serveur.
/// Aucune écriture directe de `children_links` côté client (les règles
/// n'autorisent qu'un lien *pending*, jamais *approved*).
class ChildLinkService {
  ChildLinkService({FirebaseFunctions? functions}) : _override = functions;

  final FirebaseFunctions? _override;

  // Résolu paresseusement : construire FirebaseFunctions exige un app Firebase
  // initialisé, absent des tests widget. Un faux qui redéfinit les méthodes n'y
  // touche jamais.
  FirebaseFunctions get _functions =>
      _override ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<ChildLinkResult> linkChildByCode(String code) async {
    try {
      final response = await _functions
          .httpsCallable('linkChildByCode')
          .call<dynamic>({'code': code});
      final data = Map<String, dynamic>.from(response.data as Map);
      return ChildLinkResult(
        studentId: (data['studentId'] as String?)?.trim() ?? '',
        firstName: (data['firstName'] as String?)?.trim() ?? '',
        classLevel: (data['classLevel'] as String?)?.trim() ?? '',
        alreadyLinked: data['alreadyLinked'] == true,
      );
    } on FirebaseFunctionsException catch (error) {
      throw ChildLinkException(error.code, _messageFor(error.code));
    }
  }

  String _messageFor(String code) => switch (code) {
    'not-found' =>
      'Ce code enfant est introuvable. Vérifie-le avec ton enfant.',
    'invalid-argument' => 'Saisis le code de liaison de ton enfant.',
    'permission-denied' => 'Seul un compte parent peut rattacher un enfant.',
    'unauthenticated' => 'Ta session a expiré. Reconnecte-toi puis réessaie.',
    _ => 'La liaison n’a pas abouti. Réessaie dans un instant.',
  };
}

final childLinkServiceProvider = Provider<ChildLinkService>(
  (ref) => ChildLinkService(),
);
