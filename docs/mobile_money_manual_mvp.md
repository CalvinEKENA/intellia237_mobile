# Mobile Money manuel — MVP sécurisé

Ce module ne déclenche aucun débit et ne contacte aucun opérateur. Le parent effectue lui-même le transfert, puis déclare le numéro payeur et la référence. Un administrateur de son établissement compare manuellement cette déclaration avec le portail opérateur avant d’activer l’accès.

## Configuration serveur obligatoire

L’offre d’un établissement est le document `mobile_money_offers/{establishmentId}`. Il doit être créé depuis un environnement d’administration de confiance (console Firebase, script Admin SDK ou futur back-office serveur), jamais depuis l’application Flutter.

Champs requis :

- `status`: `active` ;
- `establishmentId`: identique à l’identifiant du document ;
- `title` et `description` ;
- `amountXaf`: entier compris entre 100 et 10 000 000 ;
- `currency`: `XAF` ;
- `durationDays`: entier compris entre 1 et 730 ;
- `operators`: liste de 1 à 8 objets contenant `code`, `label`, `recipientPhone` et, facultativement, `instructions`.

Le montant, la durée et les numéros bénéficiaires ne sont jamais présents dans le code Flutter. Si le document est absent, inactif ou invalide, l’interface affiche explicitement « Offre indisponible ».

## Parcours parent

1. La callable authentifiée `getMobileMoneyOverview` détermine l’établissement depuis le compte parent ou ses liens enfant approuvés, puis projette l’offre active.
2. Le parent réalise le transfert hors d’Intellia237.
3. `submitMobileMoneyPayment` accepte uniquement un compte parent, valide strictement le téléphone camerounais, l’opérateur configuré, la référence et la clé d’idempotence.
4. La demande reste `pending`. Une empreinte de référence empêche sa réutilisation ; la référence brute n’est jamais utilisée comme identifiant et n’est jamais envoyée à Analytics ni écrite dans les logs applicatifs.

Lorsque plusieurs établissements sont liés au même parent, aucune offre n’est choisie arbitrairement : l’interface demande de contacter l’assistance.

## Validation établissement

`listMobileMoneyPayments` et `reviewMobileMoneyPayment` sont limitées aux rôles `admin`/`superAdmin` actifs dont `establishmentId` correspond exactement à celui de la demande. Même un `superAdmin` sans établissement correspondant ne peut pas valider la demande.

Une approbation crée ou prolonge `entitlements/{parentId}_{establishmentId}` avec une date de fin calculée depuis la durée capturée lors du dépôt. Elle ne modifie jamais le rôle, les permissions, les custom claims ou l’établissement du compte. Une seconde approbation identique est une relecture idempotente et ne prolonge pas deux fois l’accès.

## Collections et accès

- `mobile_money_offers`: accès direct client interdit ;
- `mobile_money_payment_requests`: lecture limitée au parent propriétaire ou à l’admin du même établissement ; toute écriture client est interdite ;
- `mobile_money_reference_keys`: tout accès client interdit ;
- `entitlements`: lecture limitée au bénéficiaire ou à l’admin du même établissement ; toute écriture client est interdite.

Les références et téléphones sont des données sensibles : ne pas les inclure dans Analytics, Crashlytics, les traces, les captures de support ou les exports non protégés. Définir avant production une durée de conservation, une procédure de suppression et un accès opérateur conforme aux règles de l’établissement.

## Mise en service

Avant ouverture aux familles :

1. créer et relire la configuration de chaque établissement ;
2. tester les règles et callables dans les émulateurs Firebase ;
3. valider la procédure humaine de rapprochement avec chaque opérateur ;
4. définir les délais de traitement, remboursement et contestation ;
5. effectuer une recette sur appareils physiques sans utiliser de vraie référence dans les environnements de test.
