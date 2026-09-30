# Blocs d’apprentissage interactifs (ILB)

État au 21 septembre 2026, branche `fix/release-hardening-sep2026`,
commits `21d5069` (serveur), `37571d6` (module), `1c9f58c` (conversation).

## Principe

Kira ou Léo peuvent joindre **une** activité courte à leur réponse. Le modèle
propose un **contenu** ; il ne choisit jamais une interface, une route, une
action serveur ni un composant. L’application décide seule du rendu, avec ses
propres widgets. Jamais de HTML, jamais de code.

```
Modèle ──texte + <<<ACTIVITY {json} ACTIVITY>>>──▶ askTutor
askTutor : retire le bloc du texte, valide, fabrique les identifiants
        ──{ text, block? }──▶ téléphone
téléphone : relit strictement, rend, corrige hors ligne
        ──activityOutcome (au message suivant)──▶ askTutor ──▶ le compagnon s’adapte
```

## Primitives et types

Une primitive = une mécanique ; un type = son usage par matière.

| Primitive | Types | Rendu livré |
| --- | --- | --- |
| `ordering` (en ligne) | `word_order` | **oui** : tuiles, toucher-déplacer et glisser-déposer |
| `ordering` (empilé) | `step_order`, `equation_order`, `timeline_order`, `process_sequence`, `sequence` | **oui** : étapes avec monter / descendre |
| `choice`, `binary`, `gap_fill`, `pairing`, `grouping`, `numeric`, `labeling`, `map`, `data` | `multiple_choice`, `true_false`, `fill_blank`, `matching`, `classification`, `numeric_input`, `diagram_labeling`, `map_interaction`, `data_interpretation`, … | non : annoncés dans le registre, **refusés** tant qu’aucun rendu n’existe |

Registre serveur : `BLOCK_TYPES` dans `functions/src/llm/interactiveBlocks.ts`.
Registre client : `InteractiveBlockType` dans
`lib/features/interactive_learning/domain/interactive_block.dart`. Un test
fige la liste des types rendus côté client.

## Choix par matière

Le prompt système donne une politique de sélection (`SELECTION_POLICY`, FR et
EN) ; le client a son équivalent (`InteractionPolicy.preferredTypesFor`) pour
les usages hors conversation :

- langues : `word_order` ;
- mathématiques : `equation_order` ;
- histoire : `timeline_order` ;
- SVT : `process_sequence` ;
- physique, chimie : `step_order` ou `equation_order` ;
- géographie, philosophie, littérature : `sequence`.

`word_order` n’est jamais proposé en mathématiques, histoire, SVT ou physique
(testé).

## Négociation

Le téléphone déclare dans `activities` les types qu’il sait rendre
(`InteractiveBlockType.supportedWireNames`). Le serveur n’annonce au modèle
que l’intersection avec ses types livrés. Une ancienne version sans
`activities` ne reçoit **aucune** consigne d’activité, donc aucun bloc.

## Validation serveur (`extractInteractiveBlock`)

Refus avec motif journalisé, le texte restant servi :
`activities_not_negotiated`, `unterminated`, `too_large` (> 4 000 caractères
bruts), `invalid_json`, `invalid_schema`, `unknown_type`, `type_not_allowed`,
`type_not_rendered`, `item_count`, `item_length`, `marker_in_item`,
`not_orderable`, `trailing_on_stacked`, `id_collision`.

Bornes : consigne 160 ; en ligne 2 à 10 éléments de 24 caractères ; empilé 2
à 8 éléments de 140 ; 3 indices de 160 ; explication 400. Le modèle ne fournit
qu’une séquence de textes dans le bon ordre : **le serveur fabrique les
identifiants** des éléments et du bloc, jamais le modèle.

## Relecture client

`InteractiveLearningBlock.tryParse` est strict : version 1, type rendu,
identifiants uniques, solution permutation exacte des éléments, textes
bornés, 6 000 caractères au plus sérialisé. Tout écart renvoie `null` et seule
la réponse texte s’affiche.

## Correction hors ligne

Pour ces activités d’entraînement, la solution voyage vers le téléphone
(décision A). `OrderingSession` :

- compare par **identifiant**, avec équivalence explicite des textes
  identiques (deux « I » sont interchangeables) ;
- mélange sans jamais partir de la solution, avec une source aléatoire
  injectable pour les tests ;
- compte essais et indices ; indices du compagnon d’abord, puis la position à
  revoir ; solution proposée après 3 essais, sans compter une réussite ;
- ponctuation finale (`trailing`) affichée hors des tuiles pour `word_order`.

Une évaluation **notée** devra passer par une clé de correction serveur,
comme les quiz (décision B) : non livré.

## Conversation

- Le bloc est stocké avec le message dans l’historique local : il survit à un
  redémarrage et se rejoue hors ligne.
- Rendu sous la réponse du compagnon, gardé vivant au défilement.
- Le résultat (`blockId`, type, réussi, essais, indices, solution montrée ;
  jamais la durée) part **une fois** avec le message suivant ; il est conservé
  si l’envoi échoue, pour la relance. Côté serveur, il devient une phrase
  factuelle dans le prompt utilisateur : le compagnon s’appuie sur la réussite
  ou réexplique la difficulté précise. Ce n’est jamais une note.
- Aucune écriture dans la maîtrise.

## Réutilisation

`InteractiveBlockView` ne dépend d’aucun fournisseur ni du réseau : il peut
être posé dans Parcours, une leçon, une révision ou un quiz en lui passant un
bloc et un compagnon.

## Reste à faire

- Rendus des primitives annoncées (choix, texte à trous, association, tri).
- Blocs rédigés dans le Studio (même schéma, validés par le même code serveur).
- Correction serveur pour un usage noté.
- Capture sur appareil réel à 360 px, clavier et lecteur d’écran (TalkBack).
