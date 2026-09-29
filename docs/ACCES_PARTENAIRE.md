# Accès partenaire — compte de test « démo pour Francis »

État au 29/09/2026 (branche `feat/content-engine`). **Rien n'est déployé.**

## Principe

Un compte de test privilégié, connu du propriétaire et de son partenaire
financier. Sur l'écran e-mail, dès que la valeur saisie est **exactement** la
valeur secrète du compte (espaces autour et casse ignorés) :

- le champ mot de passe se grise et n'est plus éditable ;
- un statut « Accès partenaire INTELLIA » apparaît ;
- le bouton devient « Accéder à INTELLIA » ;
- un tap ouvre l'accès : ni mot de passe, ni lien, ni code, ni SMS.

Toute autre valeur suit le parcours e-mail habituel, sans aucun changement.
Le comportement est absent des écrans d'accès du personnel (administration).

## La valeur secrète n'est pas dans le dépôt

Le dépôt GitHub est **public** : la valeur n'y figure ni dans le code, ni dans
les tests, ni dans cette documentation, et elle n'est écrite nulle part
ailleurs que ci-dessous.

| Où | Quoi | Comment |
|---|---|---|
| Serveur | la valeur elle-même | secret Secret Manager `PARTNER_ACCESS_EMAIL` (comme `DEMO_ACCESS_CODE`), un par projet Firebase. Sans lui, l'accès est fermé |
| Application | un **condensat salé** de la valeur (PBKDF2-HMAC-SHA256, sel aléatoire), jamais la valeur | fourni à la construction par `--dart-define-from-file=config/partner_access.local.json` ; ce fichier est **local et ignoré par git** (`config/*.local.json`) |
| Compte Firebase | **rien** | le compte n'a aucune adresse (comme le compte démo) : ni dans Authentication, ni dans le profil Firestore. Pas de réinitialisation de mot de passe possible, aucune fuite par la console |
| Journaux | **rien** | ni la valeur, ni une saisie, ni l'adresse IP du client |

La valeur doit avoir l'allure d'une adresse e-mail (contenir un `@`, 254
caractères au plus) : c'est ce que saisit le champ e-mail. Choisissez-la longue
et non devinable ; n'importe quel domaine convient, aucune boîte n'est jamais
contactée.

L'application n'a besoin que de *reconnaître* la valeur pour adapter l'écran
sans attendre le réseau. Elle ne peut pas la relire : seul le condensat est
dans le paquet. Ce n'est pas un secret inviolable : le condensat est dans
l'application distribuée, et quiconque devine la valeur la vérifie hors ligne
(chaque essai coûte 4 096 tours de calcul). Le serveur reste le seul juge.

**Sans condensat à la construction**, l'application ne reconnaît aucune valeur :
le partenaire verrait l'écran e-mail normal et un mot de passe lui serait
demandé. **Toute construction destinée au partenaire (essai, staging,
production) doit donc recevoir le fichier** ; la production passe par
`tool/build_partner_release.ps1`, qui échoue clairement sans lui.

## Valeurs révoquées

Une première adresse a été publiée par erreur dans l'historique du dépôt (avant
le 29/09/2026). Elle est **révoquée** : la liste `revokedDigests` (client,
`lib/features/partner_access/domain/partner_digest.dart`) et
`revokedPartnerEmailDigests` (serveur) ne contiennent que son condensat SHA-256,
jamais sa valeur.

- l'application ne la reconnaît jamais, même si un condensat de construction la
  porte encore ;
- le serveur ferme l'accès si le secret la porte encore, même si on la
  reconfigure par erreur ;
- l'outil de génération la refuse ;
- un test parcourt le dépôt et échoue si une valeur révoquée y figure
  (`test/features/partner_access/partner_revoked_test.dart`).

L'historique Git n'est pas réécrit : la valeur y reste lisible. Elle ne donne
plus aucun accès.

## Décision assumée, et ce qu'elle implique

Le propriétaire a décidé (29/09/2026) que **connaître la valeur suffit** pour ce
compte. Ce n'est donc pas une preuve d'identité : quiconque la connaît obtient
une session sur ce compte. Le risque est borné par construction, il n'est pas
supprimé :

- le compte est un **élève ordinaire** : aucun droit adulte, aucun
  établissement, aucune liaison parent, aucun droit d'administration ni de
  suppression ; il ne lit que ses propres documents, comme tout élève ;
- c'est une **vraie session Firebase** (jeton personnalisé émis par le
  serveur) : les règles Firestore et Storage ne changent pas d'une ligne ;
- la progression et l'historique sont **partagés** par quiconque entre avec
  cette valeur : n'y saisir aucune donnée personnelle ;
- les fonctions en ligne consomment les mêmes ressources que pour un élève.

## Essais massifs

- **App Check** : la fonction hérite du réglage global du projet
  (`ENFORCE_APP_CHECK`, faux par défaut : rien ne casse pour les versions déjà
  installées). Le basculer à `true` est un déploiement dédié, une fois les
  jetons observés.
- **Verrou par client** : 10 échecs en 15 minutes bloquent le client (adresse IP
  hachée avec la valeur secrète, jamais en clair) pendant 30 minutes, **même
  avec la bonne valeur**. Les compteurs vivent dans `student_access_attempts`
  sous des identifiants `partner-…` (serveur seulement, aucune règle à
  redéployer). Le titulaire ne se trompe jamais : l'application n'appelle la
  fonction qu'avec la valeur reconnue. Un verrou illisible refuse au lieu
  d'ouvrir.
- **Réponses uniformes** : valeur fausse, presque juste, secret absent, accès
  fermé, client verrouillé : la même réponse, octet pour octet. Rien ne dit
  qu'une saisie était « presque » la bonne.

## Ce que fait le compte

- **Un seul compte canonique** : UID `intellia-demo-francis`, prénom
  « Francis », créé à la première connexion puis toujours réutilisé (même
  profil, même progression, même historique), **quelle que soit la valeur
  secrète en vigueur**. Changer la valeur ne crée jamais un nouvel utilisateur.
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

## Mise en place (PowerShell, une fois par projet Firebase, puis à chaque changement de valeur)

Depuis la racine du dépôt.

### 1. Le condensat de l'application (local, non versionné)

```powershell
dart run tool/partner_access_digest.dart
```

La valeur se saisit à l'invite (**masquée**, jamais en argument : le terminal la
garderait), puis se retape pour confirmation. Seul le condensat est écrit dans
`config/partner_access.local.json`, que git ignore ; l'outil refuse un fichier
que git ne couvre pas, une valeur sans `@` et une valeur révoquée. Le même
fichier sert à tous les projets Firebase.

Contrôle facultatif (masqué aussi) : le condensat reconnaît-il bien la valeur ?

```powershell
dart run tool/partner_release_check.dart --verify
```

### 2. Le secret du serveur

Prérequis, déjà exigés par l'accès démo et le code d'accès élève : le compte de
service d'exécution des Functions a le rôle
`roles/iam.serviceAccountTokenCreator` sur lui-même (voir
`docs/architecture/FAMILY_IDENTITY_ACCESS_BILLING.md` §12). À vérifier :

```powershell
gcloud functions describe signInWithStudentAccessCode --gen2 --region europe-west1 --project PROJET --format="value(serviceConfig.serviceAccountEmail)"
```

```powershell
gcloud iam service-accounts get-iam-policy SERVICE_ACCOUNT_EMAIL --project PROJET
```

Si le rôle manque :

```powershell
gcloud iam service-accounts add-iam-policy-binding SERVICE_ACCOUNT_EMAIL --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" --role="roles/iam.serviceAccountTokenCreator" --project PROJET
```

Le secret : la commande demande la valeur, **masquée** ; saisir la **même**
valeur qu'à l'étape 1.

```powershell
firebase functions:secrets:set PARTNER_ACCESS_EMAIL --project PROJET
```

Le déploiement des deux fonctions concernées (la construction des Functions se
lance toute seule) :

```powershell
firebase deploy --only functions:signInWithPartnerAccess,functions:setDemoAccessClass --project PROJET
```

`PROJET` = `intellia237-staging` d'abord, puis `edunova-aabd1`. Vérifier le
journal après un premier accès :

```powershell
firebase functions:log --only signInWithPartnerAccess --project PROJET
```

`setDemoAccessClass` est redéployée parce qu'elle accepte désormais le compte
partenaire ; son comportement pour le compte démo est inchangé. Une application
qui contient ce changement **et le condensat** doit être publiée : les versions
précédentes ne reconnaissent pas la valeur.

### 3. Construire avec le condensat

Essai sur téléphone (staging) :

```powershell
$env:JAVA_TOOL_OPTIONS='-Djdk.net.unixdomain.tmpdir=C:/jtmp'; flutter run -d ADRESSE_ADB --flavor staging -t lib/main_staging.dart --profile --dart-define-from-file=config/partner_access.local.json
```

Production : la barrière refuse de construire sans condensat valide, puis
construit le bundle (elle ne touche ni au `versionName` ni au `versionCode`) :

```powershell
pwsh tool/build_partner_release.ps1
```

(`-Apk` pour un APK.) La commande manuelle équivalente,
`flutter build appbundle --flavor production -t lib/main_production.dart --release --dart-define-from-file=config/partner_access.local.json`,
ne vérifie rien : lancer d'abord `dart run tool/partner_release_check.dart`.

### 4. Contrôle avant de livrer

Prouve que le condensat compilé reconnaît la valeur **et** qu'aucun fichier du
dépôt ne la contient (la valeur se passe en argument de ce seul contrôle, il
n'écrit rien) :

```powershell
flutter test test/features/partner_access/partner_digest_wiring_test.dart --dart-define-from-file=config/partner_access.local.json --dart-define=PARTNER_ACCESS_CHECK_ADDRESS=VALEUR
```

## Changer la valeur

Nouvelle valeur pour le secret (`firebase functions:secrets:set …`, puis
redéployer `signInWithPartnerAccess`) et nouveau condensat (étape 1), puis une
nouvelle construction. Le compte canonique (UID, progression, historique) ne
change pas. Une ancienne version du secret reste inactive ; la détruire :
`firebase functions:secrets:destroy PARTNER_ACCESS_EMAIL@VERSION --project PROJET`.

## Fermer l'accès

- immédiat, sans nouvelle version : désactiver l'utilisateur
  `intellia-demo-francis` dans la console Authentication ;
- ou définir `PARTNER_ACCESS_DISABLED=true` dans les paramètres des Functions
  du projet puis redéployer `signInWithPartnerAccess` ;
- ou supprimer la fonction : `firebase functions:delete signInWithPartnerAccess --region europe-west1 --project PROJET`.

## Code

- serveur : `functions/src/services/partnerAccess.ts` (callable, identité,
  lecture du secret, verrou, valeurs révoquées) et
  `functions/src/services/demoAccess.ts` (création du compte, partagée avec le
  compte démo) ;
- client : `lib/features/partner_access/` (`PartnerAccess`, `PartnerDigest`),
  `LoginScreen`, `AuthController.signInWithPartnerAccess` ;
- outils : `tool/partner_access_digest.dart`, `tool/partner_release_check.dart`,
  `tool/build_partner_release.ps1` ;
- tests : `functions/src/__tests__/partnerAccess.test.ts`,
  `test/features/partner_access/`.
