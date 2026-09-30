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

/// Erreur de liaison portant un **code machine stable**. Le message affiché à
/// l'utilisateur est résolu côté client selon la langue (FR/EN) — jamais figé
/// en une seule langue dans le service ni renvoyé par le serveur.
class ChildLinkException implements Exception {
  const ChildLinkException(this.code, [this.debugMessage]);

  /// Code stable : `not-found`, `invalid-argument`, `permission-denied`,
  /// `unauthenticated`, `resource-exhausted`, ou autre (générique).
  final String code;

  /// Détail non localisé, pour les logs uniquement — jamais affiché tel quel.
  final String? debugMessage;

  @override
  String toString() => 'ChildLinkException($code)';
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
      // On propage le CODE stable ; la traduction se fait dans l'UI.
      throw ChildLinkException(error.code, error.message);
    }
  }
}

final childLinkServiceProvider = Provider<ChildLinkService>(
  (ref) => ChildLinkService(),
);
