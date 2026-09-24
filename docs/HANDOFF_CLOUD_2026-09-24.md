# Passation vers une session Claude Code dans le cloud (24/09/2026)

Branche : `fix/auth-v2-final-rework`. Projet Firebase de production :
`edunova-aabd1` (package Android `com.edunova.app`). Version : `3.2.1+32`.

## Ce qui est livré (commits récents, 1671 tests Flutter verts)
- Auth V2 : entrée neutre, Google « preuve d'abord » (sonde serveur), rôles
  serveur, téléphone familial « Continuer comme… / Je suis son parent ».
- V1 sans voix (ni micro, ni TTS) ; langage 100 % humain (garde-fou outillé).
- Démarrage instantané (session connue ouverte sur le dernier profil valide).
- Apprendre / Quiz : jamais « Impossible de charger » ; états « arrivent ».
- Parcours : scènes animées SVT 6e (`svt_germination_temperature_v1`,
  `svt_germination_watering_v1`, type `interactiveNative`) ; bouton
  « ← Quitter » visible ; images publiées affichées ; notions en fil d'idées.
- Écrans d'onboarding et d'authentification : **taille réelle** (QA 24/09).
  L'auth utilise `PinnedFooterLayout` (bouton épinglé au-dessus du clavier,
  contenu qui ne glisse que si l'écran est trop court, ombre d'indice) ;
  l'onboarding garde `FitViewport` en dernier recours seulement : les grands
  titres cèdent leur hauteur (`CampaignRoom`), scènes ≥ 98,5 % dès 360×640.
  Étape Compagnon : le choix est porté par le bouton épinglé (« Choisir
  Léo » → « Continuer avec Léo ») ; plus de flou ni de halo sur les phrases.
- Changement de compagnon depuis le profil : l'écran de choix n'enregistre
  qu'une fois (attente visible), se ferme lui-même et a un bouton retour ;
  l'écran de secours d'affichage a un bouton « Revenir » (`RouterEscape`).
- Guide d'inscription (parent / élève / enseignant) et guide de l'espace
  parent (6 étapes, boussole + « Revoir le guide »).
- Compagnon : envoie `tutor` + `tutorId` (le serveur déployé exige `tutor`) ;
  composeur redessiné.
- Polices renommées au format google_fonts (avant : police de secours partout).
- Version web (même code) : `WebPhoneFrame` responsive, SMS web via
  `signInWithPhoneNumber`, page de chargement, `.htaccess` Hostinger.

## Production : ce qui a été fait (avec accord explicite)
- 23/09 : 2 cartes Parcours 6e publiées (`flow_items/t27mTEm2lDq3B8jXyg8B`,
  `flow_items/ex7G1NP4RgqltWChMxHP`).
- 24/09 : droit d'appel public (`allUsers`, `roles/run.invoker`) ajouté à
  `submitflowactivity`, `recordlessonprogress`, `getpublishedquiz`,
  `checktrainingquizanswer`, `requestaccountdeletion` (Cloud Run bloquait les
  appels : « Impossible de valider les points du parcours »).

## Bloquants côté propriétaire
1. **Compagnon (Gemini) coupé** : Vertex AI répond 403 « Lightning dunning
   decision is deny » = compte de facturation en impayé. Solution : rattacher
   `edunova-aabd1` au compte de facturation disposant des crédits, après avoir
   vérifié que ces crédits couvrent les appels Gemini (Facturation → Crédits).
2. **Site principal** : l'archive web a été déposée à la racine
   d'`intellia237.com` (site principal remplacé) ; `savoir.intellia237.com`
   renvoie 404. Restaurer le site principal, déposer l'app dans le dossier du
   sous-domaine.
3. **Images des cours sur le web** : appliquer `docs/web/storage-cors.json`
   (`gcloud storage buckets update gs://edunova-aabd1.firebasestorage.app --cors-file=docs/web/storage-cors.json`)
   — en attente d'accord.
4. **Redéploiement des Functions** (propriétaire) : active la sonde Google
   (`GOOGLE_OAUTH_CLIENT_IDS` dans `functions/.env.edunova-aabd1`), l'index
   Firestore `subjects.status` (groupe de collections, cause probable
   d'Apprendre vide) et le contrat `tutorId` du compagnon.

## Reste à faire côté code
- Google sur le web (bouton Google Identity Services + origine OAuth).
- Notifications web (service worker FCM, clé VAPID).
- Prochain AAB : `versionCode` ≥ 33 (30, 31, 32 déjà utilisés sur Play).
- Retirer l'envoi du bloc `tutor` du compagnon une fois les Functions
  redéployées.

## Pièges connus
- Git Bash : `MSYS_NO_PATHCONV=1` pour `--base-href /`.
- « PathExistsException » au build (web ou AAB) : supprimer `build/web` ou
  `build/app/intermediates/flutter/productionRelease`.
- `gcloud` en boucle bash lit l'entrée standard et fausse les résultats :
  passer par un script avec `stdin=DEVNULL`.
- L'émulation mobile du navigateur intégré fausse le rendu Flutter web :
  tester dans des iframes de tailles réelles.
- Les animations répétées bloquent `pumpAndSettle` ; `FitViewport` ne fait
  qu'une mise en page par image (sinon `AnimatedSize` boucle).
