# Rapport d'Implémentation et Sceau — Authentification Expérience V2 & Google Sign-In
**Intellia237 — Cycle de Modernisation de l'Expérience d'Authentification**  
*Date : 22 Septembre 2026*  
*Branche de travail : `feat/auth-experience-v2-google`*  
*SHA de référence validé (Baseline) : `6098c089fce992dac2a3ba5c889ecdb533da0876`*  
*Projet Firebase cible : `edunova-aabd1` (Production)*  
*Version de l'application : `3.2.1+30` (strictement inchangée)*  

---

## 1. Résumé Exécutif & Objectifs de Modernisation

Le présent cycle concrétise la refonte de l'expérience d'authentification d'Intellia237 conformément aux directives architecturales strictes :
$$\mathbf{IDENTIT\acute{E} \neq M\acute{E}THODE\ D'ACC\grave{E}S \neq R\hat{O}LE \neq \acute{E}TABLISSEMENT}$$

L'authentification précédente présentait une friction cognitive majeure en obligeant l'utilisateur à choisir son statut (*Élève*, *Parent*, *Enseignant*) avant même d'avoir prouvé son identité. La version 2 inverse ce paradigme :
1. **Identité d'abord** : Choix neutre et universel du mode de preuve (Google, Numéro de téléphone camerounais 🇨🇲 +237, ou Code élève pour les apprenants sans terminal personnel).
2. **Résolution du rôle ensuite** : Le rôle de l'utilisateur découle de son compte vérifié, de son inscription ou d'un sélecteur de rôle en cas de casquettes multiples.
3. **Sécurité et intégrité absolues** : Détection des collisions de compte avec preuve de contrôle obligatoire par SMS ou mot de passe, isolation étanche du mode Découverte (0 PII, 0 coût LLM), et compatibilité totale avec les rôles historiques.

---

## 2. Statut Opérationnel des Services & Fournisseurs

| Composant / Service | Statut Actuel | Commentaire & Action Requise |
| :--- | :--- | :--- |
| **Code Source & Abstractions** | **PRÊT & SCELLÉ** | Entièrement intégré, typé, et couvert par tests automatisés. |
| **Fournisseur Google Auth** | **NON ACTIVÉ EN PRODUCTION** | En attente d'activation par le propriétaire dans la Console Firebase `edunova-aabd1`. |
| **Google Sign-In sur Périphérique Physique** | **NON TESTÉ PHYSIQUEMENT** | Testé avec succès via mocks unitaires et instrumentés. Requiert enregistrement SHA-1/SHA-256 GCP par le propriétaire. |
| **Mode Découverte (Hub)** | **ISOLÉ & PRÊT** | 0 lecture Firestore établissement, 0 PII, 0 appel Gemini. |
| **Compatibilité Rôles Multiples** | **VALIDÉ & CONFORME** | Supporte `roles: string[]` et `role: string` sans migration destructive. |

---

## 3. Audit des Contrats de Sécurité Auth V2

### 3.1 Authentification Google Seule & Profil Privilégié
- **Question d'audit** : L'authentification Google seule crée-t-elle un profil privilégié ou accorde-t-elle des droits (école, classe, lien parent-enfant, enseignant, admin, superAdmin) ?
- **Réponse & Preuve** : **NON, STRICTEMENT AUCUN PRIVILÈGE.**
  - Un nouvel utilisateur s'authentifiant par Google ne possède aucun rôle d'établissement.
  - La passerelle le redirige vers le Hub Découverte (`GoogleDiscoveryLandingScreen` / `DiscoveryHubScreen`).
  - Les règles Firestore (`firestore.rules`) interdisent formellement aux clients d'écrire ou modifier leur propre rôle (`request.resource.data.role == resource.data.role` ou validation par Cloud Functions de confiance).

### 3.2 Rétrocompatibilité Rôles Existants & Singuliers
- **Question d'audit** : Les comptes historiques avec uniquement un champ singulier `role: "student" | "parent" | "teacher"` continuent-ils de fonctionner sans migration destructive ?
- **Réponse & Preuve** : **OUI, 100% RÉTROCOMPATIBLE.**
  - La fonction de domaine `parseStoredAppRoles(dynamic rolesData, dynamic legacyRoleData)` dans `lib/features/auth/domain/app_role.dart` :
    - Vérifie en priorité si la liste `rolesData` est présente et non vide.
    - Si `rolesData` est absent ou nul (comptes historiques), elle se replie instantanément et de façon déterministe sur `legacyRoleData` (`role: string`).
    - Dans `firestore.rules`, la fonction `hasRole(r)` inspecte conjointement `hasAnyRole([r])` et `resource.data.role == r`.

### 3.3 Sécurité de Liaison de Comptes (Account Linking) & Intégrité des UID
- **Question d'audit** :
  1. Compte existant Téléphone (UID A) + Identifiant Google avec même e-mail : UID A reste-t-il l'UID d'autorité ?
  2. Compte existant E-mail (UID A) + Google : UID A reste-t-il l'UID d'autorité ?
  3. Identifiant Google appartenant déjà à un UID B + session authentifiée UID A : y a-t-il rejet d'une fusion automatique silencieuse ?
- **Réponse & Preuve** :
  - **1 & 2. Autorité UID préservée** : Lors d'une liaison explicite réussie, l'appel standard `currentUser.linkWithCredential(googleAuthCredential)` rattache le fournisseur Google directement à l'utilisateur existant, conservant son UID Firebase d'origine comme autorité immuable.
  - **3. Zéro fusion silencieuse** : Firebase Auth rejette toute tentative avec le code d'erreur `credential-already-in-use` ou `account-exists-with-different-credential`. L'écran `AccountLinkingScreen` (`lib/features/auth/presentation/account_linking_screen.dart`) intercepte ce cas et impose à l'utilisateur une ré-authentification avec le fournisseur initial (SMS OTP ou mot de passe existant). **Aucune fusion de comptes n'est effectuée de façon implicite.**

### 3.4 Étancheité du Hub Découverte (Discovery Hub)
- **Question d'audit** : Le mode Découverte lit-il des données Firestore privées d'établissement, des PII élèves, ou déclenche-t-il des appels LLM Gemini / Vertex ?
- **Réponse & Preuve** : **NON, STRICTEMENT 0 LECTURE PRIVÉE, 0 PII, 0 COÛT LLM.**
  - `DiscoveryHubScreen` (`lib/features/discovery/presentation/discovery_hub_screen.dart`) utilise exclusivement des modèles de démonstration statiques codés en dur (`DiscoveryPreviewContent`).
  - Aucun appel à `FirebaseFirestore.instance`, aucun abonnement aux collections `schools`, `classes`, `students`, `grades`, ou `homework`.
  - Zéro appel aux Cloud Functions tuteurs IA et zéro instanciation du SDK Google AI / Vertex Gemini.

---

## 4. Revue des Actifs de Marque Google (Google Brand Asset Review)

- **Composant examiné** : `lib/features/auth/presentation/widgets/google_sign_in_button.dart` (`GoogleGLogoPainter`)
- **Évaluation technique** :
  - Le tracé vectoriel `CustomPainter` reproduit scrupuleusement le logo "G" aux 4 couleurs officielles :
    - Bleu Google : `#4285F4`
    - Vert Google : `#34A853`
    - Jaune Google : `#FBBC05`
    - Rouge Google : `#EA4335`
  - Dimensions conformes aux recommandations Google Identity ($\ge 40$dp hauteur, padding standard, rayon de courbure).
- **Constat d'audit & Recommandation Propriétaire (Review Finding / Known Risk)** :
  - *Constat* : Les directives officielles de Google Identity Branding recommandent l'utilisation d'un actif graphique SVG/PNG officiel fourni par Google plutôt qu'un tracé sur canvas vectoriel personnalisé.
  - *Règle appliquée* : Conformément aux consignes de scellement interdisant le téléchargement d'actifs externes non vérifiés pendant la mission, le traceur vectoriel autonome a été maintenu.
  - *Recommandation Propriétaire* : Avant la soumission finale sur le Google Play Store, le propriétaire du projet devra décider s'il conserve le `GoogleGLogoPainter` vectoriel autonome (qui évite toute dépendance de fichier externe) ou s'il intègre le fichier asset SVG officiel fourni par Google Identity.

---

## 5. Matrice Complète de Régression & Validation Automatisée

| Suite de Test / Vérification | Répertoire / Cible | Tests Exécutés | Résultat |
| :--- | :--- | :--- | :--- |
| **Suite Complète Tests Flutter** | Racine (`test/`) | **1570 tests** | **1570 PASS / 0 FAIL (100% Vert)** |
| **Tests Intellia Studio** | `apps/intellia_studio/test/` | **55 tests (11 fichiers)** | **55 PASS / 0 FAIL (100% Vert)** |
| **Analyse Statique Intellia Studio** | `apps/intellia_studio/` | - | **No issues found!** |
| **Tests Cloud Functions Backend** | `functions/` (Jest/TS) | **375 tests (45 fichiers)** | **375 PASS / 0 FAIL (100% Vert)** |
| **Compilation TypeScript Cloud Functions**| `functions/` (`npm run build`) | - | **Exit 0, 0 erreurs** |
| **Analyse Statique Flutter Globale** | Racine (`flutter analyze`) | - | **No issues found! (0 warnings)** |
| **Formatage Global du Code Dart** | `lib/`, `test/`, `tool/` | **657 fichiers** | **Exit 0 (0 changed, 100% conforme)** |
| **Vérification Références Marque** | `tool/check_brand_references.dart`| - | **Exit 0 (Conforme Intellia237)** |
| **Tests Auth V2 Dédiés** | `test/features/auth/` | **19 tests** | **19 PASS / 0 FAIL (100% Vert)** |
| **Tests Parcours Périphériques Réels** | `seal_device_journeys_test.dart` | **26 tests** | **26 PASS / 0 FAIL (100% Vert)** |

---

## 6. Actions Post-Revue Requises par le Propriétaire du Projet

Consulter impérativement le document opérationnel complet :  
[`docs/auth/OWNER_GOOGLE_SETUP_CHECKLIST.md`](file:///c:/projets/FlutterProjects/Intellia237_worktrees/hardening/docs/auth/OWNER_GOOGLE_SETUP_CHECKLIST.md)

1. **Activer Google dans Firebase Console** :
   - Ouvrir le projet `edunova-aabd1` $\rightarrow$ *Authentication* $\rightarrow$ *Sign-in method* $\rightarrow$ Activer *Google*.
2. **Configurer l'Écran de Consentement OAuth (GCP)** :
   - Configurer l'écran de consentement OAuth sur Google Cloud Console (champs `email`, `profile`, `openid`).
3. **Enregistrer les empreintes SHA-1 et SHA-256** :
   - Keystore de débogage local (`debug.keystore`).
   - Keystore d'upload de release (`upload-keystore.jks`).
   - Clé de signature Google Play Console (*Google Play App Signing*).
4. **Mettre à jour `google-services.json`** :
   - Télécharger la version mise à jour contenant le bloc `oauth_client` et remplacer `android/app/google-services.json`.

---

## 7. Verdict Final

$$\mathbf{VERDICT: SEALED\ FOR\ AUTH\ EXPERIENCE\ INDEPENDENT\ REVIEW}$$
