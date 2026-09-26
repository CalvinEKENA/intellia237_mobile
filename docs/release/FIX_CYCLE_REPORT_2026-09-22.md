# Cycle de corrections après la revue indépendante — 22 septembre 2026

**Rien n’a été déployé.** Aucun `firebase deploy`, aucune commande `gcloud`
exécutée, aucun APK ni AAB, aucun envoi Play, version inchangée
(`3.2.1+30`). `GEMINI_TUTOR_THINKING_LEVEL=HIGH` et le plafond de sortie
(8 192) inchangés.

## Identité

| | |
| --- | --- |
| SHA source (revu par Gemini) | `11eb26cfe53d7291886b6c3a45e70d5eb5ff8927` (`fix/release-hardening-sep2026`) |
| Branche | `fix/release-hardening-review-fixes` |
| SHA final | le commit de ce rapport (tête de la branche) ; dernier commit de correction : `61bc434` |
| Diff | 35 fichiers de code, tests et documentation avant ce rapport, +2 686 / −142 |

## Corrections préalables au rapport Gemini

| Point du rapport | Vérification | Conclusion |
| --- | --- | --- |
| Projet de production `aureon-7ac27` | `.firebaserc` (`default` et `production` = `edunova-aabd1`, `staging` = `intellia237-staging`), `lib/firebase_options.dart`, Studio, `functions/src/config/env.ts` ; aucune occurrence d’`aureon` dans le dépôt | **Erroné.** Production = `edunova-aabd1`. Rien remplacé ; test ajouté (`81db5ff`) |
| Demandes de suppression `pending` « orphelines » | décision propriétaire | **Voulu.** Non migrées, jamais traitées ; verrou renforcé (`35b0ad8`) |
| Google réservé aux élèves et parents | lecture de la règle d’auto-inscription et d’une ligne mal étiquetée du rapport QA | **Corrigé dans la doc** (`a6984e1`) : Google est une méthode d’accès pour tous, jamais un rôle |
| Parcours d’authentification simple car « téléphone → code » | audit depuis le premier écran | **Maintenu** : refonte au backlog immédiat |

## Statut des blocages

Le rapport Gemini n’est pas versionné dans le dépôt : la correspondance
BLK ci-dessous suit l’ordre des sections 2 à 6 de la mission et reste à
confirmer par le propriétaire.

| BLK | Sujet | Statut | Commit |
| --- | --- | --- | --- |
| BLK-01 | CI : références de marque dans l’inventaire des ressources | **CORRIGÉ** (documentation seule, vérificateur inchangé) | `f9ff179` |
| BLK-02 | Parcours : cartes terminées perdues dans les pages 2+ | **CORRIGÉ** (fusion matérialisée une seule fois) | `2c578c2` |
| BLK-03 | Quota : question à cheval sur minuit non décomptée | **CORRIGÉ** (la réservation porte sa journée) | `1358e54` |
| BLK-04 | `tutor_requests` sans politique TTL | **PRÉPARÉ, NON DÉPLOYÉ** (TTL versionné dans `firestore.indexes.json`, invariant `expireAt` garanti) | `9270c4e` |
| BLK-05 | Réflexion HIGH + plafond de sortie : réponses inutilisables | **CORRIGÉ** (aucun débit sans réponse utilisable livrée, plafond anti-abus) | `185fd50` |

## Détail

### BLK-02 — Parcours

`flow_screen.dart` parcourait deux fois un itérable paresseux dont le filtre
ajoutait les identifiants à `known` : au second passage, les cartes déjà
terminées de la page suivante étaient toutes écartées. `mergeFlowNextPage`
lit la page une seule fois : doublons ignorés, nouvelles cartes avant les
cartes terminées (jamais avant la carte affichée), cartes terminées en fin
de fil dans l’ordre reçu. Test d’écran page 1 + page 2 + terminées +
doublon : **8 cartes sur l’ancien code, 10 après** ; tests unitaires de
l’ordre.

### BLK-03 — Quota à minuit

`reserve` renvoie `dayKey` ; `askTutor` le conserve pendant tout l’appel ;
`consume`, `release` et le règlement d’une issue non livrée agissent sur ce
seau. L’élève voit toujours sa journée en cours. Tests émulateur avec
horloge injectée : réservation 23:59:59 / débit 00:00:01, J/J, débit rejoué,
libération après minuit, et `askTutor` de bout en bout (**0 au lieu de 1 sur
l’ancien code**).

### BLK-04 — TTL de `tutor_requests`

- `firestore.indexes.json` : `fieldOverrides` `tutor_requests.expireAt`,
  `ttl: true`, `indexes: []`. Pris en charge par firebase-tools 15.16.0 (la
  version de la CI) ; ne prend effet qu’au déploiement des index.
- `complete()` et `fail()` utilisent `update` : un document disparu n’est
  jamais recréé sans `expireAt` (**le test correspondant échoue sur l’ancien
  code**).
- Documentation : le TTL Firestore est asynchrone (en général sous 24 h
  après l’échéance) ; un document n’est jamais supposé disparaître exactement
  après 15 minutes.

Commandes futures, **NON EXÉCUTÉES**, à lancer par le propriétaire depuis la
racine du dépôt :

```bash
firebase deploy --only firestore:indexes --project edunova-aabd1
```

Si l’outil propose de supprimer des index présents dans le projet mais
absents du fichier : répondre **non**. Équivalent sans le fichier d’index :

```bash
gcloud firestore fields ttls update expireAt --collection-group=tutor_requests --enable-ttl --project=edunova-aabd1
```

Vérification :

```bash
gcloud firestore fields ttls list --project=edunova-aabd1
```

### BLK-05 — Réponses inutilisables, troncature

Principe propriétaire : sans réponse utilisable livrée, la question n’est pas
une question réussie. Coût fournisseur ≠ débit visible par l’élève.

| Issue | Élève reçoit | Quota | Réserve d’étude |
| --- | --- | --- | --- |
| Réponse complète (avec ou sans activité valide) | la réponse | décompté | usage réel débité |
| Texte utile + activité invalide | le texte seul | décompté | débité |
| Coupée au plafond (`MAX_TOKENS`), texte non vide | le texte + « Ma réponse a été coupée : écris « la suite » pour que je continue. » (EN équivalent), sans activité incomplète | **non décompté** | **non débitée** |
| Texte vide, activité seule invalide, réponse inexploitable | erreur `unavailable` à relancer | **non décompté** | **non débitée** |
| Délai fournisseur dépassé | erreur `deadline-exceeded` | **non décompté** | rien à débiter |
| Au-delà de 3 issues non livrées dans la journée | idem | décompté | usage réel débité |

L’usage fournisseur de chaque issue non livrée est journalisé
(`Tutor answer not delivered as a complete answer.`, sans contenu). Une
facturation Vertex AI déjà faite n’est pas annulée : elle n’est pas imputée à
l’élève. Plafond : `TUTOR_FREE_UNDELIVERED_ANSWERS_PER_DAY = 3`, compteur
`undeliveredCount` dans le document quotidien. Quatre tests qui fixaient
l’ancienne politique ont été réalignés ; une relance d’une question non
livrée reste décomptée **une seule fois**.

## Annonces

Classement : ÉTABLISSEMENT (audiences d’école) et CLASSE ; aucune annonce
globale. Phase 1 appliquée (`042e50f`) :

- fermé : lecture d’une autre école par un élève ou un enseignant, lecture
  des audiences non destinées au rôle, lecture par un compte sans rôle, un
  profil incomplet ou du personnel inactif ;
- **maintenu ouvert (transition)** : administration d’école et parents, car
  l’app installée (`7521a94`, `3.0.0+22`) lit
  `orderBy(publishedAt).limit(5)` sans nommer l’école ; toute condition sur
  le document ferait échouer la requête et le tableau de bord entier.

Statut : **PARTIELLEMENT CORRIGÉ**. Risque résiduel : un administrateur
d’école, ou toute personne qui crée un profil parent, lit encore les
annonces de toutes les écoles. Phase 2 et préalables :
`docs/security/ANNOUNCEMENTS_ACCESS.md`. Tests : 5 négatifs (échouent sur
l’ancienne règle) + requêtes exactes de l’app installée maintenues.

## Décision propriétaire préservée — suppression de compte

**OWNER DECISION : legacy pending deletion requests remain
manual/non-executing.** Planificateur inchangé ; `pending` absent des statuts
traitables (test unitaire) ; demande `pending` avec échéance passée ignorée
et intacte (test émulateur) ; remplacement par une nouvelle demande
explicite conservé. Aucune migration vers `scheduled`.

## Compatibilité de déploiement

| Combinaison | État |
| --- | --- |
| Ancienne app + nouveau serveur | **OK**, verrouillé par `askTutorLegacyAppContract.test.ts` (charges utiles exactes de `7521a94`, alias, historique maximal, réponse coupée non vide, erreur déjà gérée) et par les requêtes d’annonces de l’app installée |
| Nouvelle app + ancien serveur | cassé (inchangé) : l’ancien `askTutor` exige `tutor` |
| Nouvelle app + nouveau serveur | OK |

Ordre futur inchangé : serveur compatible d’abord, validation, application
mobile ensuite.

## Autres corrections

- Isolation des environnements (`81db5ff`) : un runtime de production refuse
  Vertex et Storage de staging ; la configuration du dépôt ne cite que les
  deux projets connus ; remplacer l’ID de production dans `env.ts` fait
  échouer trois tests. Aucun changement de code.
- Vouvoiement du dialogue d’administration « Ajouter un élève » (`88fc92f`) :
  « Retrouvez-le avec la recherche. », « Créez son compte… », « Vérifiez
  l’adresse e-mail. ».
- Architecture d’identité (`a6984e1`) : Google = méthode d’accès pour parent,
  élève, enseignant, dirigeant ; jamais d’attribution de rôle ; multi-rôle
  préparé (trois options, audit de migration requis) ; entrée cible
  maintenue.

## Vérifications locales équivalentes à la CI

Exécutées une à une sur la branche (dernier commit de correction `61bc434`),
émulateurs du projet `demo-intellia237` :

| Vérification | Résultat |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 645 fichiers, 0 modifié |
| `flutter analyze` | aucun problème |
| `flutter test` | **1 556 / 1 556** |
| `dart run tool/check_brand_references.dart` | réussi |
| Functions `npm test` (vitest) | **375 / 375** (45 fichiers) |
| Functions `npm run build` (`tsc`) | propre |
| Règles Firestore / Storage / ressources | 67 / 9 / 16 |
| Intégration : famille, réserve d’étude, annonces, suppression, Parcours, comptes admin, publication, tuteur (quota + registre) | 17 / 8 / 4 / 8 / 6 / 4 / 9 / 13 |
| Studio : format, `flutter analyze`, `flutter test` | 74 fichiers inchangés, aucun problème, **55 / 55** |

Nouveaux tests de ce cycle : Parcours page 2+ (écran + 5 unitaires),
quota à minuit (5 émulateur), règlement des issues non livrées (3
émulateur), contrat `expireAt` (5 émulateur + 2 unitaires), réponses non
livrées ou coupées (8), annonces (7 émulateur, dont 5 négatifs), suppression
`pending` (1 unitaire + 1 émulateur), charge utile de l’app installée (6),
identité des projets (6). Chaque correctif de comportement a été vérifié en
contre-épreuve : le test échoue sur l’ancien code.

La CI distante n’a pas tourné sur cette branche : elle n’est pas poussée.

## Éléments à déployer plus tard

| Élément | Raison | Changement de ce cycle |
| --- | --- | --- |
| Functions (depuis cette branche) | `askTutor` : journée de réservation, issues non livrées, registre | `askTutorUseCase.ts`, `llmClient.ts`, `studyReserveConsumption.ts`, `tutorDailyQuota.ts`, `tutorRequestLedger.ts` |
| Règles Firestore | lecture des annonces phase 1 | `firestore.rules` |
| Index Firestore + TTL | `tutor_requests.expireAt` (et les deux index composites du cycle précédent) | `firestore.indexes.json` |
| Application mobile | Parcours page 2+, textes d’administration | `flow_page_merge.dart`, `flow_screen.dart`, ARB |
| Studio | aucun changement dans ce cycle | — |

Ordre et préalables inchangés (`docs/release/OWNER_QA_GATE_2026-09-21.md`,
section 3) ; ajouter le TTL avec les index.

## Risques restants

- Annonces : administration d’école et parents encore ouverts (phase 2).
- Plafond anti-abus : jusqu’à 3 issues non livrées gratuites par élève et par
  jour ; coût fournisseur correspondant non imputé.
- Réponses coupées : livrées sans être décomptées, dans la même limite ; la
  part de `MAX_TOKENS` reste à mesurer en recette.
- TTL asynchrone ; inexistant tant que les index ne sont pas déployés.
- Toujours ouverts depuis la revue : QA-05 (aucun environnement de recette
  de bout en bout), QA-08 à QA-12, App Check non imposé, multi-rôle, Google
  Sign-In, refonte de l’entrée.
- Ordre de déploiement imposé par `askTutor` (nouvelle app après serveur).

## Verdict

Les cinq blocages sont corrigés ou préparés sans déploiement, le point
annonces est corrigé en phase 1 avec un risque résiduel documenté, les
décisions du propriétaire sont préservées, la compatibilité ancienne app +
nouveau serveur est verrouillée par des tests, et toutes les vérifications
locales équivalentes à la CI passent.

READY FOR SECOND INDEPENDENT REVIEW
