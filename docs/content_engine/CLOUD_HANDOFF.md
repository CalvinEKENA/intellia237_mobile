# Handoff Cloud — Content Engine, Mon Parcours, Reward & Haptic (25/09/2026)

Branche : **`feat/content-engine`** (partie de `fix/auth-v2-final-rework`,
jamais fusionnée dans `main`). Ne pas merger sans accord du propriétaire.

Reprendre :

```bash
git fetch origin && git switch feat/content-engine && flutter pub get && flutter analyze
```

## Objectif

Transformer des packs JSON pédagogiques validés en expérience complète,
**sans aucun modèle de langage** : cours à 3 niveaux d'explication, visuels,
exercices corrigés de façon déterministe, jeux, Compagnon hors ligne,
maîtrise par notion, fil « Mon Parcours » pour toutes les classes, diffusion
de nouveaux chapitres sans reconstruire l'APK.

Documentation détaillée : `docs/content_engine/CONTENT_ENGINE.md` (moteur,
diffusion, publication, liste de vérification appareil) et
`docs/rewards/REWARD_ENGINE.md` (gratification et haptique).

## Architecture

| Zone | Emplacement |
|---|---|
| Classe + série | `lib/core/academics/class_key.dart` (`ClassKey`), `lib/features/learn/domain/learn_class_guard.dart` |
| Moteur | `lib/features/content_engine/{domain,data,engine,application,presentation}` |
| Diffusion distante | `data/content_delivery.dart`, `data/content_pack_cache*.dart`, `data/firebase_content_gateway.dart`, `domain/pack_catalog.dart` |
| Mon Parcours (packs) | `content_engine/feed/` (LearningCard, fabrique, historique, classement), `application/learning_feed_providers.dart`, `flow/domain/flow_card.dart` (`FlowLearningCard`), `flow/application/flow_controller.dart` (`flowComposedCatalogProvider`), `flow/presentation/widgets/flow_learning_card_view.dart` |
| Compagnon | `engine/companion_engine.dart`, `engine/companion_name_policy.dart`, `presentation/widgets/companion_sheet.dart` |
| Récompenses | `lib/features/rewards/`, pont `content_engine/application/reward_bridge.dart` |
| Serveur (non déployé) | `functions/src/services/contentAudience.ts`, `learningCatalogCallable.ts` |
| Publication | `tool/content/publish_pack.dart`, `tool/content/pack_bundle_builder.dart` |

### Filtrage ClassKey
Un contenu n'est montré que s'il **déclare** une classe (chapitre ou
matière) correspondant à celle de l'élève ; le chemin Firestore n'est jamais
une preuve. Cible sans série = toutes les séries ; `terminale-c-d` = C et D.
Cause de la fuite 6e → Terminale : anciens scripts d'amorçage
(`functions/seed_all.js`, `seed_courses.js`, import `c58a3fe`) ayant rangé
SVT et Anglais de 1er cycle sous Seconde/Première/Terminale sans classe.

### Diffusion distante, cache, retour arrière
Storage `content/catalog.json` + `content/packs/<id>/v<n>/bundle.json`.
Vérifs : statut publié, classe, version moteur minimale, sha256, identité,
jouabilité. Cache atomique, emplacements actif + précédent ; lecture :
distant actif → précédent → embarqué. Synchronisation à l'ouverture
d'Apprendre / Mon Parcours et par « tirer pour actualiser ».

### Mon Parcours
Même pager que le fil 6e (`flow_items`). Les packs de la classe produisent
14 types de cartes (fabrique déterministe, aucun texte rédigé) ; classement :
leçon en cours, remédiation après erreurs, révision espacée, variété.
Publications et packs s'entrelacent ; un nouveau pack s'insère après la
carte courante. Réponses → même `MasteryState` que S'entraîner.

### Compagnon 100 % sans LLM
Réponses tirées du pack uniquement ; hors pack : « pas encore disponible »
et notions proches. Test garde-fou : `test/features/content_engine/companion_no_llm_test.dart`.
**Aucun LLM ne doit être réintroduit dans le Compagnon runtime.**

### Jeux
Statut `ready` / `draft` / `disabled`. Moteurs : grouping, place_value,
modular_clock, factor_forge, tiling, remainder_zone (Zone du Reste),
integration_mission (Mission Awa).

### Reward & Haptic Engine (implémenté dans ce commit)
Niveaux ordinaire, progrès, série, niveau supérieur, récupération, défi,
maîtrise, chapitre ; anti-répétition, 25 s entre grandes animations ;
préférence « Vibrations pédagogiques » (activées / réduites / désactivées) ;
animations réduites respectées. Branché : S'entraîner, Mon Parcours,
jeux, correction des quiz. **Non vérifié sur appareil** (ressenti haptique
à valider sur Android réel).

## Validation

```bash
dart format --output=none --set-exit-if-changed lib test tool
dart run tool/check_brand_references.dart
dart run tool/user_facing_jargon_audit.dart
flutter analyze
flutter test
cd functions && npm test && npm run build
```

Derniers résultats (25/09/2026) : analyze 0 ; **1 893 tests Flutter** OK
(barrière complète) puis 53 tests ciblés après un dernier changement de
libellés ; Functions **430 tests** OK, build OK ; jargon 0 ; marque OK.

Tests clés : `test/features/content_engine/` (moteur, diffusion, matrice
responsive, fil, sans LLM), `test/features/flow/flow_pack_cards_test.dart`,
`test/features/learn/learn_class_guard_test.dart`, `test/features/rewards/`,
`test/content_packs/validate_packs_test.dart` (`CONTENT_PACK_DIR=<dossier>`).

## État des déploiements — RIEN n'est déployé

1. **Functions serveur codées mais non déployées** (garde de classe
   serveur : `declaresClass`, clause d'audience liée à la classe).
2. **`storage.rules` non déployé** (lecture `content/**` pour les
   utilisateurs connectés, écriture interdite).
3. **Aucun catalogue Content Engine publié** sur Storage.
4. **Six anciens contenus SVT/Anglais mal classés encore présents en
   production** (Seconde/Première/Terminale) ; masqués par la garde côté
   application, pas encore dépubliés (écriture production = accord requis).
5. Aucun APK/AAB de cette branche envoyé sur Play.

## Décisions produit prises
Classe déclarée obligatoire ; pas de second « Apprendre » ; pas de LLM au
runtime ; prénom avec parcimonie (règle partagée Compagnon / récompenses) ;
gratification discrète et premium, jamais de confettis ni d'arcade ; les
JSON des packs ne sont jamais corrigés en silence.

## Limites restantes
* **Apprendre encore partiellement unifié** : packs dans « Chapitres
  interactifs », pas encore dans la grille des matières.
* **Mathématiques Terminale D, CH01 à CH03 intégrés** (moteur v2,
  embarqués, bundles `draft` prêts dans `build/content_publish/`, rien
  téléversé). Jeux de CH02/CH03 en préparation (aucun moteur) ; 11 réponses
  rédigées non notées. Détail : section dédiée de `CONTENT_ENGINE.md`.
* Fil des packs plafonné à 60 cartes par composition.
* Aucune vérification sur appareil de cette branche.

## Prochaines tâches recommandées
1. Vérification Android (liste en fin de `CONTENT_ENGINE.md`), y compris
   ressenti haptique et animations réduites.
2. Avec accord : déployer Functions + `storage.rules`, dépublier les 6
   contenus mal classés.
3. Publier le premier catalogue (avec accord) via
   `tool/content/publish_pack.dart`, puis CH04 et suivants par le catalogue.
4. Unifier la grille Apprendre (matières Firestore + packs).

Ne jamais committer `delete_test_user.cjs` (script d'administration local)
ni aucun secret : le dépôt est public.
