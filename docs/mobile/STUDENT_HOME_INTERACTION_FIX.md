# Correction des interactions Student Home

Date : 28 juin 2026

## Cause exacte du gel

Le gel a ete reproduit en montant le vrai `StudentHomeScreen` avec un compte
Eleve, des donnees deterministes et un tour considere comme non vu.

Avant correction, un tap au centre visuel de l'onglet Apprendre produisait un
chemin de hit test commencant par :

`RenderDecoratedBox -> RenderStack -> ... -> _RenderTheater`

Le premier objet touche etait le `RenderDecoratedBox` de la carte basse de
`_TourGuideOverlay`. Cette carte et la route de dialogue etaient au-dessus de
la barre. Le `RenderPointerListener` de l'item de navigation n'entrait pas dans
le chemin de hit test. Rendre seulement la zone sombre fermable ne corrigeait
pas les taps situes sur la carte basse qui recouvrait la navbar.

Avec le tour absent, le meme tap commence par le texte de l'item puis atteint
le `RenderPointerListener` de la navbar avant le layout du Scaffold. Les cinq
onglets changent alors correctement de contenu.

Une seconde anomalie a ete identifiee : la carte Matiere utilisait
`slideX(begin: 30)`. Cette valeur fractionnelle pouvait placer la carte a
environ 4 900 px hors ecran lorsque l'animation etait suspendue. La translation
est maintenant limitee a `0.08`.

## Correction

- `FeatureFlags.studentTourGuideEnabled` vaut `false` par defaut.
- Aucun `showGeneralDialog` de tour Eleve n'est lance automatiquement.
- Aucune GlobalKey de cible Eleve n'est creee lorsque le flag est desactive.
- L'architecture du tour reste disponible pour une future refonte non modale.
- Les couches decoratives, glow et indicateur de navbar sont `IgnorePointer`.
- Chaque item possede une cle stable, une semantique de bouton et une zone
  tactile sur toute sa largeur.
- Le bouton Retour Android ramene a Accueil depuis un onglet secondaire.
- Les contraintes du Profil et d'Apprendre supportent un facteur texte 1,3.

## Diagnostic staging

En staging ou debug, chaque tap de navbar journalise : index demande, index
precedent, route, etat d'overlay et horodatage. Un compteur discret `TAPS n`
confirme visuellement la reception du pointeur. Aucun diagnostic n'est affiche
dans une release production.

## Interactions cablees

- avatar du header : Profil ;
- carte Flow : `/flow` ;
- reprendre le cours : onglet Apprendre ;
- carte Matiere : `/learn/subject/:subjectId` ;
- acces Quiz : onglet Quiz ;
- acces Compagnon : onglet Compagnon ;
- recommandation : onglet Apprendre ;
- defi quotidien : onglet Quiz ;
- progression : onglet Profil.

Le bouton Parametres sans destination a ete retire. Aucun callback vide n'a ete
conserve sur la homepage.

## Entree Auth

`has_seen_onboarding`, `has_authenticated_before` et la session Firebase sont
trois etats distincts.

- nouvelle installation : Onboarding puis Register ;
- onboarding deja vu sans ancienne session : Register ;
- session existante : accueil du role ;
- deconnexion ou session expiree apres une ancienne authentification : Login ;
- les sous-formulaires Register restent stables et ne bouclent pas.

`has_authenticated_before` est marque apres session existante, connexion ou
inscription reussie. Il n'est jamais efface lors de la deconnexion.

## Nom public

- Android production : `Intellia 237` ;
- Android staging : `Intellia 237 Staging` ;
- iOS configurations existantes : `Intellia 237` ;
- Web : `Intellia 237` ;
- Windows et macOS : `Intellia 237`.

Les schemes iOS staging restent a creer sur macOS/Xcode avant de pouvoir
garantir un nom iOS staging distinct. Aucun faux scheme n'a ete ajoute.

Les identifiants historiques Android et Firebase de production sont preserves
sans modification. Les identifiants staging restent egalement inchanges.

## Verification du build

Le Profil affiche uniquement en staging/debug la version, le numero de build,
le flavor et le commit court lorsqu'il est injecte avec
`--dart-define=GIT_COMMIT=<sha>`.

Pour un test telephone fiable :

1. desinstaller completement l'ancienne variante staging ;
2. installer `build/app/outputs/flutter-apk/app-staging-debug.apk` ;
3. verifier Nouvelle installation, Accueil Eleve, Deconnexion et cold start ;
4. confirmer que le compteur de taps augmente sur chacun des cinq onglets.

## Tests de non-regression

- taps reels au centre des cinq items de navbar ;
- inspection de `HitTestResult` ;
- tour non vu mais overlay absent ;
- tailles 360x800, 390x844 et 430x932 ;
- facteur texte 1,3 et SafeArea basse importante ;
- Retour Android depuis un onglet secondaire ;
- navigation des cartes de homepage ;
- quinze cas de redirection Auth ;
- liens visibles Register/Login ;
- persistance de l'historique Auth apres deconnexion.

Resultats executes localement :

- format Dart : succes, 236 fichiers inchanges ;
- analyse `lib/` : succes, aucune anomalie ;
- analyse `test/` : succes, aucune anomalie ;
- `flutter analyze --no-pub` global : timeout local apres 15 minutes sans
  sortie ;
- tests Flutter : succes, 84 tests ;
- Functions : succes, 21 tests et build TypeScript ;
- audit npm high/critical : succes, vulnerabilites moderees uniquement ;
- Firestore Rules : succes, 15 tests ;
- Storage Rules : succes, 8 tests ;
- controle des references de marque : succes.

APK staging :

- chemin : `build/app/outputs/flutter-apk/app-staging-debug.apk` ;
- horodatage : 28 juin 2026 a 11:24:48 ;
- SHA256 :
  `DC750F6A9D5955CFF77C7C1635C859DE3404D9B98A70C0DE13DC3DD63427F62B` ;
- label compile : `Intellia 237 Staging` ;
- application ID staging confirme.

APK production :

- chemin : `build/app/outputs/flutter-apk/app-production-debug.apk` ;
- horodatage : 28 juin 2026 a 11:27:39 ;
- SHA256 :
  `29CEF9DD6E86B7C7858C0088935B739F77AF4D5F90B5D2355B1E981A3180A9B4` ;
- label compile : `Intellia 237` ;
- application ID historique de production confirme.

Aucun telephone ni emulateur Android n'etait disponible. La checklist manuelle
reste donc obligatoire avant fusion.

## Risques restants

- validation obligatoire sur un telephone Android reel ;
- future refonte du tour en couche non modale ;
- finalisation des schemes iOS staging sur macOS/Xcode ;
- aucun deploiement Firebase ni changement de donnees production n'a ete fait.
