import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/flow/application/flow_controller.dart';
import '../../features/student_home/application/student_home_controller.dart';

/// Providers conservant des données propres à un élève et qui **ne se
/// reconstruisent pas d'eux-mêmes** quand l'élève authentifié change.
///
/// ## Quand faut-il inscrire un provider ici ?
///
/// Un provider appartient à cette liste si les deux conditions sont réunies :
///
/// 1. il retient des données rattachées à un élève (progression, contenu
///    personnel, résumé, recommandations, brouillon…) ;
/// 2. il n'observe pas `authControllerProvider`, directement ou
///    transitivement, donc rien ne le reconstruit au changement d'identité.
///
/// Un provider qui observe l'identité se reconstruit tout seul : il ne doit
/// **pas** figurer ici, sinon la liste devient un inventaire de tout le
/// produit et cesse d'être auditable.
///
/// ## Ce qui ne doit jamais y figurer
///
/// Les préférences d'appareil, qui ne changent pas de propriétaire avec la
/// session : langue, thème, échelle de texte, réduction d'animation, écran
/// d'accueil déjà vu, consentement diagnostic, configuration réseau.
final learnerScopedProviders = <ProviderOrFamily>[
  // Rattaché à l'élève depuis la v3 du stockage FLOW, donc déjà auto-isolant.
  // Conservé ici en défense en profondeur : si l'observation de l'identité
  // disparaissait un jour du contrôleur, la frontière de session continuerait
  // de protéger le changement de compte.
  flowControllerProvider,

  // N'observe que `studentFirstNameProvider`, qui se replie sur « Champion ».
  // Deux élèves portant le même prénom — ou deux sessions sans prénom résolu —
  // produisent la même valeur, donc aucune reconstruction. L'instantané
  // d'accueil est pourtant lu par identifiant côté dépôt.
  studentHomeControllerProvider,
];

/// Réinitialise l'état mémoire propre à un élève.
///
/// Appelé à chaque changement d'identité authentifiée, et non seulement quand
/// l'utilisateur touche le bouton de déconnexion : la frontière canonique est
/// le changement d'élève, pas un geste d'interface particulier.
void _resetLearnerSession(void Function(ProviderOrFamily) invalidate) {
  for (final provider in learnerScopedProviders) {
    invalidate(provider);
  }
}

extension LearnerSessionRef on Ref {
  void resetLearnerSession() => _resetLearnerSession(invalidate);
}

extension LearnerSessionWidgetRef on WidgetRef {
  void resetLearnerSession() => _resetLearnerSession(invalidate);
}

/// Point d'entrée sans arbre de widgets, utilisé par les tests de frontière.
extension LearnerSessionContainer on ProviderContainer {
  void resetLearnerSession() => _resetLearnerSession(invalidate);
}

/// Observateur d'identité : purge l'état élève à chaque changement d'UID.
///
/// Il vit **hors** du graphe de dépendances des providers qu'il invalide. Il
/// observe l'authentification comme eux, en frère et non en ancêtre : un
/// provider ne peut pas invalider ceux qui dépendent de lui, ce qui interdit
/// de déclencher la purge depuis `AuthController` lui-même.
///
/// La frontière est le changement d'identité, pas un geste d'interface : elle
/// tient donc aussi bien pour A → B directement que pour A → déconnecté → B,
/// et quel que soit le chemin ayant provoqué la transition.
final learnerSessionBoundaryProvider = Provider<void>((ref) {
  var previousUid = ref.read(authControllerProvider).userId;
  ref.listen<String?>(authControllerProvider.select((auth) => auth.userId), (
    _,
    nextUid,
  ) {
    if (nextUid == previousUid) return;
    previousUid = nextUid;
    ref.resetLearnerSession();
  });
});
