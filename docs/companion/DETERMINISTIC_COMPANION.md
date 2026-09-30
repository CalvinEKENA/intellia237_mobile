# Compagnon déterministe V1 — Kira et Léo sans modèle de langage

L'onglet Compagnon ne contacte plus aucun service de génération de texte.
Tout est calculé sur l'appareil, hors ligne compris.

## Chemin

```
message de l'élève
 → normalisation (minuscules, accents, apostrophes, « stp », « jveux »…)
 → intention (déclencheurs pondérés : plus la phrase est longue, plus elle pèse)
 → contexte local (matières, quiz, maîtrise, dernière séquence, dernier quiz)
 → compagnon (Kira ou Léo : mêmes intentions, autres mots)
 → variante choisie sans hasard (hachage stable, sans répétition immédiate)
 → réponse courte + actions réelles
```

- Moteur : `lib/features/ai_companion/deterministic/`
  (`DeterministicCompanionEngine`, `CompanionConversationState`,
  `CompanionStudyContext`, `CompanionDialogueBank`).
- Banque de dialogues : `assets/companions/dialogue/fr.json` et `en.json`.
  Le parser refuse une banque incomplète : clé manquante, moins de huit
  variantes par famille et par compagnon, emplacement inconnu, réponse
  trop longue, Kira et Léo identiques.
- Libellés d'interface (boutons, statut) : fichiers ARB.

## Ce que le compagnon sait

Seulement des données réelles et locales : prénom, matières et packs de la
classe, quiz de pack disponibles, maîtrise (`MasteryState` via les parcours),
dernière séquence ouverte, dernier quiz terminé. Une source absente compte pour
vide : pas de faux souvenir, pas de diagnostic inventé, pas de matière absente
de la classe.

## Ce qu'il ne fait pas

- Aucune explication générale : une question hors des contenus reçoit une
  réorientation honnête (`unsupported_freeform`).
- Un titre réel de séquence, de leçon ou de notion (« les nombres
  complexes ») ouvre le cours ou son quiz ; il n'est jamais « expliqué ».
- « Tu es une IA ? » : réponse honnête ; jamais « je suis humain ».

## Actions

Sous la dernière réponse : ouvrir un quiz de pack (entraînement ou
évaluation), une matière, une séquence ou une leçon, tous les quiz, toutes les
matières, ou répondre d'un toucher (nom d'une matière). Aucune logique de quiz
n'est dupliquée : les actions ouvrent `PackQuizScreen`.

## Retour de quiz

Un quiz de pack terminé depuis moins de douze heures est commenté une fois à
l'arrivée dans le Compagnon, avec son vrai score : refaire le quiz,
s'entraîner sur le thème après une évaluation, continuer le cours.

## Historique

Les fils sont marqués `engine: deterministic_v1`. Les fils plus anciens,
écrits par le service en ligne, restent sur l'appareil mais ne sont ni rouverts
ni listés.
