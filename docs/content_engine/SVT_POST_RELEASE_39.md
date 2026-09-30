# SVT Terminale D — post-release +39

## Récupération

Stash identifié par son nom `svt-source-pre-build-38`, puis inspecté avec
`git stash show -u --name-status`. Les deux fichiers SVT étaient dans le
troisième parent. Restauration limitée à `corpus_index.json` et
`sequence_01_les_echanges_cellulaires_source.json` via
`git restore --source=stash@{1}^3 --worktree -- <les deux chemins>`.
Aucun pop, aucune restauration Auth/release.

## Séquence 1 livrée

Pack canonique `m1_s1_les_echanges_cellulaires` : manifest, source, pedagogy,
runtime et validation_report. **5 leçons, 14 concepts, 46 activités dérivées** :
38 corrigibles automatiquement et 8 productions avec modèle et critères
d'autoévaluation. Le Quiz S1 utilise les 38 questions éligibles.

Cours p.3–14 et exercices p.15–21 : 15 images inspectées, 29 groupes et
79 consignes/sous-consignes inventoriées. Le source distingue l'énoncé du
manuel, la réponse soutenue, la justification et l'action runtime. Les
numéros d'images et de pages imprimées sont deux index distincts.

Six familles de réserves sont conservées : masse atomique O imprimée
ambiguë, QCM osmose/dialyse contradictoire, terminologie de membrane, graphes
ne permettant pas de valeurs exactes, légendes/mitochondrie peu lisibles,
limites du modèle médical. Quatre familles demandent une revue source ;
deux anomalies de formulation/quantification sont confirmées. Les valeurs
ambiguës, annotations manuscrites et prescriptions cliniques ne deviennent
pas des clés notées.

Les matières/classe, assets embarqués, Learn et Quiz utilisent les providers
existants. SVT est accessible pour Terminale D. Les tests de catalogue et du
Compagnon ont été actualisés pour cette quatrième matière. Aucun pack SVT
n'est servi à Terminale C/A ou Première D.

## Vérifications

Validation des packs, tests S1, catalogue Terminale D, catalogue Quiz, Learn
UI et Compagnon : inclus dans une suite de **152 tests réussis**, avec les
régressions Profil/Flow. Les tests S1 vérifient les empreintes, nombres à
virgule, signes, mots accentués et apostrophes, choix mélangés, feedbacks
distincts, inventaire et exclusions. Le rapport global complète analyze et
les suites finales.

## Production S2–S19

Les bornes du tableau viennent du corpus récupéré. Elles ne constituent pas
une validation des pages encore non inspectées. Chaque séquence suit le même
pipeline, sans génération massive.

Ordre : S2 seule, puis S3 seule (reproduction), S4–S5 (génétique), S6–S8
(coordination) après validation de chaque séquence. Ensuite modules 2, 3 et
4. Les séquences longues sont découpées en extraction cours, inventaire des
exercices, puis dérivation runtime ; chaque étape est versionnée séparément.

Portes de qualité : inspection de toutes les images du lot ; traçabilité des
consignes ; réponse autoritaire ou NEEDS_SOURCE_REVIEW ; notions/leçons et
difficultés explicites ; retours spécifiques ; aucune autoévaluation
objective ; empreintes et validation propres ; tests de notation/catalogue
et UI étroite ; commit distinct avant le lot suivant.

La suite commence par un petit lot de source S2 p.23–29 après S1 verte.
S2–S19 ne sont pas déclarées livrées dans Learn/Quiz. La source S2 partielle
n'est pas un runtime proposé aux élèves.

| Lot | Séquence | Début cours imprimé | Début exercices |
|---|---|---:|---:|
| module_1 | sequence_2 — Quelques aspects du métabolisme énergétique chez l’Homme | 23 | 37 |
| module_1 | sequence_3 — Mécanismes fondamentaux de la reproduction sexuée chez les mammifères et chez les spermaphytes | 43 | 63 |
| module_1 | sequence_4 — Brassage génétique au cours de la reproduction sexuée et unicité génétique des individus | 70 | 97 |
| module_1 | sequence_5 — La prévision en génétique humaine | 105 | 122 |
| module_1 | sequence_6 — Les activités réflexes | 130 | 152 |
| module_1 | sequence_7 — Le fonctionnement des neurones | 163 | 195 |
| module_1 | sequence_8 — Activités cérébrales et motricité volontaire | 208 | 230 |
| module_2 | sequence_9 — Les mécanismes de l’immunité | 238 | à localiser |
| module_2 | sequence_10 — Les dysfonctionnements du système immunitaire | 257 | 266 |
| module_2 | sequence_11 — La santé reproductive | 274 | 303 |
| module_2 | sequence_12 — La santé nutritionnelle | 314 | 337 |
| module_2 | sequence_13 — Le secourisme | 353 | 359 |
| module_3 | sequence_14 — Les mouvements de la lithosphère et leurs conséquences sur l’Environnement | 364 | 385 |
| module_3 | sequence_15 — L’évolution de l’Homme | 390 | 408 |
| module_4 | sequence_16 — Transformation et conservation des fruits de saison | 417 | 423 |
| module_4 | sequence_17 — L’entomophagie | 427 | 436 |
| module_4 | sequence_18 — Les énergies renouvelables | 442 | 448 |
| module_4 | sequence_19 — Valorisation des déchets de l’Environnement de l’Homme | 452 | 460 |
