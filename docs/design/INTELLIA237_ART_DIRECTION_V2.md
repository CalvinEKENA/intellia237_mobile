# INTELLIA 237 — DIRECTION ARTISTIQUE ET EXPÉRIENCE MOBILE V2

> Spécification exploitable par un agent d'implémentation (Codex / Claude Code).
> **Aucune implémentation dans ce document.** Nom public visible : **« Intellia 237 »**.
> La **homepage élève actuelle est l'ancre de référence** : non redessinée. Les autres
> écrans doivent rejoindre sa famille (palette, typo, géométrie, rythme, profondeur,
> qualité d'animation, densité, ton).

Référentiel technique réel exploité : `IntelliaColors`, `IntelliaGradients`,
`IntelliaTypography` (Playfair Display / Montserrat / Manrope), `IntelliaMotion`
(instant 80 / press 150 / fast 180 / medium 280 / slow 420 / cinematic 700),
`IntelliaRadii` (10/16/22/28/full), `IntelliaPressable` (scale 0.97 + haptique),
`AuthExperienceColors.night #080722`, contexte académique `tutorLevel` (bepc/proba/bac),
polices préchargées hors-ligne uniquement.

---

## 1. VISION

**Une seule application, deux temps : le seuil (sombre, rituel) et la maison (claire,
quotidienne), reliés par une métamorphose lumineuse — « l'aube ».**

Intellia 237 doit se vivre comme **un produit continu**, pas comme une collection
d'écrans. La continuité se mesure à trois choses vérifiables :
1. **Aucune rupture de famille visuelle** entre deux écrans consécutifs (même géométrie,
   même rythme typographique, même profondeur).
2. **Toute descente dans la hiérarchie est spatialement explicite** (l'élément source se
   transforme en écran cible) plutôt qu'un remplacement abrupt.
3. **Les nombres (XP, niveau, série, score) sont traités comme une matière de marque**,
   pas comme du texte ordinaire.

Critère de réussite global : un utilisateur qui filme son parcours
inscription → accueil → leçon → quiz ne voit **aucune coupure sèche** ni **aucune
incohérence de coins, de police ou de profondeur**.

---

## 2. PROBLÈMES À RÉSOUDRE

Constats issus du produit réel (non décoratifs — chacun rattaché à un axe : compréhension,
émotion, continuité, efficacité, hiérarchie, engagement, accessibilité, performance,
cohérence de marque).

| # | Problème observé | Axe(s) | Preuve dans le code |
|---|---|---|---|
| P-1 | Deux langages : auth « nuit » vs app « claire » → coupure à la fin de l'inscription | continuité, cohérence | `AuthExperienceColors.night` vs `IntelliaColors.backgroundPremium` |
| P-2 | Géométrie incohérente : rayons **8 px** en auth vs **22–28 px** ailleurs | cohérence, hiérarchie | `BorderRadius.circular(8)` (auth widgets) vs `IntelliaRadii.large=22` |
| P-3 | Mouvement « en pics » : riche sur onboarding/Flow, plat sur learn/quiz/lecteur | engagement, émotion | Onboarding/Flow animés ; hubs surtout statiques |
| P-4 | Nombres traités comme texte simple (pas de tabular, pas d'animation de valeur) | compréhension, émotion | tuiles stats `_StatTile` en `TextStyle` ordinaire |
| P-5 | Affordances ambiguës possibles (cartes/chevrons, overlays bloquants) | compréhension, accessibilité | tour guide modal bloquant déjà corrigé ; à systématiser |
| P-6 | Identité « 237 » sous-exploitée et non cadrée | cohérence de marque, émotion | couleurs `cmVert/cmRouge/cmJaune` présentes mais peu utilisées |
| P-7 | Pas de système d'états unifié (vide/erreur/hors-ligne) | compréhension, continuité | états techniques bruts par endroits |
| P-8 | Un seul produit pour 6e→Tle, sans modulation de maturité | engagement, crédibilité | `tutorLevel` existe mais non exploité pour le ton/densité |
| P-9 | Nom de marque incohérent : « INTELLIA237 » vs « Intellia 237 » | cohérence de marque | wordmark splash vs édition récente écran de succès |

**Incohérences techniques de la homepage à signaler (sans refonte esthétique)** :
- En-tête : texte **blanc** conçu pour fond sombre, posé sur backdrop clair → corrigé par
  un halo de lisibilité (déjà fait). À garder comme **règle** : tout texte blanc sur clair
  porte un halo.
- Onglets en `IndexedStack` : bon pour la conservation d'état ; vérifier que les écrans
  embarqués (`LearnHubScreen(embedded:true)`, etc.) **n'empilent pas** de second Scaffold
  avec barre propre (risque de double chrome).
- Tour guidé : overlay plein écran — **doit rester dismissible** (corrigé) ; règle générale
  en §5.

---

## 3. PRINCIPES DE MARQUE

### 3.1 Les 5 principes directeurs
1. **Continuité avant effet.** Un effet ne se justifie que s'il sert la compréhension,
   l'émotion ou la continuité. Pas d'animation décorative isolée.
2. **Clair par défaut, sombre par rituel.** Le sombre est réservé au seuil (splash + auth).
   Partout ailleurs : famille claire de la homepage.
3. **Les nombres parlent.** XP, niveau, série, score : matière de marque (tabular, animés,
   colorés sémantiquement).
4. **La fierté est tricolore, le reste ne l'est pas.** Vert/rouge/jaune = récompense
   méritée, jamais chrome d'interface.
5. **Un produit, plusieurs maturités.** Le ton, la densité et l'intensité s'adaptent au
   cycle scolaire — pas deux applications.

### 3.2 Maturité progressive 6e → Terminale (un seul produit)

**Mécanisme** : un profil de maturité dérivé de `tutorLevel` déjà présent (`bepc` →
**Collège**, `proba` → **Lycée**, `bac` → **Terminale/examen**). Un unique
`MaturityProfile` paramètre l'interface ; **aucun écran dupliqué**.

| Variable | Collège (6e–3e / bepc) | Lycée (2nde–1re / proba) | Terminale (bac) |
|---|---|---|---|
| Densité d'information | basse, aérée | moyenne | élevée (données, échéances) |
| Présence Kira/Léo | omniprésente, expressive | présente, mesurée | discrète, à la demande (mentor) |
| Intensité animation | élevée (célébrations fréquentes) | modérée | sobre |
| Vocabulaire | chaleureux, imagé | précis, orienté objectif | exigeant, lexique d'examen |
| Récompenses | grandes, fréquentes (badges) | paliers, maîtrise | jalons sérieux, % de maîtrise |
| Statistiques | simples (XP, série, badges) | + maîtrise par thème | + rang, temps, prédiction |
| Gamification | forte | modérée | cadrée « performance » |
| Ton des messages | encourageant, ludique | pair à pair, motivant | respectueux, responsabilisant |
| Couleurs secondaires | accents plus présents | accents mesurés | neutres + accent sur la donnée |
| Suggestions pédagogiques | guidées | autonomie + révisions | préparation examen ciblée |

**Garde-fous** : le produit reste **ludique en 6e**, **crédible en Terminale**,
**rassurant pour les parents** (clarté, sobriété, pas d'infantilisation visible côté
suivi), **premium pour tous** (même géométrie, même qualité de mouvement, seules
l'intensité et la densité varient). La maturité **ne change jamais** : la palette
primaire, la typo, les rayons, la grammaire de mouvement.

### 3.3 Nom de marque
- Texte visible : **« Intellia 237 »** (espace). Bannir « INTELLIA237 » comme **texte**.
- Le **logo image** (`icone_final.png`) peut encore contenir l'ancienne forme : remplacement
  **séparé** (tâche dédiée), non bloquant pour le texte.
- Lockup unique défini en §11.

---

## 4. DESIGN SYSTEM

### 4.1 Couleur — rôles sémantiques (valeurs réelles)
| Rôle | Token | Hex | Usage |
|---|---|---|---|
| Primaire | `brandIndigo` | #5856D6 | actions, focus, progression |
| Secondaire | `brandPurple` | #AF52DE | gradients de marque, Kira |
| Accent froid | `brandBlue` | #007AFF | Léo, liens, info |
| Succès | `success` | #34C759 | validation, juste |
| Alerte | `warning` | #FF9500 | série, attention |
| Erreur | `error` | #FF3B30 | faux, échec |
| XP | `xpGold` | #FFD60A | points d'expérience |
| Fierté 237 | `cmVert/cmRouge/cmJaune` | #007A5E/#CE1126/#FCD116 | **moments de fierté uniquement** (§12) |
| Seuil (rituel) | `night` | #080722 | splash + auth seulement |
| Surfaces claires | `backgroundPremium/Primary` | #FBFAF7 / #FCFCFF | app quotidienne |

Règle : **une seule couleur primaire d'action par écran**. Le tricolore 237 n'est jamais
fond, nav, ni chrome de carte.

### 4.2 Surfaces & profondeur — 3 niveaux (à systématiser)
| Niveau | Définition | Réalisation | Quand |
|---|---|---|---|
| **0 — Plan** | fond d'écran | gradient clair (`backgroundFor`) | toujours |
| **1 — Surface** | carte posée | `surfaceSolid`, ombre `card`, rayon `large` | contenu courant |
| **2 — Verre/flottant** | élément élevé, contextuel | `surfaceGlass` + `BackdropFilter` sigma ≤16, ombre `premium` | HUD, sheets, CTA collant |
Limiter le verre à **1 couche visible** à la fois (perf §9).

### 4.3 Rayons — **unification** (corrige P-2)
Échelle unique `IntelliaRadii` : 10 (puce/petit), 16 (champ), 22 (carte), 28 (héros/sheet),
full (pilule). **Migrer toutes les surfaces d'auth de 8 → 16/22.** Coin « continu »
(superellipse) souhaitable sur cartes ≥ 22 (détail de finition, non bloquant).

### 4.4 Ombres
`card` (douce, niveau 1), `premium` (large, niveau 2), `glow(color)` (focus/halo,
réservé aux états actifs/sélection). Pas d'ombre sur les éléments non interactifs plats.

### 4.5 Espacement & rythme
Grille 8pt via `IntelliaSpacing` (xxs4 / xs8 / sm12 / md16 / lg24 / xl32 / xxl40 / xxxl56).
Règle : marges d'écran 24, gouttière inter-cartes 16, colonne de contenu **max 480** sur
grands écrans (déjà sur la home → partout).

### 4.6 Composants interactifs (catalogue minimal)
Bouton primaire, bouton secondaire/outline, bouton verre, bouton texte, pilule de choix
(`AuthSelectionPill` → **langage de sélection unifié**), carte cliquable, carte
informative, champ, onglet, puce filtre, tuile matière, tuile leçon, tuile quiz, carte
reco, badge, carte compagnon, élément verrouillé, contenu premium. États : §6.4.

### 4.7 Système d'états (doctrine commune — détaillé §9 / écran par écran §13)
Chaque surface définit : chargement (squelette épousant la mise en page finale), normal,
vide, erreur, hors-ligne, session expirée, permission refusée, premium verrouillé,
partiellement disponible, succès. Jamais d'écran « technique ».

### 4.8 Icônes & illustrations
Icônes : Material Rounded, trait cohérent, taille 24 par défaut, jamais seules pour une
action ambiguë (toujours libellé ou contexte). Illustrations : Kira/Léo **assets
officiels uniquement**, jamais d'autre personnage généré ; fallback premium si l'asset
manque (déjà fait sur l'écran de succès → généraliser).

---

## 5. NAVIGATION

### 5.1 Doctrine
- **Barre inférieure** : 5 onglets (Accueil, Apprendre, Quiz, Compagnon, Profil), état
  conservé via `IndexedStack` (déjà). Flow reste accessible depuis l'Accueil (carte
  d'entrée). Changement d'onglet = **Fade Through** (onglets non spatialement liés).
- **Navigation profonde** (dans un onglet) : `push` ; parent→enfant = **Container
  Transform** (préféré) sinon Shared Axis Z. Retour = inverse exact.
- **Profil** : onglet (pas de modale).

### 5.2 Retour système
| Contexte | Android (bouton/back gesture) | iOS (swipe-back) |
|---|---|---|
| Écran poussé (détail/lecteur/quiz) | pop → écran parent | swipe-back actif |
| Racine d'onglet ≠ Accueil | revient à l'onglet **Accueil** | n/a (onglets) |
| Racine Accueil | confirmation de sortie (sheet) | n/a |
| Leçon / lecteur | pop (lecture sauvegardée) | swipe-back |
| Quiz **en cours** | **sheet de confirmation d'abandon** (pas de pop silencieux) | idem |
| Flow | quitte le Flow → Accueil (pas de pop carte par carte) | idem |

### 5.3 Modales, sheets, overlays — règle anti-blocage
- **Sheets** (choix contextuel, confirmation douce) : montée depuis le bas, scrim 0.4,
  coin haut 28, poignée de drag, **dismissible** (scrim + drag).
- **Dialogues** : confirmations critiques uniquement.
- **Tours guidés / overlays plein écran** : **toujours** (a) dismissibles au tap sur le
  scrim, (b) avec affordance visible « Passer », (c) marqués vus à la fermeture. **Aucune
  couche ne doit absorber les taps sans échappatoire** (leçon du tour modal corrigé).

### 5.4 Transitions par relation
| Relation | Transition | Token durée |
|---|---|---|
| Pair à pair (étapes, séquence) | Shared Axis X | standard 280 |
| Onglets (non liés) | Fade Through | standard 280 |
| Parent → enfant (drill-down) | Container Transform | emphasized 420 |
| Changement de contexte | Fade Through | standard 280 |
| Succès (inscription) | Aube (cinematic) | ≤ cinematic 700 (cap 1400 total, §14) |
| Interruption (sheet/modale) | Slide-up + scrim | quick→standard |
| Retour arrière | inverse de l'aller | identique |

---

## 6. MOTION SYSTEM

### 6.1 Motion tokens
| Token | Durée | Courbe (cubic-bezier) | Usage |
|---|---|---|---|
| `instant` | 80 ms | (0.4,0,1,1) | feedback immédiat (ripple, check) |
| `quick` | 150–180 ms | swiftOut (0.55,0,0.1,1) | pressed scale, toggles, hover web |
| `standard` | 240–280 ms | emphasizedDecelerate (0.05,0.7,0.1,1) | Shared Axis, Fade Through, transitions courantes |
| `emphasized` | 380–420 ms | emphasizedDecelerate | Container Transform, entrées importantes |
| `cinematic` | 600–700 ms (cap 900) | (0.2,0,0,1) | aube, révélations compagnon, level-up |

### 6.2 Catalogue de mouvements
| Mouvement | Usage | Durée | Courbe | Amplitude | Direction | Fréquence | Interdit |
|---|---|---|---|---|---|---|---|
| Shared Axis | pairs/étapes | standard | emphasizedDecelerate | 30 px + fade | horizontal (sens du flux) | par navigation | comme drill-down |
| Fade Through | contextes/onglets | standard | standard | fade + scale 0.92→1 | sur place | par navigation | quand un lien spatial existe |
| Container Transform | drill-down | emphasized | emphasizedDecelerate | morph rect source→cible | expansion depuis la source | par ouverture | sur éléments non liés |
| Hero | élément partagé (compagnon) | emphasized→cinematic | (0.2,0,0,1) | trajectoire + scale | source→cible | rare | si pas de continuité réelle |
| Scale de pression | tout interactif | press 150 | swiftOut | 1.0→0.97 | — | à chaque tap | comme seule affordance d'état |
| Staggered entrance | listes/cartes | standard | emphasizedDecelerate | y +8→0, fade | bas→haut | à l'apparition d'écran | délais > 60 ms/élément, > 6 éléments |
| Progression numérique | XP/score/% | 400–900 ms (selon Δ) | (0.2,0,0,1) | count-up | — | à la mise à jour | sur grands deltas sans plafond |
| Skeleton | chargement | boucle 1200 ms | sinus doux | shimmer 0.3 | balayage | pendant chargement | shimmer agressif/contrasté |
| Changement d'état | normal↔selected etc. | quick | swiftOut | couleur/échelle | — | à l'interaction | transitions > 250 ms |
| Feedback juste | bonne réponse | standard | (0.2,0,0,1) | éclosion verte + check | depuis l'option | par réponse | éclats bruyants/confettis lourds |
| Feedback faux | mauvaise réponse | quick | (0.36,0,0.66,-0.56) | secousse ±6 px ×2 | latéral | par réponse | secousse > 3 cycles |
| Arrivée Kira/Léo | révélation compagnon | cinematic | (0.2,0,0,1) | fade+scale 0.92→1, flou→net | bas→centre | rare | sur écrans de travail |
| Level-up | montée de niveau | cinematic | (0.2,0,0,1) | anneau + tricolore 237 | radial | événementiel | plus d'1/session en simultané |
| Badge | déblocage | emphasized | (0.2,0,0,1) | scale 0.7→1 + lueur | depuis l'origine | événementiel | empilement de badges animés |
| Aube | succès→accueil | cinematic | (0.2,0,0,1) | métamorphose sombre→clair | top→bas (lever) | 1× (inscription) | bloquer > 1.4 s |
| Nav inférieure | onglet sélectionné | quick | swiftOut | icône/teinte | — | par tap | rebond ludique en Terminale |
| Overscroll | bord de liste | quick | decel | lueur de marque ≤ 8 px | bord atteint | au dépassement | étirement caoutchouc exagéré |
| Reduced motion | global | — | — | remplace par fade ≤150 ms | — | si activé | toute boucle/parallax/morph |

### 6.3 Règle de simultanéité
**≤ 3 animations en boucle** par écran ; **≤ 1 `cinematic`** à la fois ; les célébrations
(level-up/badge) **ne se cumulent pas** (file d'attente, jouées séquentiellement).

### 6.4 États d'un composant interactif (générique)
| État | Signal visuel | Signal tactile |
|---|---|---|
| Normal | surface tangible (teinte/bordure), affordance directionnelle **seulement si navigation** | — |
| Hover (web) | élévation +1, teinte +4 % | — |
| Pressed | scale 0.97 (`quick`) | `selectionClick` |
| Selected | gradient/teinte primaire + coche + lueur `glow` | `selectionClick` |
| Disabled | opacité 0.4, **+ raison visible** (jamais grisé muet) | aucune |
| Loading | spinner/halo dans l'élément, label « … » | — |
| Success | teinte succès + check, `standard` | `lightImpact` |
| Error | teinte erreur + icône + message, secousse `quick` | `heavyImpact` |

---

## 7. INTERACTION SYSTEM (contrat d'affordance)

### 7.1 Règle d'or
Tout élément cliquable possède **au minimum** : (a) une **surface tangible** (fond, teinte
ou bordure), (b) un **feedback pressed** (scale 0.97 + haptique). Une **affordance
directionnelle** (chevron/flèche) est réservée aux éléments qui **naviguent**.
**Aucune** carte informative ne porte de chevron.

### 7.2 Contrat par catégorie
| Élément | Interactif ? | Signal visuel | Tactile |
|---|---|---|---|
| Bouton principal | oui | pilule pleine gradient indigo→violet, ombre `glow`, libellé + icône | `selectionClick` |
| Bouton secondaire | oui | outline/teinte douce, pas d'ombre | `selectionClick` |
| Carte cliquable | oui | surface niv.1 + pressed scale ; chevron **si navigation** | `selectionClick` |
| Carte informative | non | surface plate, **pas de chevron, pas de pressed** | aucune |
| Champ | oui | bordure 16, label flottant, focus = bordure primaire animée | — |
| Onglet | oui | icône+label, sélection = teinte primaire + indicateur | `selectionClick` |
| Puce (filtre) | oui | pilule, selected = primaire + coche | `selectionClick` |
| Matière | oui | tuile gradient matière, pressed, **Container Transform** | `selectionClick` |
| Leçon | oui | ligne/tuile + progression, pressed, drill-down | `selectionClick` |
| Quiz | oui | carte difficulté + durée, pressed | `selectionClick` |
| Recommandation | oui | carte horizontale, pressed | `selectionClick` |
| Badge | oui (détail) | médaille ; verrouillé = silhouette + cadenas | `selectionClick` (gagné) |
| Compagnon | oui | avatar + halo réactif ; non « bouton » mais zone d'action claire | `selectionClick` |
| Élément verrouillé | non (action = déverrouiller) | opacité 0.5 + **cadenas** + label « Bientôt/Premium » | aucune (tap → sheet explicatif) |
| Contenu premium | oui (vers offre) | liseré doré discret + cadenas, **jamais** tricolore 237 | `selectionClick` |

### 7.3 Fausses affordances **interdites**
Chevron sans action · bouton inactif sans raison · élément animé non cliquable · zone
cliquable sans feedback · icône seule ambiguë (toujours libellé/aria-label).

---

## 8. ACCESSIBILITÉ

| Sujet | Exigence |
|---|---|
| Contraste texte normal | ≥ **4.5:1** |
| Contraste grand texte (≥ 24 px ou 18.66 px bold) | ≥ **3:1** |
| Contraste icône/élément non textuel porteur de sens | ≥ **3:1** |
| Cible tactile | ≥ **48×48 dp**, espacement ≥ 8 |
| Échelle texte | support **1.0 → 1.5** sans clipping ; tester **1.3 et 1.5** ; tout écran scrollable |
| Lecteurs d'écran | `Semantics(button/selected/header/label)` sur chaque interactif ; live region pour XP/score/résultats |
| Ordre sémantique | de lecture logique (haut→bas, gauche→droite) ; focus initial sur le titre |
| Couleur jamais seule | juste/faux = couleur **+ icône** ; verrouillé = opacité **+ cadenas** ; série = couleur **+ libellé** |
| Textes alternatifs | Kira/Léo, badges, illustrations décrits |
| Orientation | portrait prioritaire ; ne pas casser en paysage (scroll) |
| Grands écrans | colonne max 480, centrée |
| Lecteurs dyslexiques | corps Montserrat (lisible), interligne ≥ 1.4, pas de justification ; **réglage** d'espacement renforcé ; option police dédiée = tâche séparée (police non préchargée) |
| Formulation d'erreur | simple, orientée action, sans jargon en production (code diagnostic en staging) |

### 8.1 Reduced motion — substitutions
| Animation | Remplacement reduced-motion |
|---|---|
| Container Transform | **cross-fade 200 ms**, pas de morph |
| Hero / arrivée compagnon | apparition sur place, sans trajectoire |
| Aube | fondu sombre→clair **250 ms**, sans balayage ni vol |
| Staggered entrance | apparition simultanée, fade ≤ 150 ms |
| Shine/parallax/boucles (en-tête, halos) | **supprimées** (état final figé) |
| Feedback faux (secousse) | bordure erreur + icône, **sans secousse** |
| Progression numérique | valeur finale directe (pas de count-up) |
| Particules splash | supprimées (logo + halo statiques) |

---

## 9. PERFORMANCE

### 9.1 Budget (téléphone Android moyen ~ 4 Go, GPU d'entrée de gamme)
| Cible | Limite indicative |
|---|---|
| Démarrage → premier frame cohérent | splash natif immédiat ; splash Flutter interactif ≤ **1.5 s** ; pas de frame blanche |
| Durée de transition | 200–500 ms ; **≤ 700 ms** (≤ 900 cinematic, ≤ 1400 aube totale) |
| `BackdropFilter` plein écran | **≤ 1 visible**, jamais empilés, sigma ≤ 16 |
| Animations continues simultanées | **≤ 3** |
| Poids image (compagnon) | **≤ 200 Ko**, précachée ; jamais > 1080 px de large |
| Rive (futur) | viser ≤ 150 Ko/asset, 1 lecteur actif à la fois |
| Blur | sigma ≤ 16 ; **jamais** sur une liste scrollable |
| Particules | ≤ 16 (splash) ; **0** sur écrans de travail |
| Precache | compagnons + 1er visuel onboarding + logo splash |
| Mémoire image cache | plafonner ; libérer les écrans hors champ |
| Reprise arrière-plan | contrôleurs en pause au `paused`, reprise < 300 ms |
| Fréquence | **60 fps** (budget 16.6 ms/frame ; viser < 8 ms UI thread en transition) |

### 9.2 Stratégie de dégradation (3 paliers)
| Palier | Déclencheur | Effet |
|---|---|---|
| **A — Plein** | appareil correct, motion ON | tout |
| **B — Allégé** | reprise de frames perdues détectée / batterie éco | particules→0, blur sigma↓ ou off, halos secondaires off |
| **C — Statique** | `MediaQuery.disableAnimations` / appareil faible | fallback statique, transitions = fade 150 ms, aucune boucle |
Détection : `disableAnimations` (immédiat) + heuristique « frames perdues » → bascule B/C
(réglage qualité utilisateur possible). UX-only, aucun impact backend.

---

## 10. (intégré) — voir §4.7, §9, §13 pour les états par surface

---

## 11. TYPOGRAPHIE & NOMBRES

### 11.1 Rampe typographique (polices préchargées uniquement)
| Style | Police | Taille / Poids / Interligne | Usage |
|---|---|---|---|
| Display | Playfair Display | 36 / 700 / 1.15 | grands titres rituels (splash, succès) |
| Hero | Playfair Display | 30 / 700 / 1.12 | titre d'écran fort |
| Titre d'écran | Playfair Display | 28 / 700 / 1.2 | en-tête de hub |
| Titre de section | Playfair Display | 22 / 600 / 1.25 | sections |
| Titre de carte | Montserrat | 18 / 700 / 1.3 | cartes |
| Corps | Montserrat | 16 / 400–500 / 1.5 | texte courant |
| Label | Manrope | 13 / 600 / 1.35 | étiquettes, chips |
| Caption | Montserrat | 12–13 / 400 / 1.35 | secondaire |
| Bouton | Montserrat/Manrope | 15–16 / 700 / 1.0 | actions |
| **Donnée numérique** | Manrope | 20–56 / 800 / 1.0, **tabular** | XP, score, niveau, série |

Wordmark « **Intellia 237** » : Manrope extrabold ; « 237 » peut porter l'accent tricolore
**uniquement** dans le contexte logo/célébration (§12). Bannir « INTELLIA237 » en texte.

### 11.2 Système numérique
| Donnée | Couleur | Animation de valeur | Particularité |
|---|---|---|---|
| XP | `xpGold` | count-up `cinematic`, +Δ flottant qui monte et s'efface | tabular, +N visible |
| Score | primaire / succès | count-up `emphasized` au résultat | /max en caption |
| Niveau | primaire | montée = level-up (§12) | « Niv. N » Manrope 800 |
| Série | `warning` (+ couronne tricolore aux paliers) | incrément `quick` | icône flamme + jours |
| Progression % | primaire | barre + count-up synchronisés | tabular, 0 décimale |
| Temps | neutre | aucune (sauf chrono quiz : tick `quick`) | mm:ss tabular |
| Rang (lycée/Tle) | neutre + accent | apparition `emphasized` | tabular |

Règles : **chiffres tabulaires** partout (pas de saut de largeur) ; count-up plafonné en
durée (≤ 900 ms quel que soit Δ) ; **reduced motion → valeur finale directe**.

---

## 12. IDENTITÉ « 237 » (vert / rouge / jaune)

**Principe : la fierté est tricolore, l'interface ne l'est pas.** Couleur méritée, rare,
jamais chrome.

| Où | Forme | Intensité | Fréquence | Interdit |
|---|---|---|---|---|
| « 237 » du logo | les 3 lettres colorées | pleine | permanent (logo) | hors logo |
| Montée de niveau | balayage tricolore sur l'anneau de niveau | brève (cinematic) | événementiel | en fond |
| Badge de palier majeur | liseré/médaille tricolore | accent | au déblocage | sur badges mineurs |
| Couronne de série (≥ 7, ≥ 30 j) | micro-couronne tri-ton | accent | au palier | sur série quotidienne banale |
| État de réussite important (inscription, fin de parcours) | trait/halo tricolore subtil | discrète | rare | sur succès mineurs |

**Interdits** : fond d'écran, barre de navigation, chrome de carte, corps de texte,
**plus d'un élément tricolore à l'écran**, décor « patriotique » permanent.

---

## 13. ANALYSE ÉCRAN PAR ÉCRAN

Format par écran : **Problème probable · Objectif émotionnel · Focal · Disposition ·
Profondeur · Typo · Entrée/Sortie · Micro-interactions · États · Risque de surcharge ·
Priorité (P0–P3)**. La **homepage = référence, non redessinée**.

**1. Splash** — *Pb* : parité taille logo natif/Flutter à confirmer device. *Émotion* :
promesse, gravité. *Focal* : logo + wordmark. *Dispo* : centré, halo. *Profondeur* :
niv.0 + halo. *Typo* : Display. *Entrée* : depuis natif (même 1er frame). *Sortie* :
Fade Through → onboarding/login. *Micro* : lettres en stagger (déjà). *États* : erreur
init = message + retry (déjà). *Risque* : particules (cap 16). *Priorité* : P3 (déjà bon).

**2. Onboarding** — *Pb* : aucun majeur. *Émotion* : projection, désir. *Focal* : visuel
de scène. *Dispo* : visuel haut / narration bas. *Profondeur* : niv.0 + fond ambiant.
*Typo* : Hero + corps. *Entrée/Sortie* : Shared Axis X entre scènes. *Micro* : stagger
texte, auto-advance 5 s. *États* : reduced motion (figé). *Risque* : ok. *Priorité* : P3.

**3. Choix de profil** *(élève/parent/enseignant/admin)* — *Pb* : cartes possiblement
géométrie 8, affordance à clarifier. *Émotion* : orientation claire. *Focal* : 4 cartes de
rôle. *Dispo* : liste verticale aérée. *Profondeur* : niv.1. *Typo* : Titre carte + corps.
*Entrée* : Fade Through. *Sortie* : Container Transform → inscription du rôle. *Micro* :
pressed + coche. *États* : disabled (rôle indispo) avec raison. *Risque* : surcharge
d'icônes. *Priorité* : **P1**.

**4. Connexion** — *Pb* : géométrie 8, focus champ peu marqué. *Émotion* : confiance,
rapidité. *Focal* : 2 champs + CTA. *Dispo* : centré, CTA en zone du pouce. *Profondeur* :
panneau verre niv.2. *Typo* : Hero + corps. *Entrée* : Shared Axis. *Sortie* : aube si
succès → accueil. *Micro* : label flottant, focus bordure animée, erreur inline. *États* :
loading bouton, erreur (mauvais identifiants), hors-ligne. *Risque* : faible. *Priorité* :
**P1**.

**5. Inscription Élève** — *Pb* : géométrie 8 (pilules corrigées), continuité compagnon
absente vers le succès. *Émotion* : progression maîtrisée, fierté montante. *Focal* :
contenu de l'étape courante. *Dispo* : en-tête + stepper + panneau + actions bas.
*Profondeur* : panneau verre. *Typo* : Hero + corps. *Entrée/Sortie* : Shared Axis entre
étapes ; **Hero compagnon** vers l'écran de succès. *Micro* : pilules `AuthSelectionPill`,
découverte cinématique Kira/Léo (déjà), focus champ. *États* : validation par étape,
erreurs (diagnostic staging), CTA actif seulement si valide. *Risque* : surcharge à
l'étape Compagnon (maîtrisé : une scène à la fois). *Priorité* : **P1**.

**6. Inscription Parent** — *Pb* : cohérence avec l'élève (même système). *Émotion* :
sérénité, contrôle. *Focal* : champs essentiels. *Dispo* : étapes courtes. *Profondeur* :
verre. *Typo* : Hero + corps. *Entrée/Sortie* : Shared Axis. *Micro* : focus, validations.
*États* : idem élève + lien enfant. *Risque* : densité. *Priorité* : **P2**.

**7. Inscription Enseignant/Admin** — *Pb* : ton plus sobre attendu. *Émotion* :
crédibilité institutionnelle. *Focal* : champs pro. *Dispo* : formulaire sobre.
*Profondeur* : verre. *Typo* : Titre + corps (moins « ludique »). *Entrée/Sortie* : Shared
Axis. *Micro* : validations. *États* : permission/établissement. *Risque* : sur-décoration
(à éviter). *Priorité* : **P2**.

**8. Réussite d'inscription** — *Pb* : actuellement fin en sombre → coupure (corrigé pour
l'overflow, pas pour la continuité). *Émotion* : accomplissement, accueil. *Focal* :
compagnon + « Bienvenue, [prénom] ». *Dispo* : centré, scrollable (déjà refait).
*Profondeur* : halo succès. *Typo* : Hero + corps + bouton. *Entrée* : depuis sécurité.
*Sortie* : **AUBE** (§14) vers l'accueil. *Micro* : badge succès, fallback asset (déjà).
*États* : succès. *Risque* : durée aube (cap 1.4 s). *Priorité* : **P2 (moment signature)**.

**9. Hub Apprendre** — *Pb* : mouvement plat, drill-down abrupt. *Émotion* : envie
d'explorer. *Focal* : grille/liste de matières. *Dispo* : en-tête (eyebrow+titre) +
tuiles matière. *Profondeur* : niv.1, gradients matière. *Typo* : Titre d'écran + carte.
*Entrée* : Fade Through (onglet). *Sortie* : **Container Transform** tuile→matière.
*Micro* : pressed, progression par matière. *États* : chargement (squelette grille), vide
(« contenu bientôt » + compagnon), hors-ligne. *Risque* : trop de gradients criards
(modérer). *Priorité* : **P1**.

**10. Matière** — *Pb* : transition d'entrée et hiérarchie chapitres. *Émotion* : clarté du
parcours. *Focal* : liste de chapitres + progression. *Dispo* : en-tête matière (issu du
morph) + chapitres. *Profondeur* : niv.1. *Typo* : Titre d'écran + carte. *Entrée* :
Container Transform (depuis la tuile). *Sortie* : Container Transform → chapitre. *Micro* :
progression, pressed. *États* : chargement, vide, partiellement dispo (chapitres
verrouillés = cadenas + raison). *Risque* : densité en lycée (ok), surcharge en collège
(aérer). *Priorité* : **P1**.

**11. Chapitre** — *Pb* : idem matière. *Émotion* : progression tangible. *Focal* : liste
de leçons + état. *Dispo* : en-tête chapitre + leçons (favori, progression). *Profondeur* :
niv.1. *Typo* : Titre section + corps. *Entrée/Sortie* : Container Transform. *Micro* :
favori (toggle haptique), progression. *États* : complété (célébration sobre), verrouillé.
*Risque* : faible. *Priorité* : **P1**.

**12. Leçon (lecteur)** — *Pb* : confort de lecture, hiérarchie des sections. *Émotion* :
concentration, maîtrise. *Focal* : le contenu (mode lecture). *Dispo* : fine barre de
progression en haut + sections, mini-sommaire ; **réduire le chrome**. *Profondeur* :
niv.0/1 sobre. *Typo* : Titre section + **corps soigné** (interligne 1.5–1.6, mesure
limitée). *Entrée* : Container Transform (depuis la leçon). *Sortie* : pop (lecture
sauvegardée) ; → mini-quiz intégré en Shared Axis. *Micro* : révélation des sections au
scroll, progression synchronisée. *États* : reprise (« continuer où tu t'es arrêté »),
fin de leçon (célébration sobre + suite suggérée). *Risque* : sur-animation pendant la
lecture (interdire). *Priorité* : **P1 (cœur d'usage)**.

**13. Hub Quiz** — *Pb* : mouvement plat. *Émotion* : défi accessible. *Focal* : liste de
quiz (difficulté, durée). *Dispo* : en-tête + cartes quiz. *Profondeur* : niv.1. *Typo* :
Titre d'écran + carte. *Entrée* : Fade Through. *Sortie* : **Container Transform**
quiz→jeu. *Micro* : pressed, badge difficulté. *États* : chargement, vide, hors-ligne.
*Risque* : faible. *Priorité* : **P1**.

**14. Quiz en cours** — *Pb* : feedback de réponse à dramatiser, momentum. *Émotion* :
tension positive, flow. *Focal* : la question + options. *Dispo* : question haut, options,
progression/chrono ; CTA dans la zone du pouce. *Profondeur* : niv.1, options niv.1.
*Typo* : Titre section (question) + bouton (options). *Entrée* : Container Transform.
*Sortie* : Shared Axis entre questions ; → résultat (emphasized). *Micro* : **juste** =
éclosion verte + check + `lightImpact` ; **faux** = secousse + croix + `heavyImpact` ;
**compteur de momentum** ; explication révélée. *États* : abandon (sheet de confirmation),
fin. *Risque* : surcharge d'effets par réponse (1 effet max). *Priorité* : **P1**.

**15. Résultat du quiz** — *Pb* : moment d'émotion peu exploité. *Émotion* : fierté,
envie de recommencer. *Focal* : **le score** (compte à rebours animé). *Dispo* :
« bulletin » : score → XP gagné → badges → corrections. *Profondeur* : niv.1 + halo
succès. *Typo* : Display (score) + corps. *Entrée* : emphasized depuis le quiz. *Sortie* :
retour hub (Shared Axis) ou rejouer (Container Transform). *Micro* : count-up score,
remplissage XP, **révélation de badge** (sobre, sans confetti bruyant), level-up si
atteint (§12). *États* : échec (ton bienveillant + « réessaie »), parfait (célébration
tricolore mesurée). *Risque* : empilement de célébrations (file d'attente). *Priorité* :
**P2 (moment émotionnel)**.

**16. Flow** — *Pb* : aucun majeur (déjà premium). *Émotion* : curiosité, élan. *Focal* :
la carte plein écran. *Dispo* : pager vertical, HUD discret. *Profondeur* : niv.0 +
visuels. *Typo* : Hero/corps selon carte. *Entrée* : depuis carte d'accueil (Container
Transform possible). *Sortie* : quitte → Accueil. *Micro* : célébrations XP/badge sobres,
dwell-award. *États* : fin de feed (« reviens demain »). *Risque* : déjà cadré. *Priorité* :
P3 (ancrer la cohérence avec le reste).

**17. Kira/Léo (compagnon IA)** — *Pb* : présence et états de « réflexion » à donner.
*Émotion* : compagnonnage, confiance. *Focal* : la conversation. *Dispo* : avatar réactif +
bulles + suggestions (chips). *Profondeur* : niv.1, avatar niv.2. *Typo* : corps soigné.
*Entrée* : Fade Through (onglet). *Sortie* : — . *Micro* : état « réfléchit… » (3 points),
avatar qui réagit, chips de questions. *États* : vide (suggestions d'amorce), hors-ligne,
quota/erreur (ton bienveillant). *Risque* : sur-animation de l'avatar (sobriété surtout en
Terminale). *Priorité* : **P2**.

**18. Profil** — *Pb* : tuiles stats en texte ordinaire (P-4). *Émotion* : fierté de soi.
*Focal* : identité + « tableau de toi ». *Dispo* : carte d'identité + sections (académique,
compagnon, stats). *Profondeur* : niv.1. *Typo* : Titre section + **numérique tabular**.
*Entrée* : Fade Through. *Sortie* : sheets (réglages, changement de tuteur). *Micro* :
anneau d'avatar (déjà), valeurs animées. *États* : chargement, erreur. *Risque* :
faible. *Priorité* : **P2**.

**19. Statistiques** — *Pb* : lisibilité et hiérarchie des nombres. *Émotion* : progrès
mesurable. *Focal* : XP/niveau/série/progression. *Dispo* : anneaux + barres + tuiles
numériques, **densité selon maturité**. *Profondeur* : niv.1. *Typo* : Display numérique +
label. *Entrée* : Fade Through. *Sortie* : drill-down vers détail (maîtrise par thème en
lycée). *Micro* : count-up, anneaux animés, série tricolore aux paliers. *États* : vide
(« commence pour voir tes stats »). *Risque* : trop de données en collège (simplifier).
*Priorité* : **P2**.

**20. Paramètres** — *Pb* : souvent « écran technique ». *Émotion* : contrôle serein.
*Focal* : groupes de réglages clairs. *Dispo* : listes sectionnées (compte, préférences,
**accessibilité** : reduced motion / son / vibrations / taille texte, à propos).
*Profondeur* : niv.1. *Typo* : Titre section + corps. *Entrée* : push Shared Axis. *Sortie*
: pop. *Micro* : toggles haptiques. *États* : déconnexion (confirmation). *Risque* :
faible. *Priorité* : **P2** (héberge les options accessibilité/son — important).

**21. États hors-ligne & erreurs (transversal)** — *Pb* : risque d'écrans techniques.
*Émotion* : réassurance. *Focal* : message + action. *Dispo* : illustration compagnon
sobre + titre court + action principale (+ secondaire). *Profondeur* : niv.0. *Typo* :
Titre section + corps. *Entrée/Sortie* : Fade Through. *Micro* : retry (haptique).
*États* : hors-ligne, erreur, session expirée, permission refusée, premium verrouillé.
*Risque* : sur-illustration. *Priorité* : **P0 (doctrine commune)**.

---

## 14. TRANSITION SIGNATURE « AUBE » (réussite → accueil)

**Objectif** : émotionnel **mais rapide**. **Durée totale ≤ 1.4 s** (cap dur).
Prérequis technique : orchestrer la transition (route custom / couche de transition) car
un simple `redirect` GoRouter ne propage pas le Hero — à prévoir côté implémentation.

| Temps | Compagnon | Fond | Halo | Texte | Bouton | Couleur |
|---|---|---|---|---|---|---|
| 0.00 s (tap CTA) | dans le halo de succès | nuit #080722 | succès vert | « Bienvenue » visible | « Découvrir Intellia 237 » | sombre |
| 0.00–0.15 | léger recul/scale | — | pulse bref | sous-titre **fond out** (120 ms) | scale+fade out | — |
| 0.15–0.60 | devient **Hero**, commence sa trajectoire vers la position avatar de l'accueil, scale ↓ | **morph nuit → crème** #FBFAF7 (cross-fade gradient) | succès **se dissout** | titres effacés | absent | sombre→clair |
| 0.40–0.90 | poursuit la trajectoire | balayage de **lumière chaude** haut→bas (lever) | halos sombres out / halos clairs in | — | — | clair |
| 0.60–1.00 | **atterrit** comme avatar de l'accueil | crème stable | — | — | — | clair |
| 1.00–1.40 | posé | accueil | — | contenu accueil en **entrée staggered** (existant) | — | clair |

- **Haptique** : `mediumImpact` au tap ; `selectionClick` à l'arrivée.
- **Reduced motion** : **fondu sombre→clair 250 ms**, compagnon apparaît en place (pas de
  vol), pas de balayage. Total ≤ 300 ms.
- **Risque de ralentissement** : morph fond + Hero + entrée accueil = jusqu'à 3 anim
  simultanées (limite). **Précharger/préparer l'accueil** avant de lancer l'aube ; si le
  budget de frame est dépassé, **sacrifier le balayage** (garder morph + Hero). Jamais > 1.4 s.

---

## 15. CONTAINER TRANSFORM — prototypes prioritaires

| Cas | Source | Cible | Propriétés partagées | Disparaît | Apparaît | Durée | Direction | Retour | Reduced motion |
|---|---|---|---|---|---|---|---|---|---|
| Matière → détail | tuile matière (rect, gradient, titre, icône) | écran matière | rect, gradient, **titre**, icône | autres tuiles (fade) | chapitres, en-tête détail | emphasized 420 | expansion depuis la tuile | collapse vers la tuile | cross-fade 200 ms |
| Chapitre → détail | carte chapitre | écran chapitre | rect, couleur, titre, progression | siblings | leçons | emphasized 420 | expansion | collapse | cross-fade 200 ms |
| Leçon → lecteur | ligne/tuile leçon | lecteur | rect, titre, progression | liste | contenu sections | emphasized 450 | expansion | collapse | cross-fade 200 ms |
| Quiz → jeu | carte quiz | quiz en cours | rect, titre, difficulté | hub | 1re question | emphasized 420 | expansion | collapse (confirmation si en cours) | cross-fade 200 ms |
| Badge → détail | médaille badge | feuille détail badge | rect, médaille, couleur | grille badges | description, critères | emphasized 380 | expansion | collapse | cross-fade 180 ms |

Règle commune : l'élément partagé (rect + titre + couleur) **persiste et se transforme** ;
le reste de l'écran source **fond out**, le contenu cible **fond in** après ~60 % de la
durée. Retour = inverse exact ; pour « quiz en cours », le retour passe par la sheet
d'abandon.

---

## 16. DESIGN SYSTEM & GOUVERNANCE

### 16.1 Structure des tokens (source unique de vérité)
`color` (rôles §4.1) · `surface` (3 niveaux §4.2) · `radius` (§4.3) · `shadow` (§4.4) ·
`type` (§11) · `spacing` (§4.5) · `motion` (§6.1) · `haptic` (§7) · `icon` · `illustration`
(Kira/Léo) · `state` (§6.4) · `component` (§4.6). Un seul fichier de tokens fait foi ;
les écrans **consomment** les tokens, n'inventent pas de valeurs (fin des `circular(8)`
isolés).

### 16.2 Checklist de validation par écran (Definition of Done UX)
- [ ] **Identité** : palette/typo/rayons/profondeur = famille homepage.
- [ ] **Lisibilité** : contrastes AA, texte blanc sur clair = halo.
- [ ] **Action** : chaque interactif a surface + pressed + haptique ; pas de fausse affordance.
- [ ] **Navigation** : transition correcte selon la relation (§5.4) ; retour cohérent.
- [ ] **Responsive** : 320 / 360 / 390 / 430 ; texte 1.3 et 1.5 sans clipping ; colonne ≤ 480.
- [ ] **Performance** : ≤ 1 backdrop plein écran, ≤ 3 anims continues, images précachées.
- [ ] **Accessibilité** : Semantics, ordre de lecture, couleur jamais seule, cibles ≥ 48 dp.
- [ ] **États** : chargement/vide/erreur/hors-ligne définis et non techniques.
- [ ] **Reduced motion** : substitutions présentes (§8.1).
- [ ] **Cohérence homepage** : l'écran « appartient » visuellement à l'accueil.

---

## 17. BACKLOG PRIORISÉ

> Ne pas tout modifier en même temps. P0 = fondations transverses ; P1 = écrans quotidiens ;
> P2 = moments émotionnels ; P3 = polish/identité.

### P0 — Cohérence & structure
| Item | Impact | Effort | Dépendances | Risque | Écran(s) | Validation |
|---|---|---|---|---|---|---|
| Unifier la géométrie (8 → 16/22) | élevé | moyen | tokens | bas | auth, choix profil | aucun `circular(8)` résiduel |
| Fichier de tokens unique + consommation | élevé | moyen | — | moyen | tous | écrans sans valeurs en dur |
| Grammaire de mouvement (helpers Shared Axis / Fade Through / Container Transform) | élevé | moyen | tokens | moyen | tous | helpers réutilisés ≥ 3 écrans |
| Doctrine d'états (loading/vide/erreur/offline) | élevé | moyen | illustrations | bas | transversal | composant d'état réutilisé |
| Système numérique (tabular + count-up) | élevé | faible | tokens | bas | stats, quiz, profil | nombres tabulaires + animés |
| Règle overlays non bloquants | moyen | faible | — | bas | tours/sheets | tout overlay dismissible |

### P1 — Écrans quotidiens
| Item | Impact | Effort | Dépendances | Risque | Écran | Validation |
|---|---|---|---|---|---|---|
| Container Transform matière→détail | élevé | moyen | grammaire P0 | moyen | Apprendre/Matière | morph fluide ≤ 420 ms, retour ok |
| Chapitre & leçon en drill-down | élevé | moyen | ci-dessus | moyen | Chapitre/Leçon | continuité du morph |
| Mode lecture du lecteur de leçon | élevé | moyen | typo | bas | Leçon | chrome réduit, lecture confortable |
| Feedback juste/faux du quiz | élevé | faible | motion P0 | bas | Quiz | 1 effet/réponse, haptique |
| Connexion / choix profil alignés | moyen | faible | géométrie P0 | bas | Login/Profil | famille homepage |

### P2 — Moments émotionnels
| Item | Impact | Effort | Dépendances | Risque | Écran | Validation |
|---|---|---|---|---|---|---|
| Transition « aube » succès→accueil | élevé | élevé | Hero/route custom, accueil préchargé | élevé | Succès→Accueil | ≤ 1.4 s, fluide, reduced ok |
| Bulletin de résultat de quiz | élevé | moyen | numérique P0 | moyen | Résultat | count-up + badge sobre |
| Présence du compagnon IA | moyen | moyen | — | bas | Kira/Léo | état « réfléchit », chips |
| « Tableau de toi » (profil/stats) | moyen | moyen | numérique P0 | bas | Profil/Stats | anneaux + tabular |

### P3 — Polish & identité
| Item | Impact | Effort | Dépendances | Risque | Écran | Validation |
|---|---|---|---|---|---|---|
| Fil « 237 » (fierté tricolore) | moyen | faible | célébrations | moyen | level-up/badge/série | tricolore rare et cadré |
| Lockup de marque « Intellia 237 » | moyen | faible | — | bas | tous | plus de « INTELLIA237 » texte |
| Lueur d'overscroll de marque | faible | faible | — | bas | listes | discret, ≤ 8 px |
| Remplacement logo image (forme du wordmark) | faible | faible | design asset | bas | logo | asset conforme |

---

## 18. PROTOTYPES RECOMMANDÉS (3) + ordre

1. **Container Transform « matière → détail »** *(premier)*.
2. **Transition « aube » succès → accueil**.
3. **Bulletin de résultat de quiz (XP + badge)**.

**À construire en premier : le Container Transform matière → détail.** Raisons :
- **Réutilisation maximale** : il établit la **grammaire de descente** (élément partagé +
  fade in/out) réemployée ensuite par chapitre, leçon, quiz, badge **et** par l'aube (qui
  repose sur la même mécanique d'élément partagé/Hero). C'est la **fondation** des autres
  prototypes.
- **Risque maîtrisé** : pas de cross-route ni de contrainte de perf simultanée comme l'aube
  (jugée P2/élevée). On valide la mécanique sur un cas simple avant le moment signature.
- **Impact quotidien immédiat** : il améliore un parcours **à fort usage** (Apprendre), pas
  un moment unique.
L'**aube** vient **ensuite** (elle réutilise la mécanique d'élément partagé éprouvée), puis
le **bulletin de quiz**.

---

## 19. CRITÈRES D'ACCEPTATION

### 19.1 Globaux
- Aucune valeur géométrique/typo/couleur en dur hors tokens ; **aucun `circular(8)`**.
- Toute navigation respecte la table relation→transition (§5.4).
- Tout interactif : surface + pressed + haptique ; **zéro fausse affordance**.
- Contrastes AA, cibles ≥ 48 dp, texte 1.3 et 1.5 sans clipping.
- ≤ 1 backdrop plein écran, ≤ 3 animations continues, ≤ 1 cinematic simultané.
- Reduced motion : substitutions présentes ; aucune boucle/morph résiduel.
- Nombres tabulaires + animés ; **« Intellia 237 »** comme seul texte de marque.
- Chaque écran passe la checklist §16.2.

### 19.2 Par prototype
- **Matière→détail** : morph fluide (≤ 420 ms), élément partagé continu (titre/couleur),
  retour = collapse exact, reduced motion = cross-fade 200 ms, 60 fps maintenu.
- **Aube** : ≤ 1.4 s, morph nuit→crème sans flash, Hero compagnon arrivant à la position
  avatar de l'accueil, reduced motion = fondu 250 ms, jamais de blocage de taps.
- **Bulletin quiz** : score count-up (≤ 900 ms), XP qui se remplit, badge révélé sans
  effet bruyant, level-up tricolore seulement si atteint, reduced motion = valeurs directes.

---

## PROCHAINE ACTION (unique)

**Construire d'abord le prototype « Container Transform : tuile matière → écran matière »**
(P1), car il pose la grammaire de descente réutilisée par tous les autres écrans
quotidiens **et** par la transition « aube » — c'est la fondation à valider avant toute
généralisation. Les deux autres prototypes (aube, bulletin de quiz) s'appuieront dessus.
