# Intellia237 — Guide de Configuration Google Sign-In & GCP OAuth
**Destiné au Propriétaire du Projet (Project Owner Setup Checklist)**  
*Date de révision : 22 Septembre 2026*  
*Application : Intellia (com.intellia237.app)*  
*Environnement de Production : `edunova-aabd1`*

---

## 1. Contexte & Principes Fondamentaux

L'expérience d'authentification v2 d'Intellia repose sur le principe fondamental :
$$\text{IDENTITÉ} \neq \text{MÉTHODE D'ACCÈS} \neq \text{RÔLE} \neq \text{ÉTABLISSEMENT}$$

La méthode Google Sign-In offre une authentification rapide, sécurisée et sans friction pour les utilisateurs disposant d'un compte Google. Pour fonctionner sur les terminaux Android des élèves, parents et enseignants sans déclencher d'erreur `10: DEVELOPER_ERROR` ou `12500`, les identifiants OAuth 2.0 et les empreintes d'intégrité doivent être rigoureusement déclarés dans la Google Cloud Platform (GCP) et la console Firebase du projet de production **`edunova-aabd1`** (et **non** le projet obsolète `aureon-7ac27`).

---

## 2. Checklist d'Activation Firebase & GCP

### Étape 1 : Activer le Fournisseur Google dans Firebase Console
1. Accéder à [Firebase Console](https://console.firebase.google.com/) $\rightarrow$ Sélectionner le projet **`edunova-aabd1`**.
2. Dans le menu de gauche, naviguer vers **Build** $\rightarrow$ **Authentication** $\rightarrow$ Onglet **Sign-in method**.
3. Cliquer sur le fournisseur **Google**.
4. Basculer l'interrupteur sur **Activé** (Enable).
5. Sélectionner l'**E-mail d'assistance pour le projet** (Project support email) dans le menu déroulant (obligatoire pour Google Identity).
6. Nom public du projet : `Intellia` (ou `Intellia237`).
7. Cliquer sur **Enregistrer** (Save).

---

### Étape 2 : Configuration de l'Écran de Consentement OAuth (GCP Console)
1. Ouvrir la console Google Cloud : [GCP APIs & Services $\rightarrow$ OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent).
2. S'assurer que le projet sélectionné en haut est bien **`edunova-aabd1`**.
3. Type d'utilisateur : **Externe** (External) $\rightarrow$ Cliquer sur *Créer*.
4. Informations sur l'application :
   - **Nom de l'application** : `Intellia`
   - **Adresse e-mail d'assistance utilisateur** : [votre e-mail officiel ou contact@intellia237.com]
   - **Logo de l'application** : (Optionnel, respecter le format carré 120x120px)
   - **Domaine d'application** :
     - Lien vers la page d'accueil : `https://edunova-aabd1.web.app` (ou domaine officiel)
     - Lien vers les règles de confidentialité : `https://edunova-aabd1.web.app/privacy`
     - Lien vers les conditions d'utilisation : `https://edunova-aabd1.web.app/terms`
   - **Coordonnées du développeur** : [votre e-mail de contact]
5. Champs d'application (Scopes) :
   - Ne demander **aucun** champ sensible ou restreint.
   - Vérifier que seuls les 3 champs standards sont présents :
     - `.../auth/userinfo.email`
     - `.../auth/userinfo.profile`
     - `openid`
6. Utilisateurs tests (si l'état est "En test") :
   - Ajouter les adresses Gmail des testeurs internes pour les essais préliminaires.
   - Soumettre en production ou publier l'application lorsque les tests sont terminés (ne nécessite pas de vérification complexe si aucun scope sensible n'est demandé).

---

### Étape 3 : Enregistrement des Empreintes SHA-1 et SHA-256 (Android)

Pour qu'Android autorise le jeton Google Identity via Google Play Services, **toutes** les clés de signature doivent être déclarées dans la fiche de l'application Android (`com.intellia237.app`) dans Firebase Console :

1. Accéder à **Paramètres du projet** (roue crantée) $\rightarrow$ Onglet **Général** $\rightarrow$ Sélectionner l'application Android **`com.intellia237.app`**.
2. Dans la section **Certificats d'empreinte SHA**, cliquer sur **Ajouter une empreinte** pour chacun des certificats suivants :

#### A. Empreinte de Débogage Local (Debug Keystore)
Générée par chaque machine de développement via la commande :
```bash
# Windows PowerShell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
*Ajouter à la fois le SHA-1 et le SHA-256 obtenus.*

#### B. Empreinte de la Clé de Téléversement (Upload Keystore)
Générée sur le fichier de keystore utilisé pour signer les bundles de publication :
```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```
*Ajouter le SHA-1 et le SHA-256.*

#### C. Empreinte de Signature Google Play (Play App Signing) — **CRITIQUE POUR LA PRODUCTION**
Lorsque l'AAB est téléversé sur Google Play, Google re-signe l'APK distribué avec la clé gérée par Google Play. Sans cette empreinte, Google Sign-In fonctionnera en local mais échouera systématiquement chez les utilisateurs Play Store !
1. Ouvrir la [Google Play Console](https://play.google.com/console).
2. Sélectionner **Intellia** $\rightarrow$ Menu **Configuration** $\rightarrow$ **Intégrité de l'application** (App Integrity).
3. Dans l'onglet **Signature d'application Google Play**, copier :
   - **Certificat de clé de signature d'application : Empreinte de certificat SHA-1**
   - **Certificat de clé de signature d'application : Empreinte de certificat SHA-256**
4. Coller ces deux empreintes dans Firebase Console $\rightarrow$ Application `com.intellia237.app`.

---

### Étape 4 : Récupération et Remplacement de `google-services.json`

Dès que les empreintes SHA et le fournisseur Google ont été enregistrés dans Firebase :
1. Dans Firebase Console $\rightarrow$ **Paramètres du projet** $\rightarrow$ Application Android `com.intellia237.app`.
2. Cliquer sur **Télécharger google-services.json**.
3. Remplacer le fichier existant dans le projet :
   `android/app/google-services.json`
4. Vérifier que le fichier JSON téléchargé contient bien :
   - `"project_id": "edunova-aabd1"`
   - Dans `oauth_client`, des entrées de type `1` (client Android avec les SHA déclarés) et au moins une entrée de type `3` (client Web Client ID pour l'échange de token).

---

### Étape 5 : Vérification des Identifiants Client OAuth 2.0 (GCP Credentials)

Vérifier dans la [GCP Console $\rightarrow$ Identifiants](https://console.cloud.google.com/apis/credentials) pour le projet `edunova-aabd1` :
1. **ID client OAuth 2.0 — Android client for com.intellia237.app (auto created by Google Service)** :
   - Type : Android
   - Nom du package : `com.intellia237.app`
   - Empreinte : doit correspondre à vos SHA enregistrés.
2. **ID client OAuth 2.0 — Web client (auto created by Google Service)** :
   - Type : Application Web
   - Utilisé par `google_sign_in` sous le capot pour obtenir le `idToken` échangé avec `GoogleAuthProvider.credential(idToken: ...)`.

---

## 3. Matrice de Test & Comportements de Secours

| Scénario | Comportement Attendu |
| :--- | :--- |
| **Utilisateur annule la boîte de dialogue Google** | L'écran d'accueil reste réactif, aucun message d'erreur bloquant. |
| **Compte Google déjà associé à un compte SMS/Mot de passe existant** | L'application redirige automatiquement vers l'écran sécurisé de liaison (`AccountLinkingScreen`), exigeant la preuve de contrôle du compte existant. Aucun détournement de compte possible. |
| **Nouvel utilisateur Google sans profil Intellia** | Redirection vers le sas sécurisé `GoogleDiscoveryLandingScreen` proposant soit le Mode Découverte (hors-ligne/isolé), soit la complétion de profil avec son rôle d'usage. |
| **Connexion sans Play Services ou configuration GCP incomplète** | L'erreur est capturée proprement, l'interface affiche un message d'explication amical et invite à utiliser l'authentification par numéro camerounais (+237) ou code élève. |

---

## 4. Résumé des Interdictions Strictes
- **NE PAS** modifier le `project_id` vers un projet autre que `edunova-aabd1`.
- **NE PAS** commiter de clés de signature privées (`upload-keystore.jks`) dans le dépôt public Git.
- **NE PAS** supprimer les méthodes d'accès par SMS (+237) ni par Code Élève : elles restent le mode d'accès primaire et inclusif de référence au Cameroun.
