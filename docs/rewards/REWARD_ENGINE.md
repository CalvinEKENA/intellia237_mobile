# INTELLIA237 — Reward & Haptic Engine

Couche de gratification légère : réussir doit être agréable à voir et à
sentir, jamais bruyant. Générique : le moteur ne connaît ni matière ni
chapitre, il réagit à des événements pédagogiques abstraits. Aucun réseau,
aucun modèle de langage.

## Chaîne

```
bonne réponse → RewardEvent → RewardEngine (mémoire courte) → RewardPattern
   → RewardStage (effet) + RewardMessageLine (micro-message) + HapticPlayer
```

| Fichier | Rôle |
|---|---|
| `lib/features/rewards/domain/reward_event.dart` | Événement abstrait (difficulté, maîtrise avant/après, seuil, erreurs, chapitre terminé, temps de réponse) |
| `domain/reward_pattern.dart` | `RewardTier`, `RewardIntensity`, `RewardVisual`, `RewardMessage`, `RewardPattern` |
| `domain/haptic_pattern.dart` | `HapticMode` (activées, réduites, désactivées), `HapticPattern` → impulsions |
| `domain/reward_engine.dart` | Décision, anti-répétition, délai entre grandes animations |
| `application/reward_providers.dart` | `rewardDispatcherProvider` (point d'entrée unique), lecteur haptique, préférence |
| `presentation/reward_stage.dart` | Effets (un contrôleur, peintres légers), micro-message |
| `presentation/reward_milestone.dart` | Scène plein écran des grandes étapes (1,3 s, ne bloque aucun geste) |
| `content_engine/application/reward_bridge.dart` | Événement construit depuis le même `MasteryState` que la Content Engine |

Branché dans : S'entraîner et l'intégration (Content Engine), Mon Parcours
(cartes de pack et cartes publiées), jeux, correction immédiate des quiz.

## Niveaux

| Niveau | Déclencheur | Effet | Haptique | Message |
|---|---|---|---|---|
| A. Ordinaire | bonne réponse | coche, impulsion, montée, pas de progression (en rotation) — 300 à 500 ms | tap léger | une fois sur deux : « Exact. », « Bien vu. », « Oui. », « Très propre. », « Tu l'as. » |
| Rapide | réponse en moins de 2,5 s | coche seule | tap léger | aucun |
| Progrès | palier de 25 points de maîtrise | pas de progression | tap | « Belle progression. » |
| B. Série | 3, 5 puis toutes les 5 | trait lumineux | deux petites impulsions | « 3 de suite. » |
| Niveau supérieur | le moteur d'adaptation propose la difficulté supérieure | trait lumineux | deux impulsions | « Niveau supérieur débloqué. » |
| D. Récupération | réussite après au moins 2 erreurs | impulsion douce | retour doux | « Oui. Cette fois, tu l'as. » |
| C. Défi | difficulté la plus haute (≥ 3) | contraction puis déploiement, halo | impulsion marquée + légère | « Très bien. Tu viens de franchir un vrai cap. » |
| E. Maîtrise | seuil du pack franchi | anneau qui se complète, micro-particules | motif court distinct | « Notion maîtrisée : Congruence modulo n » |
| F. Étape | dernière notion du chapitre maîtrisée | scène plein écran brève | deux impulsions posées | « Chapitre réussi : Arithmétique » |

## Anti-répétition

* Jamais deux grandes animations (défi, maîtrise, étape) à moins de 25 s :
  la seconde devient un halo ou un trait, son message reste.
* Effets ordinaires en rotation, jamais deux fois le même de suite.
* Un message n'est jamais repris parmi les trois derniers affichés ; une
  réponse ordinaire sur deux n'a pas de message.
* Des exercices faciles en série ne déclenchent jamais de grande animation.
* Prénom : même règle que le Compagnon (`CompanionNamePolicy`), réservé
  aux défis, maîtrises, étapes et récupérations, jamais deux fois de suite.

## Haptique

Impulsions élémentaires : sélection, légère, moyenne. Jamais forte, jamais
longue (motif ≤ 300 ms). « Réduites » : une seule impulsion légère, et
seulement pour série, défi, maîtrise, étape. « Désactivées » : rien.
Une réponse à revoir donne un retour doux (plus d'impulsion forte). Sur
Android, le retour haptique suit le réglage système de vibration au toucher.

## Accessibilité et performance

* Animations réduites (système ou préférence INTELLIA) : aucun effet, pas de
  scène plein écran ; verdict et micro-message restent affichés.
* Micro-message annoncé par les lecteurs d'écran (région dynamique).
* Un seul `AnimationController` par scène, `CustomPainter` avec `repaint`,
  peintures réutilisées, aucune image ni vidéo ni shader coûteux.
* Mon Parcours : aucun temps mort, le swipe reste possible pendant l'effet.
