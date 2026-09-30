# PARCOURS — VISUAL SYSTEM (post-release +39)

## Audit de l'existant

« Mon Parcours » est le fil pédagogique `features/flow/FlowScreen`, pas une
simple page de statistiques. Il conserve ses cartes, son classement et ses
gestes. Le Profil expose aussi une maîtrise par matière fondée sur des preuves
Quiz serveur. Ces deux lectures ne sont pas confondues.

| Donnée réelle | Source | Utilisation P0 / limite |
|---|---|---|
| Maîtrise par notion 0–100, essais, réussites, erreurs, difficulté | `LearnerContentSnapshot`, `MasteryState` local par élève | carte des chapitres et recommandations ; jeux ajoutés utilisent la même source |
| Progression matière/chapitre/leçon et seuil du pack | `subjectJourneysProvider`, `ConceptsProgress` | **visualisation majeure** : itinéraire de chapitres, états et anneaux |
| Dernière séquence ouverte | `learningRecentsProvider` | CTA de reprise |
| Séances Quiz terminées, setId, mode, score, total, date | `packQuizHistoryProvider` | heatmap et courbe d'un seul Quiz/mode ; maximum 30 entrées locales |
| Niveau, points vérifiés, points en attente, série | `FlowProgressState` | HUD existant, aucune conversion en score de maîtrise |
| Objectif hebdomadaire, jours actifs | `personalGoalControllerProvider` | séances/jours actifs enregistrés ; minutes visées, jamais une durée mesurée |
| Maîtrise estimée sur preuves serveur | `studentMasteryProvider` | reste dans le Profil, échelle qualitative ; pas un pourcentage de programme |
| Lecture/cartes déjà vues | `learningCardHistoryProvider` | confort du fil existant ; ne prouve pas temps d'étude ni acquis |
| Temps d'étude, historique complet de maîtrise | absent de ce contrat local | **aucune courbe de maîtrise historique ni durée inventée** |

Aujourd'hui les chapitres et leur statut existent surtout dans Apprendre ;
le HUD du Parcours montre des points/niveaux mais ne donne pas la carte des
notions et des chapitres. L'historique local des Quiz est utilisable sans réseau.

## Composition P0

Une commande « Mon avancée » dans le HUD de Mon Parcours ouvre une feuille
scrollable. La fermer retrouve la même carte. Accès également disponible quand
le fil ne contient pas de carte, afin de ne pas cacher une progression en cache.

1. Identité réelle + classe et objectif hebdomadaire déclaré.
2. **Carte du parcours** par matière disponible : timeline de chapitres,
   état explicite (à commencer/en cours/acquis/à revoir), anneau proportionné
   aux notions au seuil, libellé du dénominateur, action vers la vraie leçon.
3. **Régularité Quiz** : 14 jours, comptes de séances terminées dans
   l'historique local, pas « jours d'étude ». Les zéros signifient aucune
   séance conservée sur cet appareil, pas absence de tout travail.
4. **Courbe Quiz comparable** : score/total d'un même `setId` **et mode**,
   ordre chronologique, sélection explicite. Pas de mélange entre matières,
   évaluations et entraînements de difficultés différentes.
5. À renforcer : maximum trois notions réellement travaillées sous le seuil
   (les auto-évaluations restent visibles dans le statut), lien concret vers leur leçon ; sinon première
   notion pas encore abordée. Ne pas fabriquer des erreurs historiques.

## Choix évalués

Anneaux + timeline sont retenus pour le P0 : ils donnent une position et une
prochaine action, avec des nombres vérifiables. La courbe des Quiz et la
heatmap réemploient des dates réellement persistées. Un radar exige des axes
de compétence fiables absents ici ; une constellation/orbite décorative
pourrait suggérer des relations de prérequis non déclarées. Montagne,
simulation permanente, vidéo de statistiques et shader ne sont pas retenus.

P1 : graphe de notions uniquement après déclaration de relations dans les
packs ; détails des résultats de jeux et comparaison de tentatives.
P2 : courbe de maîtrise dans le temps uniquement après une vraie collecte de
snapshots datés, avec distinction des notions et de leurs seuils.

## Rendu / accessibilité / performance

Flutter natif + `CustomPainter` pour les arcs et la courbe, cellules natives pour la heatmap. Pas de dépendance,
vidéo, image distante, LLM ou token. Le texte reste des widgets : tout visuel a
un équivalent lisible, un état explicite et des labels de lecteur d'écran.

Une seule interpolation courte (≤ 400 ms) par variation de valeur, aucun
ticker permanent. Reduce Motion : valeurs finales immédiatement, aucune
animation de données, aucun délai. Vue étroite : une matière/section par ligne,
chapitres empilés ; graphe à largeur contrainte, légende en dehors des pixels.
Les feuilles respectent le grand texte et gardent fermeture/CTA accessibles.

Vérifications : sources manquantes/en erreur/hors ligne, absence de fausse
activité, quiz de modes différents séparés, prochains CTA réels, 320/360/412/
480 px et texte ×1,5, absence d'overflow, lecture statique en Reduce Motion et
absence de boucle après la fin des micro-animations. Les tests de widgets ne
prétendent pas remplacer une mesure de FPS sur Android physique.

## P0 livré

La carte des chapitres est accessible depuis le HUD du fil et son état vide.
Elle garde le pager monté ; sa fermeture conserve la carte courante. Les CTA
ouvrent une leçon réelle du chapitre affiché. L’anneau mesure le nombre de
notions au seuil du pack, avec ce nombre écrit à côté. Deux micro-vues : la
heatmap des séances Quiz terminées des 14 jours et la courbe par ensemble de
Quiz et mode. Une seule observation affiche un résultat sans inventer de courbe.
L’axe horizontal correspond aux tentatives chronologiques, pas à une durée
d’étude. Aucune minute étudiée n’est déduite de la cible de l’élève.

Les nouvelles preuves de jeux passent dans `LearnerContentSnapshot` : la carte
et la prochaine étape les lisent avec les autres tentatives. Les indicateurs
serveur du Profil restent distincts et ne prétendent pas synchroniser ces
preuves locales. Les animations des arcs/courbes durent 350 ms ; la feuille
suit aussi Reduce Motion. Pas de ticker, vidéo ni requête LLM.

19 tests dédiés vérifient le calcul des données, la séparation des modes, les
CTA, les états vides/en erreur, la conservation du fil, la fin des animations et les largeurs 320/360/412/480 px en FR/EN, texte
×1,5. Capture vérifiée `build/post_release_39/parcours_412.png`, polices réelles
et données de test ; aucun gain de FPS chiffré n’est affirmé.
