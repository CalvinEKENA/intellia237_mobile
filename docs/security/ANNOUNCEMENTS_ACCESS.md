# Annonces — accès en lecture et plan de transition

État au 22 septembre 2026, branche `fix/release-hardening-review-fixes`.
Rien n’est déployé : ces règles s’appliqueront au prochain déploiement des
règles Firestore.

## Constat (revue indépendante)

`match /announcements/{announcementId}` autorisait `read` à **tout compte
connecté**. L’app analysée comme production (`7521a94`, `3.0.0+22`) lit les
annonces **sans nommer l’école** :

| Écran (version en production) | Requête |
| --- | --- |
| Tableau de bord administration | `orderBy('publishedAt', desc).limit(5)` |
| Tableau de bord parent | `orderBy('publishedAt', desc).limit(5)` |
| Tableau de bord enseignant | `where('createdBy', == uid).limit(5)` |

Conséquence en production : un administrateur ou un parent voit les cinq
dernières annonces **toutes écoles confondues**, et n’importe quel compte
connecté (même sans profil) peut lire toutes les annonces.

## Classement des annonces

| Classe | Définition | Audiences |
| --- | --- | --- |
| GLOBAL | n’existe pas : toute annonce porte un `establishmentId` (règle de création) | — |
| ÉTABLISSEMENT | publiée par l’administration de l’école ou la super-administration | « Tout l’établissement », « Élèves », « Parents », « Enseignants », « Administration » |
| CLASSE | publiée par un enseignant affecté à la classe | « Classe » + `classId` |

## Phase 1 — ce cycle (compatible avec l’app en production)

| Lecteur | Lit |
| --- | --- |
| Super-administration | tout |
| Enseignant actif | les siennes ; dans son école : « Tout l’établissement », « Enseignants », « Classe » d’une classe qu’il encadre |
| Élève | dans son école : « Tout l’établissement », « Élèves », « Classe » de sa classe |
| Administration d’école | **transition** : tout, comme avant |
| Parent | **transition** : tout, comme avant |
| Compte sans rôle, profil incomplet, personnel inactif, non connecté | rien |

Pourquoi l’administration et les parents restent ouverts : dans Firestore,
une règle qui dépend du contenu du document refuse **en bloc** une requête qui
ne contraint pas ce contenu. Les requêtes non filtrées de la version installée
échoueraient, et avec elles tout le tableau de bord (les annonces y sont
chargées avec le reste). Les requêtes enseignant de la version installée
(`createdBy == uid`) restent servies par la branche « les siennes ».

Ce qui est fermé dès ce cycle : lecture d’une autre école par un élève ou un
enseignant, lecture des annonces non destinées à leur rôle, lecture par un
compte sans rôle ou inactif.

**Risque résiduel de la phase 1** : un administrateur d’école, ou toute
personne qui crée un profil parent (la création `parent` est ouverte aux
clients), lit encore les annonces de toutes les écoles.

L’app de cette branche borne déjà chaque requête à l’école (administration :
son école ; parent : l’école de chacun de ses enfants ; enseignant : son école
et ses propres annonces).

## Phase 2 — après retrait des versions installées

Préalables :

1. publication de la nouvelle app, puis version minimale imposée : les
   versions qui interrogent sans nommer l’école (dont `7521a94`, version
   `3.0.0+22`) n’ouvrent plus les tableaux de bord. Le numéro exact de la
   version aujourd’hui publiée est à relever dans la Play Console : il n’est
   pas vérifiable depuis le dépôt ;
2. pour les parents : appartenance aux écoles des enfants **écrite par le
   serveur** (par exemple `parent_access/{parentId}.establishmentIds`, mise à
   jour à l’approbation d’un lien et lors du changement d’école d’un enfant),
   ou lecture des annonces uniquement par les notifications déjà distribuées
   aux parents liés.

Règle cible :

| Lecteur | Lit |
| --- | --- |
| Super-administration | tout |
| Administration active | son école, toutes audiences |
| Enseignant, élève | inchangés (phase 1) |
| Parent | écoles de ses enfants approuvés : « Tout l’établissement », « Parents » |

## Tests

`functions/src/__tests__/rules/firestore.rules.test.ts`, bloc « announcements
follow their real audience » : tests négatifs d’une école à l’autre (élève,
enseignant), audiences par rôle, personnel inactif et compte sans rôle, et
**requêtes exactes de la version en production** maintenues. Les tests
négatifs échouent sur l’ancienne règle `isAuthenticated()`.
