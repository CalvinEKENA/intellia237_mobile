# Rapport de refonte Auth INTELLIA237

Date : 27 juin 2026

## Perimetre

- Branche : `feature/auth-complete-mobile-flow`
- Pull Request : #6
- Identifiants historiques de production preserves sans modification
- Staging cible : `intellia237-staging` /
  `com.intellia237.app.staging`

## Cause de CONFIGURATION_NOT_FOUND

Le client staging est coherent : Project ID, package Android, App ID et cle
client correspondent entre le vrai `google-services.json` staging,
`firebase_options.dart` et `AppConfig`.

Une requete de diagnostic non creatrice envoyee directement a Identity Toolkit
avec le client staging retourne HTTP 400 `CONFIGURATION_NOT_FOUND`. L'echec se
produit donc dans `FirebaseAuth.createUserWithEmailAndPassword`, avant
l'obtention d'un UID, avant Firestore et avant toute Cloud Function.

Cause exacte : Firebase Authentication n'est pas initialise dans le projet
`intellia237-staging`, ou le fournisseur Email/Mot de passe n'y est pas active.
La correction Console est detaillee dans
`docs/auth/FIREBASE_AUTH_STAGING_CHECKLIST.md`. Aucune modification de Console
n'a ete revendiquee ou executee par cette branche.

## Corrections fonctionnelles

- Mapping centralise des erreurs Firebase en francais.
- Detection de `CONFIGURATION_NOT_FOUND` meme lorsqu'il est encapsule dans une
  erreur Firebase `internal-error`.
- Journalisation du code, du message technique et de la stack uniquement en
  debug, sans cle.
- Delais explicites sur la creation Auth et l'ecriture du profil Eleve.
- Suppression du compte Auth nouvellement cree si la transaction de profil
  echoue.
- Reprise d'un utilisateur Auth courant de meme e-mail pour recuperer un echec
  partiel sans creer un doublon.
- Ecran de reussite affiche uniquement apres creation Auth et ecritures
  Firestore reussies.
- Authentification locale finalisee au clic sur `Decouvrir INTELLIA237`.
- Callable staff adressee explicitement en region `europe-west1`.
- Probe de la callable staging : HTTP 404, donc fonction non disponible tant
  qu'un deploiement staging autorise n'a pas ete effectue.

## Suppression des etablissements

Les choix, recherches, catalogues, validations et messages d'etablissement ont
ete retires des inscriptions Eleve, Parent, Enseignant et Direction.

- Les nouveaux documents Eleve omettent `establishmentId` et
  `establishmentName`.
- Les nouveaux profils staff en attente omettent ces champs.
- Le payload callable accepte encore un ancien objet `establishment` optionnel
  pour ne pas casser un ancien client, mais ne le persiste plus.
- Les Firestore Rules conservent la lecture des champs historiques. Aucune
  migration et aucune suppression de donnee ne sont executees.

Consequence : un compte staff reste `pending_validation` et sans privileges.
La future activation d'un staff devra definir son perimetre organisationnel par
un processus d'administration distinct si ce perimetre reste necessaire.

## Nouvelle experience

Direction artistique : fond nuit indigo, surfaces profondes, gradients
indigo/violet, accents champagne, bordures lumineuses et animations courtes.

Ecrans refaits ou consolides :

- connexion ;
- choix de profil ;
- mot de passe oublie ;
- inscription Eleve ;
- cadres Parent, Enseignant et Direction ;
- reussite Eleve.

Parcours Eleve :

1. Identite ;
2. Classe et serie conditionnelle ;
3. choix direct de Kira ou Leo ;
4. securite, consentements et resume ;
5. reussite apres persistance reelle uniquement.

## Composants partages

- `AuthExperienceScaffold`
- `AuthAmbientBackground`
- `AuthHeader`
- `AuthGlassPanel`
- `AuthStepIndicator`
- `AuthAnimatedField`
- `AuthChoiceCard`
- `CompanionSelectionCard`
- `AuthConsentTile`
- `AuthErrorBanner`
- `AuthPrimaryButton`
- `AuthRegistrationFrame`
- `AuthSuccessScreen`

Le scaffold gere `SafeArea`, largeur contrainte, defilement, fermeture du
clavier et `MediaQuery.viewInsets.bottom`. Les erreurs utilisent une region
semantique live et proposent `Reessayer` lorsque l'action est pertinente.

## Kira et Leo

Seuls les assets officiels sont utilises :

- `assets/companions/kira.png`
- `assets/companions/leo.png`

Aucune image et aucun personnage generique n'ont ete ajoutes. Les cartes
appliquent uniquement scale, halo et selection haptique sans deformer les
images.

## Onboarding

- Quatre ecrans existants conserves sans changement de texte ou visuel.
- Duree : exactement 5 secondes par ecran.
- Duree automatique totale : environ 20 secondes.
- Pause sur `inactive`, `hidden`, `paused` et `detached`.
- Reprise sur `resumed` sans reinitialiser la progression.
- Swipe, Suivant, Passer et Commencer conserves.
- Le dernier ecran ne termine jamais le parcours automatiquement.
- Les transitions sont desactivees lorsque reduced motion est demande.

## Tests ajoutes

- quatre scenes et duree de 5 secondes ;
- pause/reprise lifecycle ;
- Passer et Commencer ;
- traduction des erreurs Firebase ;
- detection de `CONFIGURATION_NOT_FOUND` ;
- absence d'etablissement dans les documents Eleve ;
- absence d'etablissement dans l'interface ;
- reussite masquee apres echec de persistance ;
- redirection Auth uniquement apres confirmation de reussite ;
- tailles 320x640, 360x800, 390x844 et 430x932 ;
- facteur de texte 1,3 et clavier simule ;
- assets officiels Kira et Leo ;
- tests serveur staff sans champs d'etablissement.

## Test reel et risques restants

L'inscription reelle staging reste bloquee tant que Firebase Authentication
Email/Mot de passe n'est pas active dans la Console. Aucun telephone Android
n'est connecte et l'AVD local reference une image systeme absente. Le test reel
doit etre repris apres l'action Console avec l'APK staging produit.

Risques restants :

- activation manuelle Firebase Auth staging ;
- verification du deploiement des Rules sur staging ;
- deploiement de `submitStaffRegistration` staging avant test staff ;
- validation TalkBack/VoiceOver et clavier AZERTY sur telephone reel ;
- migration future Built-in Kotlin signalee par Flutter.

## Validations techniques

Resultats executes localement le 27 juin 2026 :

- `git diff --check` : succes ;
- `dart format --output=none --set-exit-if-changed .` : succes ;
- `flutter analyze --no-pub` : succes, aucune anomalie ;
- `flutter test --no-pub` : succes, 38 tests ;
- controle des references de marque : succes ;
- tests Functions : succes, 21 tests ;
- build TypeScript Functions : succes ;
- audit npm au seuil high : succes ; 9 vulnerabilites moderees transitives
  restent signalees ;
- Firestore Rules : succes, 15 tests ;
- Storage Rules : succes, 8 tests.

Builds Android verifies :

- production : `build/app/outputs/flutter-apk/app-production-debug.apk` ;
  package historique de production preserve ; SHA256
  `A417E6B189E7E573A2B5C60C370E14B4E24ED71E5DA758678BCA7F54B3D0EAFA` ;
- staging : `build/app/outputs/flutter-apk/app-staging-debug.apk` ; package
  compile `com.intellia237.app.staging` ; SHA256
  `040B5345E51144EC362290DA2C84E8A95C34FB854CDF5FFC9ADBDCB6F84D81CA`.

Les ressources Google Services generees associent bien le build staging au
projet `intellia237-staging`. Le build de production conserve sa configuration
historique. Aucune cle client n'est reproduite dans ce rapport.

Le test reel d'inscription n'a pas ete execute : aucun appareil Android ni
emulateur utilisable n'est disponible sur cette machine, et l'activation
Firebase Authentication staging reste une action Console obligatoire. Le
succes fonctionnel reel ne doit donc pas etre revendique avant application de
la checklist et creation verifiee d'un compte Eleve depuis l'APK staging.

## Garanties

- Aucun deploiement Firebase effectue.
- Aucune donnee de production modifiee.
- Aucun appel Gemini ou paiement modifie.
- Aucun push direct sur `main`.
- La PR #6 reste ouverte et non fusionnee.

---

## Mise à jour — correctifs téléphone (PR #6)

### A. Lisibilité Classe / Série
Le `ChoiceChip` (`_SelectionPill`), dont le fond/texte pouvaient être écrasés
par le `ChipTheme` global (blocs blancs illisibles), est remplacé par
`AuthSelectionPill` — composant contrôlé, couleurs littérales, indépendant du
thème. Non sélectionné : fond blanc 6 %, bordure 14 %, texte blanc 90 %, h≥52,
rayon 16. Sélectionné : gradient indigo→violet, texte blanc, coche, halo,
haptique, transition ~210 ms. Couvert par `auth_selection_pill_test.dart`.

### B. Découverte cinématique Kira / Léo
L'étape Compagnon ne montre plus jamais les deux personnages ensemble.
`CompanionDiscovery` : `PageView` une scène à la fois, révélation (fondu +
flou→net + tracking resserré), phrases une à une, flèche animée « Découvrir
Léo », transition halo violet→bleu-indigo, retour possible, sélection après
découverte, CTA « Continuer » actif seulement après choix. Un contrôleur par
scène libéré, pause en arrière-plan, reduced-motion, images précachées,
`RepaintBoundary`. Couvert par `student_registration_experience_test.dart`.

### C. Diagnostics d'inscription (staging)
`FirebaseErrorMapper.diagnosticId()` ajoute des identifiants stables
(`AUTH-CONFIG-001` quand Firebase Auth / Email-Mot de passe n'est pas activé).
En staging, le message inclut l'ID copiable et un log non sensible est émis
(env, projectId, appId tronqué, étape, code). Aucun secret journalisé. Le
correctif réel reste l'activation console + test device — voir
`FINAL_DEVICE_VALIDATION.md`.

### D. Splash fidèle au Web
Splash natif (#FAFAFD + logo officiel) + splash Flutter rejouant le splash Web,
sans frame blanche — voir `docs/design/WEB_SPLASH_TO_FLUTTER_REPORT.md`.

> Onboarding conservé à 5 s/écran. Intellia Flow, correctifs bootstrap et
> assets officiels Kira/Léo préservés.
