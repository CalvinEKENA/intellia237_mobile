# Accès démo (code d'invitation)

État au 28/09/2026 (branche `feat/content-engine`).

Un compte élève unique et partagé, ouvert par un **code d'invitation** remis
par le propriétaire (par exemple à un testeur). Il peut explorer toutes les
classes ; un message d'accueil l'invite à commencer par la Terminale D, la
plus fournie en cours, et précise que l'accès est offert par Calvin EKENA.

## Principes

- **Le code n'est jamais dans le dépôt** (public) : il vit uniquement dans le
  secret `DEMO_ACCESS_CODE` (Secret Manager). Sans secret, l'accès est fermé.
- Callable séparée `signInWithDemoAccessCode` : la connexion par code des
  élèves (`signInWithStudentAccessCode`) n'en dépend pas. Même
  anti-bruteforce (20 échecs / 15 min par client), même réponse d'échec.
- Compte `intellia-demo-student` : élève ordinaire (aucun droit adulte, aucun
  établissement, aucune liaison parent), marqué `demo` (champ du profil et
  revendication du jeton). Créé à la première connexion, en Terminale D.
- Changement de classe : callable `setDemoAccessClass`, refusée à tout autre
  compte ; le profil n'est jamais modifié depuis l'appareil.
- Côté application : l'écran « code élève » accepte un code d'invitation
  (6 à 11 lettres ou chiffres) et l'envoie à `signInWithDemoAccessCode`.
  L'accueil du compte démo montre la classe explorée et « Changer de
  classe » ; le message d'accueil s'ouvre une fois par appareil.

## Activation (à faire par le propriétaire)

1. Créer le secret (saisir le code quand la commande le demande, pour qu'il
   n'apparaisse pas dans l'historique du terminal) :
   ```
   firebase functions:secrets:set DEMO_ACCESS_CODE
   ```
2. Déployer les deux fonctions :
   ```
   firebase deploy --only functions:signInWithDemoAccessCode,functions:setDemoAccessClass
   ```
3. Publier une version de l'application qui contient ce changement : les
   versions précédentes n'acceptent que les codes élève de 12 caractères.
4. Le testeur : écran d'accès → « J'ai un code » → saisir le code.

## Révoquer ou changer le code

- Nouveau code : `firebase functions:secrets:set DEMO_ACCESS_CODE`, puis
  redéployer `signInWithDemoAccessCode`.
- Fermer l'accès : détruire le secret ou désactiver l'utilisateur
  `intellia-demo-student` dans la console Authentication.

## À savoir

- Compte partagé : tous les testeurs voient la même progression et la même
  classe (la dernière choisie).
- Les fonctions en ligne (compagnon, fil…) consomment les mêmes ressources
  que pour un élève.
