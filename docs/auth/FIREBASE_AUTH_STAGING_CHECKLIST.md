# Checklist Firebase Authentication staging

## Diagnostic confirme

- Projet Firebase : `intellia237-staging`
- Application Android : INTELLIA237 Staging
- Package Android : `com.intellia237.app.staging`
- Client Android, App ID et cle client : coherents entre
  `android/app/src/staging/google-services.json` et
  `lib/firebase_options.dart`
- Endpoint teste : Identity Toolkit `accounts:signUp`
- Resultat actuel : HTTP 400 `CONFIGURATION_NOT_FOUND`

Cette reponse est produite par Firebase Authentication avant toute creation
d'utilisateur ou ecriture Firestore. Elle indique que Firebase Authentication
n'est pas initialise pour ce projet, ou que le fournisseur Email/Mot de passe
n'est pas active.

## Action requise dans Firebase Console

1. Ouvrir <https://console.firebase.google.com/>.
2. Selectionner le projet `intellia237-staging`.
3. Ouvrir **Build > Authentication**.
4. Si la page propose **Get started**, cliquer dessus pour initialiser Firebase
   Authentication dans ce projet.
5. Ouvrir l'onglet **Sign-in method**.
6. Selectionner **Email/Password**.
7. Activer le premier interrupteur **Email/Password**.
8. Laisser **Email link (passwordless sign-in)** desactive sauf besoin produit
   explicite.
9. Enregistrer.

Valeur attendue : le fournisseur Email/Mot de passe doit apparaitre avec le
statut **Enabled** dans `intellia237-staging`.

## Verification Google Cloud

Dans Google Cloud Console, avec le projet `intellia237-staging` selectionne :

1. Ouvrir **APIs & Services > Enabled APIs & services**.
2. Rechercher **Identity Toolkit API**.
3. Verifier que `identitytoolkit.googleapis.com` est activee.
4. Ouvrir **APIs & Services > Credentials** et inspecter la cle Android du
   client staging sans la copier dans un document.
5. Si des restrictions API sont configurees, verifier qu'elles autorisent
   Identity Toolkit API.
6. Si une restriction Android est configuree, verifier le package
   `com.intellia237.app.staging` et les empreintes SHA associees au build teste.

## Verification de l'application Android

Dans **Project settings > Your apps**, l'application Android staging doit
afficher :

- package : `com.intellia237.app.staging` ;
- projet : `intellia237-staging` ;
- App ID identique a celui du fichier staging suivi par Git ;
- fichier telecharge installe uniquement dans
  `android/app/src/staging/google-services.json`.

Ne pas remplacer `android/app/google-services.json`, qui reste la configuration
historique de production.

## Verification apres activation

1. Reconstruire l'APK staging.
2. Installer `build/app/outputs/flutter-apk/app-staging-debug.apk`.
3. Utiliser une adresse e-mail de test nouvelle.
4. Completer l'inscription Eleve.
5. Verifier dans **Authentication > Users** que l'UID existe.
6. Verifier dans Firestore les documents `users/{uid}` et
   `student_profiles/{uid}`.
7. Confirmer la classe, la serie eventuelle et `tutorId` (`kira` ou `leo`).
8. Verifier qu'aucun champ d'etablissement n'est cree.

Une requete de diagnostic invalide vers Identity Toolkit doit alors retourner
une erreur de validation telle que `MISSING_EMAIL`, et non
`CONFIGURATION_NOT_FOUND`.

## Autres preconditions staging

- Une base Firestore doit exister dans `intellia237-staging`.
- Les Firestore Rules de cette branche doivent etre deployees sur staging avant
  un test reel complet.
- `submitStaffRegistration` doit etre deployee en region `europe-west1` pour
  tester les inscriptions Enseignant/Direction. L'inscription Eleve ne depend
  pas de cette callable.
- Le probe HTTP du 27 juin 2026 retourne actuellement 404 pour
  `submitStaffRegistration` en region `europe-west1` : la callable staging
  n'est donc pas disponible a cette adresse.
- App Check n'est pas utilise par le parcours Eleve actuel. S'il est active en
  mode enforcement dans la Console, enregistrer l'application de test ou
  desactiver temporairement l'enforcement uniquement sur staging.

## Securite

- Aucune cle API n'est reproduite dans ce document.
- Aucun secret backend ou compte de service ne doit etre ajoute au depot.
- Les cles client Firebase Android ne remplacent jamais des identifiants de
  compte de service.
- Aucune action ne doit etre appliquee au projet Firebase de production dans
  le cadre de cette checklist.

---

## Mise à jour — diagnostics d'inscription (AUTH-CONFIG-001)

### Action console requise (propriétaire)
1. Console Firebase → projet **intellia237-staging**.
2. Authentication → **Get started** (si Authentication n'est pas initialisé).
3. Sign-in method → **Email/Password** → **Enable** → Save.

### Diagnostic côté app (déjà en place)
- Quand Firebase Auth / Email-Mot de passe n'est pas activé, l'erreur Firebase
  `configuration-not-found` (ou `operation-not-allowed`) est mappée vers
  l'identifiant diagnostic **`AUTH-CONFIG-001`**.
- En **staging**, le message d'erreur affiché inclut `[AUTH-CONFIG-001]`
  (copiable par le testeur) et un log non sensible est émis :
  `env`, `projectId`, `appId` (tronqué), `step`, `code`, `diagnostic`.
- En **production**, seul le message utilisateur est affiché.
- Jamais journalisés : mot de passe, clé API, token, contenu privé du profil.

### Après activation — vérifications runtime
Voir la checklist détaillée dans `FINAL_DEVICE_VALIDATION.md` (projectId,
package staging, compte créé dans Authentication, `users/{uid}`, profil Élève,
rôle/classe/série/compagnon, aucune exigence d'établissement).

### Rappel
Un build APK, un test mock, `flutter analyze` ou une CI verte **ne valident
pas** la mission Firebase : seule une création de compte réelle sur téléphone
la valide.
