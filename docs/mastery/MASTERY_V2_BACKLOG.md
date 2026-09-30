# Maîtrise V2 — pré-requis et backlog

Note du 21 septembre 2026 (`fix/release-hardening-sep2026`). **Aucun code de
maîtrise n’a été modifié** dans cette mission : la V1 « Encre & Tracé »
(`docs/mastery/IMPLEMENTATION.md`) reste le contrat en vigueur. Ce document
liste ce qui manque pour passer de « première lecture prudente » à une
estimation par compétence.

## Ce que les données permettent aujourd’hui

La V1 lit uniquement les documents `progress` de type `quiz`
(`quizId`, `subjectId`, `score`, `maxScore`, `updatedAt`), écrits par
`academicStateStore.writeQuizRewards`. Un document est **remplacé** à chaque
nouvelle tentative du même quiz : ce n’est pas un historique. La V1 produit
donc seulement `NO_EVIDENCE`, `EXPLORING` et `BUILDING`, sans pourcentage.

## Manques bloquants pour une V2

| Manque | Constat dans le code | Conséquence |
| --- | --- | --- |
| **Étiquetage des questions** | `QuizQuestion` (`lib/features/quiz/domain/quiz_question.dart`) n’a ni `chapterId`, ni `competencyId`, ni `difficulty` ; seuls le quiz porte un `difficultyLabel` libre (« Intermédiaire » par défaut) et le schéma serveur des quiz générés un `difficulty` easy/medium/hard | impossible d’agréger par chapitre ou compétence : une question réussie ne dit pas **ce** qu’elle prouve |
| **Historique des tentatives par question** | `quiz_attempts` n’est pas lu par le profil ; le résumé public (`quizAttemptHistoryCallable`) n’a ni `quizId` ni `subjectId` | pas de courbe dans le temps, pas de distinction premier essai / essais suivants |
| **Aides reçues** | le quiz ne trace pas si l’élève a demandé l’aide du compagnon avant de répondre | impossible de revendiquer une réussite autonome |
| **Parcours et activités** | les réponses Parcours (`submitFlowActivity`) et les nouvelles activités interactives (`ActivityOutcome`, envoyé au compagnon seulement) ne sont pas des preuves durables | à ne **pas** intégrer sans contrat : ce sont des entraînements, souvent avec indices |
| **`studyMinutesToday`** | lu par `firestore_parent_repository.dart` et `firestore_teacher_repository.dart`, affiché dans `teacher_class_detail_screen.dart`, mais **aucun écrivain** côté serveur (`functions/src` n’a aucune occurrence) | la valeur est toujours 0 : l’enseignant voit « 0 min aujourd’hui » pour tous. Champ mort à retirer de l’affichage ou à alimenter |

## Pré-requis, dans l’ordre

1. **Étiqueter le contenu** : `chapterId` et `competencyId` sur chaque
   question (Studio et import de pages de cours), avec un référentiel de
   compétences par matière et par classe. Sans cela, rien d’autre n’a de sens.
2. **Historique append-only** des réponses par question, écrit par le serveur
   au moment de la correction (`quiz_evidence/{studentId}/items`), avec
   `firstAttempt`, `assisted`, `competencyId`, `answeredAt`.
3. **Règles** : lecture par l’élève, le parent lié et l’enseignant de la
   classe ; écriture serveur seule. Tests d’émulateur comme pour `progress`.
4. **Moteur** : niveaux (pas de pourcentage), drapeaux « à revoir » par
   compétence, fenêtre temporelle explicite, seuil de preuves minimal.
5. **Écrans** : la V1 garde sa structure ; la V2 remplace le moteur, pas le
   récit.

## Hors V2

- Les points Parcours restent de la motivation, pas une preuve.
- Les notes officielles de l’établissement restent une section séparée.
- `studyMinutesToday` : décider avant la V2 s’il est retiré de l’écran
  enseignant (recommandé tant qu’aucun écrivain n’existe) ou alimenté par un
  agrégat serveur de sessions.
