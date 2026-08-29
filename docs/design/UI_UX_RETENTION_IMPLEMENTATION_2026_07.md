# Intellia237 — implémentation UI/UX, fiabilité et rétention

## Périmètre livré

- Contrat sémantique clair/sombre et correction des textes blancs sur fonds clairs.
- Tests WCAG de l’accueil, petites largeurs, text scale et changements d’onglet.
- Accueil connecté aux matières réelles, mode démo explicitement étiqueté et état honnête lorsque Firestore est vide.
- Reprise locale vers la dernière leçon réellement ouverte.
- États partagés : vide, bientôt disponible, hors ligne, erreur, accès refusé et verrouillé.
- Continuité visuelle du parcours matière → chapitre → leçon.
- Quiz : confirmation d’abandon, récapitulatif des réponses manquantes, remplacement de route vers le résultat et révision active des erreurs sans points supplémentaires.
- FLOW : plus de vingt exercices corrigés, sept matières, progression locale persistée, aucune statistique initiale fictive et priorité aux cartes non terminées.
- Compagnon : historique local, retry, état honnête, contexte de la leçon et absence de télémétrie sur le texte libre.
- Paramètres : taille du texte, réduction des animations, économie de données, préférences de rappels et diagnostics sous consentement.
- Objectif personnel hebdomadaire local (séances, durée, matière prioritaire)
  avec carte d’accueil, réglage dans Paramètres et comptage des jours actifs.
- Chiffres de marque animés : `IntelliaCountUp` (tabulaire, ≤ 900 ms, valeur
  directe en animations réduites) sur le score et les points du résultat de
  quiz, synchronisé avec l’anneau.
- Transition signature « aube » à la fin de l’inscription : rideau de lumière
  nuit → crème (≤ 1,2 s), jamais bloquant (un tap passe directement), fondu
  court en animations réduites.
- Badge « en progrès » au résultat de quiz : comparaison honnête avec la
  tentative précédente du même quiz (jamais de record inventé ; silencieux en
  cas de baisse ou de première tentative).
- Détection d’absence de réseau avec bannière globale.
- Localisation système française et architecture prête pour le français/anglais.
- Retrait du bundle des anciens logos, Lottie et images inutilisées, sans suppression destructive des sources.

## Décisions produit

### Accueil et Aujourd’hui

Un écran « Aujourd’hui » séparé ferait doublon avec l’accueil. L’accueil reste le point d’entrée quotidien et ne montre que les blocs soutenus par des données réelles. Lorsque la base de cours est vide, il présente honnêtement les fonctionnalités déjà utilisables.

### FLOW

FLOW reste une expérience courte accessible depuis l’accueil plutôt qu’un sixième onglet. Une session a une fin naturelle ; les contenus terminés sont repoussés après les contenus nouveaux lors de la reprise.

### Progression

La progression demeure dans le Profil tant que les agrégats serveur ne sont pas disponibles. Aucun graphe plat ou chiffre arbitraire ne doit simuler de l’activité.

### Quiz

Le quiz principal reste en mode examen : les corrections arrivent après soumission. La révision des erreurs utilise le rappel actif sans redistribuer de points et sans exposer davantage les réponses pendant une tentative.

### Objectif personnel hebdomadaire

- **Besoin utilisateur** : un cadre réaliste choisi par l’élève (« 3 séances
  cette semaine ») plutôt qu’une pression quotidienne subie.
- **Effet rétention attendu** : engagement auto-déterminé ; l’accueil affiche
  la progression de la semaine et un raccourci vers la matière prioritaire.
- **Coût** : faible — stockage local (`PersonalGoalStore`), aucun schéma
  serveur ; une carte d’accueil, une sheet partagée avec les Paramètres.
- **Risque et garde-fous** : culpabilisation. Interdits : « en retard »,
  « raté », pénalité de semaine manquée. Le compteur repart chaque lundi
  (semaine ISO 8601) ; à zéro séance le ton reste neutre.
- **Intégration** : une séance = un jour calendaire avec activité pédagogique
  réelle (leçon terminée, quiz soumis ou carte FLOW validée) — trois points
  d’accroche existants, idempotents pour la journée.
- **Métriques** : `goal_set` et `goal_week_completed` (nombre de séances
  uniquement, sous consentement diagnostics).
- **Décision** : implémenté. La liaison de l’objectif avec l’horaire des
  rappels reste conditionnée à l’activation réelle des notifications.

### Notifications

Le réglage est préparé mais aucune notification système n’est programmée sans choix d’horaire, permission OS et validation éditoriale. Cette restriction évite les rappels manipulateurs ou intempestifs.

## Matrice de télémétrie

La collecte Analytics et Crashlytics est désactivée par défaut. Elle ne démarre qu’après activation explicite de « Diagnostics anonymes ».

| Événement | Finalité | Données | Personnelle | Conservation recommandée | Consentement |
|---|---|---|---|---|---|
| `quiz_submitted` | Mesurer la complétion | nombres de questions/réponses | Non | 90 jours | Oui |
| `flow_card_completed` | Mesurer l’usage des formats | type technique de carte | Non | 90 jours | Oui |
| `flow_exercise_answered` | Mesurer la valeur pédagogique | booléen juste/faux | Non | 90 jours | Oui |
| Crash technique | Repérer les régressions | pile technique filtrée | Potentiellement | 30 jours | Oui |

Sont interdits : messages au compagnon, réponses libres, nom, e-mail, identifiant utilisateur lisible, token, contenu détaillé d’un cours.

## Stratégie réseau

- Le cache Firestore existant reste un cache technique, pas une promesse de mode hors ligne complet.
- L’interface signale uniquement qu’aucun réseau n’est détecté ; elle ne prétend pas garantir l’accès Internet.
- FLOW et les préférences sont persistés localement.
- Les Cloud Functions de score, progression et compagnon exigent encore le réseau.
- Une file d’attente serveur pour la progression devra être conçue avec idempotence avant activation ; elle n’est pas simulée côté client.

### Célébration de série

La célébration « série maintenue » est différée : elle exige un streak calculé
côté serveur (agrégat quotidien fiable). La recalculer localement créerait un
second système de récompense parallèle, ce que le registre interdit.

### Purge des sources d’assets débundlés

Vérifié : plus aucune référence code, native ou web aux fichiers débundlés
(`assets/tutors`, `assets/onboarding`, `assets/lottie`, `assets/images`,
`assets/animations`, anciens logos de `assets/icons`) — soit ≈ 11,7 Mo qui ne
pèsent plus dans l’APK et ne restent que dans le dépôt git. Leur suppression
est laissée à une décision humaine (action destructive).

## Éléments dépendant encore du backend ou du contenu

- Alimentation des cours, chapitres, leçons et quiz réels.
- Agrégats de progression parent/enseignant et points unifiés côté serveur
  (dont le streak, prérequis de la célébration de série).
- Suppression automatisée de compte et politique de rétention des données.
- Téléchargement volontaire de chapitres avec manifeste de fichiers et résolution de conflits.
- Traduction éditoriale anglaise validée humainement.
- Autorisation et planification réelles des notifications.

## Terminologie des récompenses

L’interface et le modèle canonique utilisent désormais le terme scolaire
« points ». Les nouvelles écritures Firestore emploient `points`,
`pointsReward` et `pointsAwarded`. Les anciennes clés `xp`, `xpReward` et
`xpAwarded` restent uniquement acceptées en lecture afin de préserver les
données existantes sans migration destructive.

## Validation

- `flutter analyze` doit rester sans erreur ni avertissement.
- Les groupes de tests accueil et FLOW couvrent l’honnêteté, la lisibilité, les interactions, le catalogue et les récompenses.
- Une validation visuelle sur Android réel reste obligatoire pour les performances, le rendu des polices et les captures avant/après.
