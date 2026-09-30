# Établissements : catalogue de référence et choix à l'inscription

État au 28/09/2026 (branche `feat/content-engine`).

## Deux notions distinctes

| | Établissement de référence | Établissement partenaire |
|---|---|---|
| Source | catalogue embarqué (`assets/data/establishments/`) | serveur (`listRegistrationEstablishments`) |
| Rôle | permettre à l'élève de dire où il étudie | établissement réellement connecté à INTELLIA |
| Badge « Partenaire INTELLIA » | jamais | oui, seulement si le serveur le dit |
| Droits | aucun | aucun non plus au choix : le serveur seul écrit `establishmentId` après vérification |

Choisir un établissement n'écrit qu'une métadonnée descriptive,
`preferences.establishmentCandidate` : `candidateId`, `name`, `city`,
`region`, `district`, `source` (`partner` | `catalogue` | `suggestion`),
`status` (`pendingVerification`). Les règles Firestore ne contraignent pas la
forme de cette carte : les nouvelles clés `district` et `source` ne demandent
**aucun** changement de règles ni déploiement.

## Chaîne de données

```
tool/establishments/sources/base_maitresse_…_2026_09.xlsx   (feuille « Base maîtresse » seule)
tool/establishments/sources/owner_additions_2026_09.json     (alias et ajouts du propriétaire)
lib/…/data/establishment_catalog.dart                        (catalogue historique, 100 entrées, identifiants stables)
        │  dart run tool/establishments/import_master_catalog.dart
        ▼
tool/establishments/sources/base_maitresse_2026_09.csv       (instantané lisible de la source)
assets/data/establishments/cameroon_secondary_2026_09.json   (catalogue versionné, schéma intellia.establishments.v1)
tool/establishments/reports/review_signals_2026_09.md        (rapprochements à relire, jamais fusionnés)
```

- `--check` échoue si un fichier versionné ne correspond plus à la source ; le
  test `establishment_directory_test.dart` fait la même vérification en CI.
- Les feuilles « Yaoundé » et « Douala » du classeur sont des vues de la Base
  maîtresse : elles ne sont pas importées (pas de double compte).
- Union contrôlée : le catalogue historique garde ses identifiants ; une ligne
  de la Base maîtresse reconnue (même nom canonique et même ville, ou même
  arrondissement) enrichit l'entrée existante au lieu d'en créer une seconde.
- Nom canonique (`SchoolNameCanon`) : minuscules, sans accents, tirets et
  apostrophes neutralisés, chiffres romains unifiés (« 2 » = « II »), mots de
  liaison retirés, sigle entre parenthèses gardé comme alias, ville répétée en
  fin de nom retirée. Identité = nom canonique + ville.
- Un rapprochement approximatif n'est jamais une fusion : il est écrit dans le
  rapport de relecture.
- La provenance (source, confiance, lien) reste interne : elle n'est jamais
  affichée à l'élève.

## Chiffres (import du 28/09/2026)

- Base maîtresse : 250 lignes (Yaoundé 118, Douala 132).
- Catalogue : 339 établissements = 100 historiques + 250 + 2 ajouts − 13
  reconnus dans l'historique.
- Yaoundé 121, Douala 135 ; « Collège LE SAVOIR » sans ville connue.
- Corpus de référence Yaoundé/Douala : 252 (250 + MBOHMELITES + LE SAVOIR).
- 7 rapprochements à relire (Ekounou, Nkol-Eton, New-Bell, Mongo Joseph, GBHS
  et GHS de Bamenda, Kumba, Limbe).

Cas particuliers :

- « Collège MARIE-ALBERT » est un alias de « Collège Privé Laïc Marie Albert II
  (COMAL II) », une seule entrée. Son arrondissement reste vide : le classeur
  indique « À confirmer », le propriétaire « Yaoundé IV » ; à trancher.
- « MBOHMELITES BILINGUAL COLLEGE » : Yaoundé, Yaoundé VII, bilingue, déclaré
  par le propriétaire.
- « Collège LE SAVOIR » : nom exact, ville, région, arrondissement, langue et
  statut inconnus (null). Jamais fusionné avec « Collège Bilingue Échos du
  Savoir » (Douala). « Le Savoir Plus » n'est pas ajouté.

## Annuaire et recherche dans l'application

- `referenceEstablishmentsProvider` lit le catalogue embarqué une fois par
  session ; s'il était illisible, le catalogue historique compilé prend le
  relais.
- `schoolDirectoryProvider` fusionne les partenaires serveur par identifiant ou
  par identité exacte (`asPartner` garde l'identifiant serveur et
  `referenceId`) ; un partenaire inconnu du catalogue est ajouté tel quel.
  Hors ligne, la recherche reste complète, sans badge.
- `EstablishmentSearch` : aucune requête réseau par frappe ; formes pliées
  calculées une fois par établissement ; tolère accents, tirets, apostrophes,
  espaces manquants ou en trop (« nkolbisson » / « nkol bisson »), chiffres
  romains, alias, ville, arrondissement, mots dans le désordre et fautes
  légères. Le meilleur résultat est mis en avant, jamais choisi d'office.
- À l'inscription, le dépôt accepte un identifiant du catalogue ou d'un
  partenaire, ou une proposition sans identifiant (`source: suggestion`) ;
  tout autre identifiant est refusé (`invalid-establishment`).

## Choix d'établissement (élève)

- Étape « passeport » : une carte « TON ÉTABLISSEMENT » ouvre l'écran de
  choix ; après sélection, une carte de confirmation (nom, ville ·
  arrondissement, badge partenaire éventuel) avec « Changer ».
- Écran de choix : champ de recherche, capsules Yaoundé / Douala / Toutes
  (villes les plus fournies de l'annuaire), cartes de résultat (nom sur deux
  lignes, partie trouvée surlignée, deux repères confirmés au plus), vibration
  légère et coche à la sélection. Clavier ouvert sur petit écran : le titre
  s'efface.
- Aucun résultat : « Ton établissement n'apparaît pas ? » → « Proposer mon
  établissement » (nom, ville, arrondissement facultatif), enregistré comme
  proposition à vérifier. Filtré sur une ville, l'écran propose d'abord de
  chercher dans toutes les villes.
- L'application est aujourd'hui forcée en thème clair ; le choix
  d'établissement a néanmoins sa palette sombre, testée.

## Mettre à jour le catalogue

1. Déposer le nouveau classeur dans `tool/establishments/sources/`.
2. Ajuster `owner_additions_…json` si besoin (alias, ajouts, sans métadonnée
   inventée).
3. `dart run tool/establishments/import_master_catalog.dart --xlsx <classeur>`
4. Relire `reports/review_signals_….md`, puis `flutter test
   test/features/student_registration/`.

## Reste à faire

- Trancher l'arrondissement de COMAL II et compléter LE SAVOIR.
- Côté administration : traiter les propositions (`source: suggestion`) et
  relier un élève à un établissement partenaire.
- Validation sur Android physique : vibration légère à la sélection.
