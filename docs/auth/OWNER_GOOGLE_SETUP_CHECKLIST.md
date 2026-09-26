# INTELLIA237 — « Continuer avec Google » : checklist du propriétaire

*Révision : 23 septembre 2026 — refonte Auth V2 (branche `fix/auth-v2-final-rework`).*
*Remplace la version du 22 septembre, qui visait une application inexistante
(`com.intellia237.app`) et décrivait le flux web `signInWithProvider`.*

Rien dans ce document n'a été exécuté par l'équipe de développement : aucune
console Firebase ou Google Cloud n'a été modifiée, rien n'a été déployé.
Chaque étape ci-dessous est une action du propriétaire.

---

## 1. Applications et projets concernés

| Environnement | Projet Firebase | Identifiant Android | Fichier de configuration dans le dépôt |
| --- | --- | --- | --- |
| Production | `edunova-aabd1` | `com.edunova.app` (saveur `production`) | `android/app/google-services.json` |
| Staging | `intellia237-staging` | `com.intellia237.app.staging` (saveur `staging`) | `android/app/src/staging/google-services.json` |

Source : `android/app/build.gradle.kts` (`productFlavors`). Aucune application
`com.intellia237.app` n'existe.

État constaté le 23/09 : les deux fichiers `google-services.json` ne contiennent
**aucune** entrée `oauth_client`. Tant que ce n'est pas corrigé, Google renvoie
une erreur de configuration et l'application affiche : « La connexion Google
n'est pas encore disponible sur cette version. Utilisez votre numéro de
téléphone. »

## 2. Le flux réellement utilisé

Flux **natif Android** (Credential Manager), via `google_sign_in` 7.2 :

1. Le sélecteur de comptes Google du téléphone renvoie un **jeton d'identité
   Google** (ID token). Aucune session Firebase n'est ouverte à ce stade.
2. La callable `probeGoogleIdentity` vérifie ce jeton (signature, émetteur,
   **audience = client OAuth Web**, expiration) et répond seulement
   « existing » ou « unknown ». Elle ne crée rien.
3. Compte connu : `signInWithCredential(GoogleAuthProvider.credential(idToken))`.
   Compte inconnu : la question « Vous utilisez déjà INTELLIA237 ? » ; « Oui »
   → connexion réelle au compte existant (téléphone ou e-mail) puis
   `linkWithCredential` sur **le même UID** ; « Non » → nouvelle identité, en
   Découverte.

Ce n'est **pas** le flux web `signInWithProvider` : les empreintes SHA et le
client OAuth Web sont donc indispensables.

## 3. Checklist Firebase / Google Cloud (à faire pour chaque projet)

### Étape 1 — Activer le fournisseur Google
Firebase Console → projet (`edunova-aabd1`, puis `intellia237-staging`) →
Authentication → Sign-in method → Google → Activer, choisir l'e-mail
d'assistance, Enregistrer. L'activation crée le client OAuth **Web** du projet.

### Étape 2 — Écran de consentement OAuth
Google Cloud Console → APIs & Services → OAuth consent screen, même projet.
Type Externe ; nom de l'application INTELLIA237 ; e-mail d'assistance ;
liens vers la politique de confidentialité et les conditions. Portées : `openid`,
`email`, `profile` seulement. Publier (aucune portée sensible).

### Étape 3 — Empreintes SHA-1 et SHA-256 de l'application Android
Firebase Console → Paramètres du projet → Général → application
`com.edunova.app` (production) ou `com.intellia237.app.staging` (staging) →
Ajouter une empreinte, pour **chaque** clé qui signe une version installée :

- **Debug** (versions de développement installées depuis un ordinateur) :
  ```bash
  keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
  ```
- **Clé de téléversement** (upload key du keystore de publication) :
  ```bash
  keytool -list -v -keystore <chemin du keystore> -alias <alias>
  ```
- **Signature d'application Google Play** (versions installées depuis le Play
  Store, re-signées par Google) : Play Console → l'application → Configuration
  → Intégrité de l'application → Signature de l'application → copier SHA-1 et
  SHA-256. Sans elle, Google fonctionne en test local et échoue chez les
  utilisateurs du Play Store.

Le nom de package déclaré doit être exactement celui de la saveur installée.

### Étape 4 — Récupérer le `google-services.json` à jour
Après les étapes 1 et 3, télécharger le fichier de chaque application et
remplacer :
- production : `android/app/google-services.json` ;
- staging : `android/app/src/staging/google-services.json`.

Vérifier que le fichier contient `oauth_client` avec au moins une entrée
`"client_type": 1` (Android, votre package et vos SHA) et une entrée
`"client_type": 3` (Web). Ce remplacement est une modification du dépôt à
committer ; il ne change aucune version.

Alternative sans nouveau fichier : fournir le client Web à la compilation,
`--dart-define=GOOGLE_SERVER_CLIENT_ID=<ID du client OAuth Web>.apps.googleusercontent.com`.

### Étape 5 — Configurer la sonde serveur, puis déployer
La callable `probeGoogleIdentity` refuse tout jeton tant que la variable
`GOOGLE_OAUTH_CLIENT_IDS` (liste séparée par des virgules) ne contient pas le
**client OAuth Web** du projet, c'est-à-dire l'audience des jetons émis sur
Android. Renseigner cette variable dans la configuration des Functions de
chaque projet avant le déploiement.

Ordre de déploiement (propriétaire) : Functions (`probeGoogleIdentity`,
`manageUserRoles` et les contrôles de rôles), puis règles Firestore. Tant que
`probeGoogleIdentity` n'est pas déployée, « Continuer avec Google » affiche un
message réseau et ne crée jamais d'identité.

### Étape 6 — Vérifier les clients OAuth (lecture seule)
Google Cloud Console → APIs & Services → Identifiants :
- « Android client for com.edunova.app » : type Android, package
  `com.edunova.app`, empreinte correspondant à l'étape 3 ;
- « Web client (auto created by Google Service) » : c'est l'ID à utiliser dans
  `GOOGLE_OAUTH_CLIENT_IDS` et, le cas échéant, `GOOGLE_SERVER_CLIENT_ID`.

## 4. Vérifications sur téléphone (non vérifiées à ce jour)

| Scénario | Attendu |
| --- | --- |
| Sélecteur ouvert puis fermé sans choisir | Retour à l'accueil, aucun message d'erreur. |
| Compte Google déjà rattaché à un compte INTELLIA237 | L'espace du compte s'ouvre directement. |
| Compte Google inconnu | « Vous utilisez déjà INTELLIA237 ? » ; aucune identité créée avant la réponse. |
| « Oui », puis numéro du compte existant et code SMS | Google est ajouté au même compte ; l'espace existant s'ouvre. |
| « Oui », puis e-mail et mot de passe du compte existant | Idem. |
| Compte Google déjà rattaché à un autre compte | « Ce compte Google est déjà associé à un autre compte INTELLIA237. » Rien n'est fusionné. |
| « Non, continuer » | Découverte ; après redémarrage, toujours la Découverte. |
| Configuration absente (étapes 3-5 non faites) | « La connexion Google n'est pas encore disponible… » ; le téléphone et le code élève restent disponibles. |

Codes Android attendus : l'annulation arrive en `GoogleSignInExceptionCode.canceled`
(une configuration incomplète peut aussi se présenter ainsi sur certains
appareils) ; une configuration absente en `clientConfigurationError` ou
`providerConfigurationError`.

## 5. Interdits
- Ne jamais pointer l'application de production vers un autre projet que
  `edunova-aabd1`.
- Ne jamais committer de keystore privé ni de mot de passe de keystore.
- Ne jamais retirer l'accès par numéro (+237) ni le code élève : ils restent
  les accès de référence.
