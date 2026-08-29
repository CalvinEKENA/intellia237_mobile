# Confidentialité des corrigés de quiz

## Contrat de stockage

- `quizzes/{quizId}` contient uniquement les métadonnées et les questions
  publiques : énoncé, options, mode et nombre de points.
- `quiz_answer_keys/{quizId}` contient les réponses attendues et les
  explications. Cette collection est inaccessible aux élèves et parents ; seuls
  les comptes du personnel actifs peuvent l'utiliser dans les écrans d'édition.
- Les nouveaux enregistrements administrateur et enseignant écrivent les deux
  documents dans un même batch.

Les anciens quiz contenant encore un corrigé dans `quizzes` restent corrigeables
côté serveur durant la transition. Les règles Firestore interdisent désormais
leur lecture directe par un élève, ce qui empêche cette compatibilité temporaire
de devenir une fuite.

## Contrat élève

Le client élève n'interroge plus directement `quizzes` :

- `listPublishedQuizzes` renvoie seulement les métadonnées nécessaires au hub ;
- `getPublishedQuiz` renvoie les questions via une projection en liste blanche ;
- `submitQuizAttempt` reçoit toutes les réponses en une fois, calcule le score
  côté serveur et renvoie ensuite le corrigé ;
- `checkTrainingQuizAnswer` est disponible uniquement pour un quiz déclaré en
  mode `training`. Il ne crédite aucun point.

La projection publique ignore explicitement `correctOptionIndex`,
`correctBooleanValue`, `acceptedAnswers`, `explanation` et toute future donnée
non autorisée, même si un ancien document les contient.

## Modes et réseau

- **Examen** : aucune vérification intermédiaire ; une seule callable est
  effectuée à la fin de la tentative.
- **Entraînement** : l'élève peut demander la correction de la question avant de
  continuer. En cas de réseau instable, sa réponse reste en mémoire et il peut
  réessayer ou avancer sans correction immédiate. La soumission finale groupée
  reste l'unique source du score et des points.

Les métadonnées et questions publiques déjà reçues sont conservées localement
pendant quatorze jours afin de permettre l'ouverture du quiz en connexion
dégradée. Aucun corrigé n'est placé dans ce cache. Après une première tentative
de soumission, l'identifiant et le payload restent stables : un retry réseau
rejoue donc la même opération sans créditer une seconde fois les points.

## Ordre de mise en production

1. Déployer les Functions de lecture filtrée et de correction.
2. Publier l'application utilisant les nouvelles callables.
3. Après adoption ou mise à niveau obligatoire, déployer les règles Firestore
   qui bloquent la lecture directe des quiz par les élèves.
4. Réenregistrer ou migrer les éventuels anciens quiz afin de déplacer leurs
   corrigés vers `quiz_answer_keys`.

La bascule de l'étape 3 doit être coordonnée avec la disponibilité de la nouvelle
application : une ancienne version tente encore une lecture directe et doit donc
être mise à niveau avant l'activation de la règle restrictive.
