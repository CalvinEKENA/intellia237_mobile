# TERMINALE D — GAME MAP (post-release +39)

## Inventaire avant la première vague

Sept packs canoniques présents avant récupération SVT : 39 blueprints, **7 jeux
jouables**, **32 drafts**. Le statut JSON seul n'est pas suffisant : le parseur
exige aussi un moteur connu et des niveaux. Les contenus publiés à distance
sans copie locale ne sont pas inventoriés comme s'ils avaient été téléchargés.

| Matière réellement embarquée pour D | Chapitres | Jouables / blueprints | Lacunes et concepts difficiles | Proposition |
|---|---|---|---|---|
| Mathématiques | Arithmétique ; Nombres complexes ; Fonctions | 7/19, tous les 7 en Arithmétique | Complexes et fonctions : aucun jeu actif | P1 plan complexe à coordonnées ; graphe paramétrique |
| Physique C-D | Erreurs/incertitudes ; Dimensions | 0/10 | Confusion grandeur/dimension/unité, erreurs de mesure | P0 laboratoire d'associations unités/grandeurs ; P1 assemblage dimensionnel |
| Anglais Terminale (toutes séries) | Passport ; Recreational activities | 0/10 | Vocabulaire administratif, lecture et expressions contextualisées | P0 Document Dash ; P1 phrases à reconstruire |
| SVT D | S1 Échanges cellulaires en production sourcée dans cette mission | 0 avant cette mission | États cellulaires et mécanismes de transport | P0 liens membranaires ; P1 labo osmotique qualitatif sourcé |

Les autres matières du programme scolaire peuvent être visibles dans le
catalogue académique. Cela ne constitue pas un pack disponible et ne justifie
pas la création de jeux sans sources. Les compteurs ci-dessus sont le **socle
avant ajout**, pas un état final après production SVT.

Moteurs existants : `grouping`, `place_value`, `modular_clock`, `factor_forge`,
`tiling`, `remainder_zone`, `integration_mission`. Les six premiers génèrent
des énigmes arithmétiques manipulables ; le dernier reprend des questions
d'intégration et ne suffit pas à diversifier les autres matières.

## Bibliothèque de mécaniques

| Mécanique | État/réemploi | Utilité et limite |
|---|---|---|
| Classer | P1 moteur de catégories | Biologie, erreurs physiques ; tap équivalent au déplacement |
| Relier | **P0 MatchingGameEngine**, une table de paires par manche | Relier plusieurs cartes indépendantes, correction de chaque erreur |
| Reconstruire | P1 moteur de séquences | Protocole, raisonnement, phrase ; ordre légitime déclaré par source |
| Labo virtuel | P1/P2 | Variables et conséquence ; aucune équation scientifique inventée |
| Graphe interactif | P1 fonctions/complexes | Manipulation par curseurs et boutons, pas de drag obligatoire |
| Mission/cas | intégration existante, P1 scénarios | Décisions en chaîne, états et retours déclarés |
| Erreur à trouver | P1 | Localiser un pas invalide et comprendre sa correction |
| Duel de concepts | P2 | Justification ; pas un second QCM appelé jeu |
| Construction | arithmétique déjà active, P1 dimensions/langue | Assembler des éléments avec contraintes explicites |
| Simulation temporelle | P2 | Réservée aux sources donnant une évolution exploitable |
| Carte/schéma | P2 | Placement légendé, alternative tap |
| Chronométré | pas en P0 | Vitesse uniquement si elle entraîne une compétence réelle |
| Estimation | P1 | Prédiction d'ordre de grandeur avant le calcul |
| Prédiction | P1 labo | Prédire puis révéler un phénomène source-justifié |

## Catalogue proposé

| Priorité / jeu | Matière et chapitre | Concept / mécanique | Durée, difficulté | Évaluation et replay | Offline / assets / complexité / réemploi |
|---|---|---|---|---|---|
| **P0 Document Dash** | Anglais U1 Passport | vocabulaire : relier mots et définitions réelles du pack | 2–3 min estimées, 1–3 | exactitude au premier essai ; ordre différent au replay, aucune prime de vitesse | oui ; texte local ; moyenne ; moteur commun |
| **P0 Laboratoire des unités** | Physique M1S2 Dimensions | relier grandeurs et unités de base/dérivées | 2–3 min estimées, 1–3 | paires justes, erreurs et aide ; même maîtrise que le cours | oui ; texte/formules locales ; moyenne ; moteur commun |
| **P0 Liens membranaires** | SVT S1 | relier état/mécanisme et observation/source | 2–3 min estimées, 1–3 | correction spécifique ; pas de score sur données ambiguës | oui ; texte local ; moyenne ; moteur commun |
| P1 Adresse Complexe | Maths CH02 | fabriquer Re/Im dans le plan | 3 min, 1–3 | contraintes satisfaites et essais | oui ; CustomPainter ; moyenne ; graphe réutilisable |
| P1 Transformations de courbe | Maths CH03 | paramètre → courbe/propriété | 3–4 min, 1–3 | prédiction puis manipulation | oui ; CustomPainter ; élevée ; physique |
| P1 Détective des erreurs | Physique M1S1 | classer aléatoire/systématique et action | 3 min, 1–2 | justesse et correction | oui ; texte ; moyenne ; SVT |
| P1 Passive Forge | Anglais U1 | reconstruire une phrase passive | 2–3 min, 1–3 | séquence reconnue, variantes source-déclarées | oui ; tuiles texte ; moyenne ; protocoles |
| P1 Labo osmotique | SVT S1 | modifier le milieu, prédire l'état qualitatif | 3 min, 1–2 | prédiction source-backed ; pas de modèle numérique non fourni | oui ; CustomPainter ; élevée ; autres laboratoires |
| P2 Protocoles / schémas | sources S2+ validées ultérieurement | séquence + carte | selon source | exigences à fixer après extraction | oui ; assets seulement si nécessaires ; élevée |

Aucun listening n'est ajouté : cette première vague ne dispose pas d'assets
audio vérifiés pour ces unités.

## Contrat P0 avant implémentation

Le moteur d'association est piloté par `runtime.games[].rounds`. Une manche
déclare un ID stable, sa difficulté, sa notion, son objectif, ses paires
`id/left/right/explanation/source_anchor` et un indice éventuel. Références
source obligatoires. Des libellés de droite identiques rendent la paire
ambiguë : la manche doit être rejetée. Données invalides → draft, jamais une
manche à moitié corrigible. Ne pas compter ces paires comme des QCM du Quiz.

Interaction : choisir une carte gauche puis sa relation à droite ; une bonne
association est verrouillée, une erreur laisse essayer après retour explicatif.
Toutes les relations doivent être reconstruites, avec des ordres mélangés de
façon déterministe par graine de partie. Aucune réponse n'est liée à sa place.
Grand texte : colonnes adaptables/verticales ; labels lisibles ; couleurs
accompagnées d'icône et de texte ; zones tactiles de 48 dp ; pas de drag imposé.

Score pédagogique : nombre de relations réussies au premier essai / nombre de
relations ; nombre d'erreurs et aide explicitement signalés. Aucun bonus de
série ni chrono dans les nouveaux jeux. Une manche terminée sans erreur et sans
aide constitue une preuve objective. Les aides ne certifient pas un acquis.

Enregistrement : preuve de manche identifiée par
`game:<contentId>:<gameId>:<roundId>`, rattachée à la notion déclarée du pack,
dans le **même LearnerContentSnapshot/MasteryState** que l'entraînement. Ne pas
marquer artificiellement une question de Quiz existante comme répondue. Les
scores du jeu restent un bilan de partie, pas une nouvelle maîtrise parallèle.
La vue Parcours lit ensuite ce même instantané.

Tests : parseur/données invalides, associations correctes/fausses, répétition
de clic et preuve enregistrée une fois, aide sans acquis artificiel,
persistance par élève, 320/360/412/480 px × grand texte, Reduce Motion.

## Première vague livrée

Trois jeux passent par le moteur commun `matching` : Document Dash (9 relations),
Laboratoire des unités (10), Liens membranaires (9). Chacun propose trois
plateaux de difficulté progressive, soit 28 relations sur neuf plateaux. Le
formulaire anglais reste explicitement un exemple du cours, sans règle
administrative universelle. Les références SVT excluent les diagrammes ambigus.

Le catalogue compte désormais 40 blueprints : 10 jouables et 30 draft. Les
sept jeux arithmétiques précédents restent disponibles. Les durées ci-dessus
sont des objectifs de conception ; aucune durée observée n’est inventée.
Les jeux sont accessibles via les cartes pédagogiques et les leçons existantes.
Le bilan indique premier essai, erreurs et aide ; le replay change la graine
mais conserve les IDs. La preuve positive ne se cumule pas au replay. Une
complétion erronée produit une tentative négative ordinaire ; une partie aidée
reste un entraînement sans preuve. Le stockage local vérifie son écriture avant
d’afficher la confirmation et permet de réessayer en cas d’échec.
