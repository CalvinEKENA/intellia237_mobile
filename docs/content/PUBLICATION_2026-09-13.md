# Publication des contenus et inscription — 13 septembre 2026

## Diagnostic confirmé

La matière **SVT / Sixième** était publiée, mais la leçon **Influence du climat sur la production végétale** était en brouillon. Elle comportait trois sections et cinq questions. Son quiz d'entraînement et ses sept cartes FLOW étaient également en brouillon. Publier la matière ne publiait pas ses descendants.

Deux documents de chapitre avaient le même titre. Le premier était vide ; le second contenait la leçon. L'interface ne permettait pas de supprimer ces chapitres et le CRUD ancien supprimait uniquement certains documents parents, sans leurs descendants.

L'éditeur pouvait continuer à publier après un échec de sauvegarde ; une erreur de publication de la matière était également masquée. Des index de leçons vides pouvaient rester en cache cinq minutes.

L'inscription utilisait un catalogue national embarqué, distinct des dix établissements créés par le super administrateur. Le compte élève avait déclaré Vogt avec un identifiant de ce catalogue embarqué, sans rattachement à l'établissement réel.

Le compte enseignant correct est **contact@intellia237.fr**. Il est actif et rattaché au **Collège F.X VOGT**.

## Parcours à utiliser

1. Choisir la classe, la matière et le chapitre dans le Studio.
2. Rédiger une leçon, ou importer des pages de cours. L'import existant utilise le backend Gemini, configuré sur `gemini-3.8-flash`, pour préparer leçon, questions, exercices et cartes FLOW. Les résultats restent des brouillons à relire.
3. Ouvrir la leçon, vérifier son contenu et le public indiqué. **Enregistrer** conserve un brouillon invisible aux élèves ; sur une leçon déjà publiée, il actualise le contenu en ligne.
4. **Publier** met en ligne la leçon, son index, sa matière, ses quiz et ses cartes FLOW associés dans une seule transaction. Les réponses du quiz sont validées avant cette transaction.
5. Sans quiz/cartes importés associés, les questions du mini-quiz alimentent automatiquement un quiz d'entraînement et des cartes FLOW ; le résumé alimente une carte notion. Les identifiants sont stables : republier ne crée pas de doublon.

Un contenu créé seul, sans lien vers une leçon, reste géré dans sa rubrique du Studio. La publication d'une leçon n'approuve pas tous les brouillons de l'application.

Le super administrateur publie dans le programme commun. Un enseignant actif peut publier les leçons de son établissement avec leurs contenus associés. Le rattachement validé de l'élève détermine son accès aux contenus d'établissement. Choisir un établissement à l'inscription reste une déclaration et ne constitue pas, à lui seul, une autorisation d'accès aux données privées de l'école.

## Corrections livrées

- Les écrans enseignant de leçons et de quiz ouvrent désormais le Studio commun. L’ancien formulaire écrivait dans `lesson_assets`, hors du parcours Apprendre, et proposait une liste de classes limitée. Aucun document de cette ancienne collection n’a été trouvé pour le compte enseignant indiqué.
- Création de chapitres par serveur pour les enseignants : leur chapitre peut rejoindre une matière commune sans leur donner les droits de modification globale. Lecture des brouillons FLOW limitée à leur établissement côté serveur. Les nouvelles cartes conservent leur auteur pour permettre leur publication explicite.

- Publication transactionnelle côté serveur, avec validation des questions, des corrigés et des cartes FLOW ; erreurs affichées dans l'éditeur, double envoi bloqué.
- Suppression depuis les écrans des matières, chapitres et leçons, réservée au super administrateur, avec confirmation. Nettoyage récursif des descendants Firestore, des quiz/corrigés et des cartes FLOW associés. Les résultats et points historiques des élèves sont conservés.
- Détection des titres de chapitre déjà utilisés et protection contre le double clic du dialogue de création.
- Rafraîchissement du catalogue élève après changement des index ; chapitres sans leçon visible masqués ; compteurs tenant compte du public.
- Cartes FLOW rattachées à une matière Firestore reconnues grâce au libellé publié ; pagination consommée au-delà de la première page ; cache isolé par élève/établissement et vidé lorsque le fil est réellement vide.
- Correction et attribution de points des cartes FLOW publiées à partir de leurs documents serveur, avec contrôle de classe/établissement et protection contre les doubles récompenses.
- Corrigés de quiz compatibles avec les champs optionnels `null` émis par l'éditeur ; contrôle du public dans les API de lecture, correction et soumission.
- Liste d'inscription issue uniquement des établissements actifs créés par un super administrateur. Seuls identifiant, nom, ville et région sont retournés. Liste visible immédiatement, recherche par nom/ville, accents acceptés, état de chargement et bouton de nouvelle tentative.

## État de production

Les onze fonctions concernées ont été déployées dans `edunova-aabd1`, région `europe-west1` : `saveLessonPublication`, `deleteCatalogContent`, `listRegistrationEstablishments`, `submitFlowActivity`, `submitQuizAttempt`, `listPublishedQuizzes`, `getPublishedQuiz`, `checkTrainingQuizAnswer`, `recordLessonProgress`, `createCatalogChapter`, `listEditorialFlow`.

Après accord explicite de l'utilisateur, la leçon SVT, son quiz et ses sept cartes FLOW ont été publiés ensemble. Le chapitre vide en double a été retiré après vérification de l'absence de descendants. Les écritures ont utilisé des préconditions sur les versions des documents et une sauvegarde locale des données originales.

Le compte élève de test a été rattaché au Collège F.X VOGT, conformément à son choix existant et à l'établissement de l'enseignant indiqué par le super administrateur. `users` et `student_profiles` sont cohérents ; rôle, points et classe n'ont pas été modifiés. L'opération figure dans `establishment_changes`.

L'API d'inscription déployée renvoie les dix établissements attendus. Aucune donnée privée de direction n'est incluse.

## Vérifications

- 128 tests unitaires serveur réussis.
- 76 tests de règles et d'intégration réussis ; la suite de publication étendue à 9 tests a ensuite réussi, y compris les deux nouveaux chemins du Studio enseignant.
- Tests Flutter des parcours Apprendre, FLOW, inscription et du compositeur exécutés. Les trois défauts détectés dans la nouvelle liste d'établissements ont été corrigés, et les suites concernées relancées avec succès. Les tests ciblés finaux de recherche, rendu et pagination passent également.
- Compilation TypeScript réussie ; analyse Dart des fonctionnalités modifiées sans anomalie. Les 25 tests de permissions et les 16 tests du compositeur FLOW passent, dont la conservation de l’auteur enseignant.
- Compilation Android et vérification du bundle final : voir la livraison ci-dessous.
- Les sources exactes des 41 fichiers Dart modifiés ou ajoutés sont présentes dans le noyau de la compilation de production, y compris la dernière correction de l’auteur des cartes FLOW.
- Aucune réponse réelle au quiz et aucun point artificiel n'ont été enregistrés sur le compte élève de production pour les tests.

## Livraison Android

Version **3.2.1 (25)** : `build/app/outputs/bundle/productionRelease/intellia237-3.2.1-25.aab`.

Compilation Android réussie. Le manifeste du bundle confirme `com.edunova.app`, `versionName=3.2.1`, `versionCode=25`. Signature JAR vérifiée.

SHA-256 : `AF7F69B4F0A027BCCF2D90897D4030357F8EFDDCEA0B2E34ACCCC15EB384E420`.

Numérotation confirmée avec l’utilisateur : version Play actuelle 3.2.0 (24), puis 3.2.1 (25). Les anciens bundles locaux 26 et 27 n’ont pas été importés par cette tâche et ne consomment pas de numéro Play.

Le bundle est produit localement ; il n'a pas été envoyé au Play Store. La leçon publiée est disponible côté serveur dès maintenant. Les nouvelles commandes de publication/suppression et le nouveau sélecteur d'établissement nécessitent cette version de l'application. Sur l'ancienne version, fermer puis rouvrir l'application évite de conserver les anciens index en mémoire ; une reconnexion permet de recharger le rattachement d'établissement.
