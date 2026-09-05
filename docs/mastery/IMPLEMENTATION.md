# Encre & Tracé — contrat de la V1

Base auditée : `7521a94eebd1e59b5439ea608700a4cc16215a3f`.
Développement exclusivement dans `Intellia237_mastery`, branche
`feat/mastery-profile-encre-trace`. Aucun changement serveur, de règles,
d’authentification, de route racine ou de bootstrap global.

## Ce que le code existant permet réellement

| Domaine | Contrat vérifié au commit de base | Conséquence pour la V1 |
| --- | --- | --- |
| Profil élève | `_ProfileTab` dans `student_home_screen.dart`, identité, classe, compagnon et statistiques | Remplacé par `StudentProfileTab`, identité puis apprentissage par matière |
| Profil parent | `parent_home_screen.dart`, `child_overview_screen.dart`, `child_progress_screen.dart` | Les trois surfaces utilisent un récit parent distinct |
| Parcours élève | `learnHubProvider` → `LearnSubject.chapters[].completion`, construit depuis `lessonProgress` | Nombre de chapitres comportant une exploration ; jamais une preuve de compréhension |
| Ancien calcul parent | `FirestoreParentRepository._computeProgress` classait les matières fortes/faibles à partir des leçons consultées | Déduction supprimée ; champs historiques conservés, listes désormais vides |
| Tentatives | `QuizAttempt` envoie les réponses ; `QuizAttemptSummary` ne conserve pas `subjectId` | Le modèle d’historique n’est pas détourné pour une jointure par libellé |
| Historique public | `quizAttemptHistoryCallable.ts` renvoie un résumé sans `quizId` ni `subjectId` | Insuffisant pour agréger par identifiants stables |
| Correction | `quizScoring.ts` compte les réponses correctes ; `academicStateStore.ts` écrit le résumé dans `progress` | Seule source d’estimation utilisée |
| FLOW | `FlowPointsResult` contient `correct` et `cardId`, avec une validation serveur et une file hors ligne ; aucun historique durable de preuves par matière exploitable par ce profil | Aucune carte vue, aucun point, aucune réponse locale ou en attente n’entre dans l’estimation |
| Entraînement | `checkTrainingAnswer` renvoie une correction mais n’établit pas un historique durable distinct | Pas d’agrégation des réponses individuelles |
| Classe | `LearnAcademicContext`, `AcademicLevelIdentity`, `AcademicPassport` | Classe affichée depuis le modèle existant ; catalogue résolu par sa clé existante |
| Matière | Identifiant documentaire `LearnSubject.id`, également écrit comme `subjectId` par le serveur | Égalité exacte des identifiants ; aucune inférence à partir du titre des questions |
| Compagnon | `TutorPersona`, `selectedTutorProvider`, préférence de profil prioritaire au cache | Nom, portrait, identifiant et accent restent canoniques, alias historiques compris |
| Objectif | `personalGoalControllerProvider`, état local optionnel déjà isolé | Inchangé ; ne participe jamais à la maîtrise |
| Régularité | `StudentHomeSnapshot.gamification.streakDays`, agrégat réel facultatif | Éventuelle série d’activité enregistrée, présentée séparément ; aucune appréciation de « bonne dynamique » inventée |
| Notes scolaires | Aucune route de carnet officiel élève/parent trouvée dans le routeur existant | Section informative distincte, sans fausse note ni bouton sans destination |
| Apparence | `IntelliaColors.backgroundPremium`, `surfaceSolid`, `textPrimary`, `textSecondary`, `brandIndigo`, titres Playfair | Palette globale conservée ; ajouts locaux dans `MasteryStyle` |
| Mouvement existant | `flutter_animate`, `FadeSlideEntrance`, `animations/OpenContainer` | Transition locale de 280 ms ; entrées finies spécifiques pour respecter l’accessibilité |
| Langues | ARB FR/EN et `flutter gen-l10n` vers `lib/l10n/generated` | Ajouts groupés et préfixés `mastery`, aucune chaîne française codée dans les nouveaux widgets |
| Résilience | Lecture des régions optionnelles via des fournisseurs indépendants et `valueOrNull` | Préservée ; nouvelles erreurs limitées à leur région, boutons de relance reliés à la source |

## Source de preuves et limites de confiance

La source nouvelle lit uniquement les documents existants de `progress` filtrés
par `studentId` et `type == quiz`. Le writer vérifié est
`functions/src/services/academicStateStore.ts`, méthode `writeQuizRewards`.
Le contrat de `firestore.rules` réserve les écritures aux fonctions serveur et
autorise les lectures à l’élève concerné et au parent lié, entre autres rôles.
La requête n’accède jamais à `quiz_attempts`, aux conversations ou aux pièces jointes.

Champs admis dans le domaine : `quizId`, `subjectId`, `score`, `maxScore`,
`updatedAt`. Le parseur exige des entiers finis, un résultat entre zéro et
`maxScore`, des identifiants non vides exacts, le bon élève et un `Timestamp`
serveur. Une date client, un score absent, une valeur fractionnaire ou une
écriture locale en attente ne devient pas une preuve. Les données hors contrat
sont ignorées, sans remplacer leurs valeurs par zéro.

Le document est remplacé après une nouvelle tentative du même quiz : il ne
constitue **pas** l’historique de toutes les tentatives. `evidenceCount` compte
les quiz distincts exploitables, pas les réponses ni les sessions. Les écrans
de détail expliquent cette limite et la fenêtre temporelle.

Le résumé ne précise ni les aides reçues, ni le mode de passation, ni le premier
essai, ni la représentativité du programme. Il ne permet pas de revendiquer une
compréhension autonome. En conséquence, le moteur de cette V1 produit seulement :

- `NO_EVIDENCE` : pas assez d’éléments exploitables ; aucun score calculé ;
- `EXPLORING` : première lecture prudente des quiz ;
- `BUILDING` : première lecture prudente en construction.

La confiance est au plus `limited`. `UNDERSTOOD` et `SOLID` existent dans le
modèle, le composant et les traductions pour les prochaines sources ; **ils ne
sont jamais attribués par cette source**, même après de nombreux quiz parfaits.
Les tests visuels peuvent construire ces états explicitement pour vérifier
leur rendu ; ils ne représentent pas une attribution réelle en production.

## Paramètres de calibration

Tous sont regroupés dans `MasteryCalibration`, sans seuil caché dans un widget.
Il s’agit de garde-fous initiaux non validés pédagogiquement, à faire examiner
avant toute ouverture de niveaux plus affirmatifs. Ils ne sont ni des notes,
ni des probabilités de maîtrise, ni un instrument de classement.

| Paramètre | Valeur V1 | Rôle |
| --- | --- | --- |
| Fenêtre | 90 jours, borne inférieure incluse | Écarter les preuves anciennes ; dates futures rejetées |
| Quiz distincts | Au moins 3 | Un quiz répété ne suffit jamais |
| Questions exploitables | Au moins 12 au total | Écarter une observation trop réduite |
| Taille minimale d’un quiz | 3 questions | Éviter une fausse diversité de micro-quiz |
| Dates distinctes | Au moins 2 jours UTC | Ne pas attribuer un état depuis une seule journée ; ne prouve aucune régularité |
| Passage prudent à `BUILDING` | Moyenne par quiz au moins 0,60 | Seuil provisoire parmi les seuls états prudents |
| Plafond de l’état | `BUILDING` | Conditions de passation et couverture des compétences inconnues |
| Plafond de confiance | `limited` | Ne pas prétendre à une validation indépendante |

Chaque quiz a le même poids interne. Les répétitions retiennent seulement le
résultat le plus récent. Des valeurs contradictoires à date identique ou une
affectation d’un même quiz à deux matières sont rejetées. Une autre matière
n’aide jamais à franchir le seuil de la matière courante. Les valeurs
`masteryScore`, `confidenceScore` et `freshnessScore` ne sont pas affichées ;
les deux dernières restent nulles faute de calibration justifiable.

## Tracé, actualisation et erreurs

`MasterySession` compare uniquement les émissions réellement observées pendant
la souscription actuelle. La première émission n’a aucun passé reconstruit.
Une nouvelle preuve datée peut conserver l’instantané précédent ; une
suppression, une expiration ou une correction sans nouvelle date ne crée pas
une tendance. Un instantané d’une autre entité ou insuffisant est rejeté.
Les états précédents ne sont pas persistés et disparaissent à la fin de la
souscription. Aucune comparaison hebdomadaire ou interappareil n’est promise.

Les fournisseurs sont automatiquement libérés et identifiés par le couple
observateur/élève. Le flux serveur actualise la lecture après un résultat réel.
Une minuterie locale d’expiration empêche les preuves de rester valides
indéfiniment si aucun nouvel événement réseau n’arrive. Elle n’effectue aucune
lecture réseau et s’arrête avec la souscription. Le bouton de relance invalide
la source concernée. Une erreur reste une erreur, elle n’est pas transformée en
liste de preuves fictivement vide.

Le parent passe par le tableau de bord existant des liens approuvés ; ce garde-fou
local n’accorde aucun droit supplémentaire. Les autorisations serveur restent
la référence. Les noms viennent du catalogue de classe existant, indépendamment
des preuves. Les erreurs de catalogue, de maîtrise, d’établissement ou de compagnon
ne font pas tomber l’identité. Le parcours parent est facultatif, limité à 250
leçons et explicitement signalé comme partiel si une 251e leçon est présente.

## Présentation et accessibilité

Le profil élève affiche identité, classe et établissement déclaré s’il existe,
puis compagnon discret, résumé local déterministe et matières. Aucun appel
génératif ne produit ce résumé. Le parent voit une autre question, des
comparaisons seulement si elles existent, un accompagnement prudent, le parcours
et une invitation à discuter. Les compteurs de minutes, erreurs exactes,
conversations, anciens classements et notes déduites du parcours sont absents.

`MasteryScale` emploie un `CustomPainter` sans shader, blur ou animation infinie.
Les longueurs discrètes représentent les états, jamais le rapport de bonnes
réponses. Les hachures et le texte indiquent une confiance limitée. Le tracé
antérieur est discontinu et possède un libellé explicite. Les couleurs ne
codent pas des qualités scolaires. Les sémantiques annoncent matière, état,
confiance et éventuelle comparaison, sans valeur en pourcentage.

Entrées : identité 0–150 ms, résumé 100–300 ms, encre à partir de 180 ms jusqu’à
520 ms ; le tracé éventuel arrive après l’encre. Le détail utilise `OpenContainer`
sur 280 ms, avec retour vers la carte. En réduction des mouvements, ce passage
est immédiat et les entrées sont supprimées. Aucun nouveau haptique de maîtrise
n’a été ajouté. Les préférences Android et iOS sont prises en compte suivant
le [contrat Flutter sur la réduction des animations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html).

Les cartes grandissent avec le texte. Deux colonnes ne sont utilisées qu’à
partir de 640 px utiles et avec un texte au plus à 130 %. Le texte sémantique
n’est pas tronqué à 200 %. Les cibles des cartes et du compagnon dépassent
48 px ; les autres actions conservent les dimensions du thème existant.
Le budget vise Android de milieu de gamme, mais **60 images/s ne sont pas
certifiées sans mesure sur appareil physique**.

## Vérification et suite de la mission

Les tests couvrent parseur, seuils et bornes, indépendance du parcours,
plafonds de confiance, répétitions, dates, identifiants, instantanés, changements
d’observateur, expiration locale, erreurs, relance, textes FR/EN, confidentialité
parent, identité des compagnons, sémantiques, mouvement et navigation.

La matrice comprend 320, 360, 390, 412, 480 et 768 px avec des textes à 1,0, 1,3,
1,5 et 2,0 pour élève et parent, dans les deux langues. Le détail est testé aux
six largeurs à 1,0 et 2,0. Les tests chargent les polices locales et les icônes
réelles ; les captures sont des **fixtures synthétiques de revue**, sans
connexion Firebase et sans valeur de validation sur téléphone.

Pour la V1.5/V2 : contrat de preuves versionné et minimal, conditions de
passation, références stables de tentative, classe et version du contenu,
liens explicites vers chapitres/compétences, historique comparable et validation
pédagogique des seuils. Si l’audit serveur restreint la lecture de `progress`,
une projection sécurisée devra être fournie ; aucun contournement ni changement
de règles n’est introduit ici. Le carnet officiel exige sa propre source.
