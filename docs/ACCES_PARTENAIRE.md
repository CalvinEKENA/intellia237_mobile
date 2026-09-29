# Accès partenaire — compte de test « démo pour Francis »

État au 29/09/2026 (branche `feat/content-engine`). **Rien n'est déployé.**

## Principe

Un compte de test privilégié, connu du propriétaire et de son partenaire
financier. Sur l'écran e-mail, dès que l'adresse saisie est **exactement**
`fran6farmer@yahoo.fr` (espaces autour et casse ignorés) :

- le champ mot de passe se grise et n'est plus éditable ;
- un statut « Accès partenaire INTELLIA » apparaît ;
- le bouton devient « Accéder à INTELLIA » ;
- un tap ouvre l'accès : ni mot de passe, ni lien, ni code, ni SMS.

Toute autre adresse suit le parcours e-mail habituel, sans aucun changement.
Le comportement est absent des écrans d'accès du personnel (administration).

## Décision assumée, et ce qu'elle implique

Le propriétaire a décidé (29/09/2026) que **connaître l'adresse suffit** pour ce
compte. Ce n'est donc pas une preuve d'identité, et l'adresse est dans un dépôt
public : n'importe qui qui la saisit obtient une session sur ce compte. Le
risque est borné par construction, il n'est pas supprimé :

- le compte est un **élève ordinaire** : aucun droit adulte, aucun
  établissement, aucune liaison parent, aucun droit d'administration ni de
  suppression ; il ne lit que ses propres documents, comme tout élève ;
- c'est une **vraie session Firebase** (jeton personnalisé émis par le
  serveur) : les règles Firestore et Storage ne changent pas d'une ligne ;
- la progression et l'historique sont **partagés** par quiconque entre avec
  cette adresse : n'y saisir aucune donnée personnelle ;
- les fonctions en ligne consomment les mêmes ressources que pour un élève.

## Ce que fait le compte

- **Un seul compte canonique** : UID `intellia-demo-francis`, prénom
  « Francis », créé à la première connexion puis toujours réutilisé (même
  profil, même progression, même historique). Jamais de nouvel utilisateur.
- **Marque** : `demoForFrancis` (revendication du jeton et champ du profil).
  Aucun drapeau `demo`.
- **Terminale D** par défaut à la première ouverture : maths (3 chapitres),
  anglais (2), physique C-D (2), leurs leçons, exercices, jeux et Quiz.
- **Toutes les classes et séries** : l'accueil propose « Changer de classe »
  (même mécanisme que le compte démo, callable `setDemoAccessClass`, refusée à
  tout autre compte : il faut l'UID exact **et** la revendication du serveur).
- **Compagnon** : déterministe et local, aucun abonnement ni réserve à vérifier.
- **Aucune barrière d'abonnement** n'existe côté client : ni « abonnement
  requis », ni « contenu verrouillé », ni « classe non autorisée » pour ce
  compte. Les contenus propres à un établissement ne lui sont pas visibles
  (comme au compte démo, il n'a pas d'établissement).

## À déployer (par le propriétaire, aucun déploiement n'a été fait)

Prérequis, déjà exigés par l'accès démo et le code d'accès élève : le compte de
service d'exécution des Functions a le rôle
`roles/iam.serviceAccountTokenCreator` sur lui-même (voir
`docs/architecture/FAMILY_IDENTITY_ACCESS_BILLING.md` §12). À vérifier :

```
gcloud functions describe signInWithStudentAccessCode --gen2 --region europe-west1 --project edunova-aabd1 --format="value(serviceConfig.serviceAccountEmail)"
```

```
gcloud iam service-accounts get-iam-policy SERVICE_ACCOUNT_EMAIL --project edunova-aabd1
```

Si le rôle manque :

```
gcloud iam service-accounts add-iam-policy-binding SERVICE_ACCOUNT_EMAIL --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" --role="roles/iam.serviceAccountTokenCreator" --project edunova-aabd1
```

Aucun secret à créer. Déploiement des deux fonctions concernées :

```
firebase deploy --only functions:signInWithPartnerAccess,functions:setDemoAccessClass --project edunova-aabd1
```

Le même déploiement sur l'environnement d'essai, à faire d'abord :

```
firebase deploy --only functions:signInWithPartnerAccess,functions:setDemoAccessClass --project intellia237-staging
```

Ordre : déployer, ouvrir une fois l'accès depuis une application de cette
version, puis vérifier le journal :

```
firebase functions:log --only signInWithPartnerAccess --project edunova-aabd1
```

`setDemoAccessClass` est redéployée parce qu'elle accepte désormais le compte
partenaire ; son comportement pour le compte démo est inchangé. Une application
qui contient ce changement doit être publiée : les versions précédentes ne
reconnaissent pas l'adresse.

## Fermer l'accès

- immédiat, sans nouvelle version : désactiver l'utilisateur
  `intellia-demo-francis` dans la console Authentication ;
- ou définir `PARTNER_ACCESS_DISABLED=true` dans les paramètres des Functions
  du projet puis redéployer `signInWithPartnerAccess` ;
- ou supprimer la fonction : `firebase functions:delete signInWithPartnerAccess --region europe-west1 --project edunova-aabd1`.

## Code

- serveur : `functions/src/services/partnerAccess.ts` (callable, identité) et
  `functions/src/services/demoAccess.ts` (création du compte, partagée avec le
  compte démo) ;
- client : `lib/features/partner_access/`, `LoginScreen`,
  `AuthController.signInWithPartnerAccess` ;
- tests : `functions/src/__tests__/partnerAccess.test.ts`,
  `test/features/partner_access/partner_access_test.dart`.
