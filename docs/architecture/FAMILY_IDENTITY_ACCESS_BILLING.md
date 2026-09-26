# Famille, identité, accès et facturation — architecture canonique

Statut : décision d'architecture, septembre 2026 (mission « Parent / enfant /
authentification », addenda « élèves avec téléphone », « payeur », « enfants dans
plusieurs établissements »).

## 1. L'échec qui a imposé cette refonte

Reproduction du propriétaire sur appareil :

1. un profil élève existe, authentifié par le **seul téléphone de la famille** ;
2. le code de liaison parent est copié depuis ce profil ;
3. déconnexion, choix « Parent », saisie du code ;
4. l'application demande un numéro : le numéro familial est saisi ;
5. Firebase Auth résout l'UID **élève** attaché à ce numéro ;
6. l'entrée parent refuse le compte élève (conflit de rôle) et propose
   « utilisez un autre numéro ».

L'espace parent était donc inatteignable pour toute famille qui ne possède qu'un
numéro. Ce n'est pas un défaut de route : le modèle confondait **possession d'un
téléphone**, **identité authentifiée** et **autorité familiale**. Une famille
camerounaise où l'élève n'a pas de téléphone ne pouvait pas exister proprement.

## 2. Vérité actuelle (audit avant modification)

### Identité et rôles

- `users/{uid}.role` est le seul rôle autoritaire (`student`, `parent`,
  `teacher`, `admin`, `superAdmin`). Il n'est jamais réécrit par le client.
- L'élève et le parent s'authentifient par téléphone (OTP Firebase). Un élève
  **devait** donc posséder un numéro ; un numéro ne peut appartenir qu'à un seul
  utilisateur Firebase Auth.
- L'administration générale peut créer un élève (`manageAccount/createStudent`),
  mais **avec un numéro obligatoire**.

### Relation parent ↔ élève

- `children_links/{parentId}_{studentId}`, statut `approved` écrit par le
  callable `linkChildByCode` (Admin SDK). Plusieurs parents par élève et
  plusieurs élèves par parent sont déjà possibles.
- Les règles `isLinkedParent(studentId)` autorisent un parent lié à lire
  `users/{studentId}`, `student_profiles/{studentId}` et sa progression.
- Codes de liaison : 8 caractères (≈ 39,6 bits), générés avec `Math.random`,
  stockés **en clair** (`student_profiles.linkCode` et
  `student_link_codes/{code}`), émis et régénérés **par l'élève seul**. Un
  enfant sans téléphone ne pouvait donc jamais produire son code.

### Facturation (réponse aux questions de l'addendum)

- Offre : `mobile_money_offers/{establishmentId}` — une offre par école,
  `offerId === establishmentId`. Prix, durée et opérateurs peuvent déjà différer
  d'une école à l'autre.
- Payeur : **uniquement un compte parent** (`submitMobileMoneyPayment`).
- Le numéro Mobile Money (`payerPhone`) est une donnée de preuve de virement,
  **indépendante** du numéro d'authentification.
- Portée du paiement : `resolveParentScope` **devine** l'école du parent
  (école vérifiée du parent, sinon l'école commune de ses enfants liés) et
  **refuse tout paiement** (`multiple_schools`) dès que les enfants sont dans
  deux écoles.
- Droit : à l'approbation, `entitlements/{parentId}_{establishmentId}`
  (`userId = parentId`, `startsAt`, `endsAt` prolongé au renouvellement). Il n'y
  a **aucun champ bénéficiaire**.
- Résolution (`FirestoreStudyReserveProvisioningStore.resolveEntitlement`) :
  élève → son école → tous ses parents approuvés → droit
  `{parentId}_{école}` actif → fenêtre qui court le plus loin.

**Sémantique V1 réelle : A.** Un paiement parent + école couvre **tous** les
enfants de ce parent liés dans cette école. La Réserve d'étude reste **par
élève** (un cycle et une allocation par enfant, jamais mutualisés). Entre
plusieurs parents payeurs, la résolution est déterministe (fin la plus
lointaine). L'auto-paiement élève et le financement par un établissement
n'existent pas.

Ce qui casserait si l'identifiant de droit changeait : la résolution de la
Réserve d'étude (qui recalcule `{parentId}_{establishmentId}`), la relecture
idempotente de `reviewMobileMoneyPayment`, et la règle de lecture
`entitlements` (`userId`). **Aucun identifiant n'est donc modifié.**

### Notifications

Le fan-out des annonces vise `users where establishmentId == école`. Un parent
sans école — ou dont les enfants sont dans d'autres écoles — ne recevait pas les
annonces des écoles de ses enfants. Le tableau de bord parent lisait lui aussi
une seule école : celle du parent.

### Routeur

Sans `optionURLReflectsImperativeAPIs`, go_router réévalue la redirection de
premier niveau contre la route **de base** d'une pile poussée, à chaque
rafraîchissement. Tout changement d'état d'authentification démontait l'écran
téléphone poussé au-dessus de `/auth` ou `/register`.

## 3. Modèle canonique

Cinq dimensions indépendantes, jamais déduites l'une de l'autre :

| Dimension | Question | Porteur |
| --- | --- | --- |
| Identité | Qui suis-je ? | UID Firebase Auth |
| Méthode d'accès | Comment je me connecte ? | téléphone OTP, code d'accès élève (jeton personnalisé), e-mail |
| Relation | Quels enfants puis-je suivre ? | `children_links` approuvés |
| Bénéficiaire | Qui reçoit le service ? | l'élève (scopé à son école) |
| Payeur | Qui finance ? | parent en V1 ; élève, établissement, sponsor à l'avenir |

Règles :

- **Le parent est global.** Son identité ne porte pas d'école autoritaire ;
  l'école appartient à chaque enfant.
- **L'élève est scopé à son école.** `users/{studentId}.establishmentId`.
- **Le paiement est contextualisé par bénéficiaire.** L'enfant choisi détermine
  l'école, donc l'offre.
- **La Réserve d'étude appartient à l'élève.**
- **L'autorisation vient de la relation** (parent), du périmètre de l'école de
  l'élève (direction) ou de la plateforme (super-administration).
- Un élève qui possède un téléphone ne change **que** sa méthode d'accès.

## 4. Code d'accès élève

Distinct du code de liaison :

| | Code de liaison parent | Code d'accès élève |
| --- | --- | --- |
| Rôle | établit la relation parent ↔ élève | connecte l'élève à SON espace |
| Format | 8 caractères | 12 caractères, `XXXX-XXXX-XXXX` |
| Qui l'émet | élève, parent lié, direction de l'école, super-admin | parent lié, direction de l'école, super-admin |
| Stockage | index serveur | **empreinte HMAC seulement** |

- Alphabet sans ambiguïté (31 symboles, sans O/0/I/1/L), tirage CSPRNG
  (`crypto.randomInt`) : 31¹² ≈ 2^59,5 combinaisons.
- Empreinte : HMAC-SHA-256 avec un poivre gardé dans Secret Manager
  (`STUDENT_ACCESS_CODE_PEPPER`). Une fuite de la base ne suffit pas à
  reconstituer ni à tester hors ligne un code.
- `student_access_credentials/{studentId}` : empreinte, version, dates, auteur
  et rôle de la dernière émission.
- `student_access_codes/{empreinte}` : index inverse `{ studentId, version }`.
- Émettre = **toujours un nouveau code** ; l'ancien est supprimé de l'index dans
  la même transaction. Le code en clair est renvoyé **une seule fois** ; il n'est
  jamais relisible (l'interface dit « générer un nouveau code », jamais
  « afficher le code »).
- Connexion : `signInWithStudentAccessCode` vérifie le format, l'empreinte, la
  version, le rôle et le statut du compte, puis renvoie un **jeton
  personnalisé** Firebase pour l'UID élève. Le client appelle
  `signInWithCustomToken`.
- Anti-bruteforce : échecs comptés par client (empreinte HMAC de l'adresse IP
  et de l'application App Check, jamais l'IP en clair) — 20 échecs par
  15 minutes, blocage 15 minutes (beaucoup de familles partagent une IP
  publique : NAT des opérateurs mobiles, Wi-Fi d'école ; 20 essais parmi 31¹²
  restent négligeables), message identique pour un code inconnu,
  remplacé ou mal formé, et pour un compte suspendu. L'adresse retenue est la
  **dernière** valeur de `X-Forwarded-For` (celle qu'ajoute l'infrastructure
  Google) : les valeurs précédentes viennent du client et changeraient à chaque
  essai. Les émissions et rotations sont journalisées dans
  `student_access_audit`.
- Jamais de code dans une URL, un journal, une analytique ou un rapport
  d'incident.

Téléphone et code d'accès mènent au **même UID élève** : aucun second profil.

## 5. Migration du numéro familial (élève → parent)

Situation : `Auth UID = élève`, `phoneNumber = numéro du parent`,
`users/{uid}.role = student`.

Déclenchement : entrée **Parent**, OTP réussi, le compte résolu est un élève.
L'écran n'effectue rien en silence ; il demande :

> Ce numéro est actuellement utilisé pour l'accès d'un élève. Souhaitez-vous
> l'utiliser comme numéro du parent ? L'élève conservera son profil et utilisera
> désormais son code d'accès INTELLIA.

Sur confirmation explicite (`{ requestId, confirmed: true }`),
`migrateStudentPhoneToParent` :

1. **Exige la preuve de possession** : session ouverte par SMS
   (`sign_in_provider = phone`) il y a **moins de 5 minutes**, numéro du jeton
   encore attaché à cet UID élève actif dans Firebase Auth. Un vieux jeton de
   l'appareil de l'enfant ne suffit pas.
2. **Prend le bail** du journal `auth_phone_migrations/{HMAC du numéro}` en
   transaction (60 s) : une double pression ne lance jamais deux migrations.
3. **Assure un accès élève** : émet un code d'accès **avant toute modification
   d'Auth**.
4. **Détache le numéro** de l'UID élève (`updateUser(phoneNumber: null)`) —
   état `phone_detached`.
5. **Crée l'identité parent** Firebase Auth portant ce numéro —
   état `parent_attached`.
6. **Relie et termine, en une transaction** :
   `children_links/{parentUid}_{studentId}` approuvé
   (`linkedVia: family_phone_migration`), numéro retiré des fiches élève
   (`users`, `student_profiles` : `phoneNumber` supprimé,
   `authPhoneMovedToParentId` ajouté), journal `completed`, audit
   `phone_moved_to_parent`.
7. **Répond** avec un jeton personnalisé parent et le code d'accès élève, montré
   une seule fois.

Pannes et reprise (testées sur les émulateurs Auth et Firestore) :

| Panne | Effet | Reprise |
| --- | --- | --- |
| retrait du numéro (4) | rien n'a changé | nouvel essai immédiat |
| création du parent (5) | numéro **réattaché** à l'élève, état `compensated` | nouvel essai : repart de zéro |
| création du parent **et** réattachement | état `needs_recovery` ; le code d'accès part dans le détail de l'erreur et ouvre l'élève | le numéro est libre : un nouveau SMS crée une identité vierge, **adoptée** comme parent |
| lien (6) après 3 essais | le parent existe et porte le numéro ; le code est dans le détail de l'erreur | le prochain SMS aboutit sur le parent, qui termine |

Côté application, une migration confirmée mais inachevée est mémorisée sur
l'appareil : l'écran montre d'abord le code d'accès de l'élève, puis propose de
vérifier à nouveau le numéro ; la nouvelle session parent appelle la reprise
avant l'inscription parent. Sans migration confirmée en attente, aucun appel
n'est fait : rien n'est jamais migré en silence.
| réponse perdue | journal `completed` | même résultat, nouveau jeton parent, **sans** second code (il n'est pas stocké) |

À chaque instant, la famille garde soit un accès parent, soit un accès élève.
Un compte sans lien avec le journal ne peut ni reprendre ni détourner une
migration inachevée.

Invariants : l'UID élève, sa classe, son école, sa progression, FLOW, sa
maîtrise, sa Réserve d'étude, ses notifications, son code de liaison et ses
liens existants sont conservés. Seuls la propriété du numéro et le champ
`phoneNumber` des fiches élève changent.

Le profil parent est ensuite créé par l'inscription parent existante (le compte
parent porte le numéro vérifié ; consentements donnés par le parent lui-même),
puis l'espace parent s'ouvre avec l'enfant déjà lié.

## 5 bis. Nouvelle famille : enfant sans téléphone ni compte

Le parent, déjà identifié par son propre numéro, choisit « Mon enfant n'a pas
encore de compte INTELLIA » et saisit le prénom. `createChildStudentAccess` :

- exige un compte parent actif, rejoue une même demande (`requestId`) sans
  créer un second enfant ni révéler un second code, et plafonne à 5 créations
  par parent sur 24 h ;
- crée une identité Firebase Auth **sans téléphone ni e-mail** ;
- écrit `children_links/{parentId}_{studentId}` approuvé
  (`linkedVia: parent_created_access`) et `pending_student_accounts/{studentId}`
  (prénom, auteur) ;
- émet le code d'accès, montré une seule fois au parent.

L'enfant entre avec ce code ; sans profil, il complète lui-même son inscription
scolaire (école, classe) — le parent ne choisit jamais l'école à sa place.
L'inscription élève accepte une session ouverte par jeton serveur (ni
téléphone ni e-mail) pour écrire le profil de **sa propre** identité. En
attendant, « Mes enfants » affiche l'enfant « en attente de sa première
connexion », avec l'action « Code d'accès élève ».

## 6. Vue parent d'un enfant

- Aucune usurpation : le parent reste connecté sous son UID.
- `listParentChildren` renvoie, pour chaque lien approuvé : identité scolaire
  (prénom, nom, classe, série, école et son nom), méthode d'accès (téléphone
  personnel présent ? code d'accès émis, et quand ? — jamais le numéro ni le
  code), abonnement résolu comme la Réserve d'étude (`active` / `inactive`,
  échéance, offre, `paidBy` : `you` ou `another_guardian`) et disponibilité
  d'une offre dans l'école de l'enfant. La super-administration peut
  prévisualiser un parent (`parentUid`) ; une direction d'école, jamais.
- Routes : `/parent/children/:studentId` (activité) et
  `/parent/children/:studentId/profile` (profil, bandeau « Mode parent »).
- Chaque lecture serveur vérifie `children_links/{parentUid}_{studentId}`
  approuvé ; chaque lecture Firestore passe par `isLinkedParent`.

## 7. Codes de liaison : chemins de confiance

`ensureStudentLinkCode` et `rotateStudentLinkCode` acceptent désormais un
`studentId` explicite pour : un parent déjà lié, la direction de l'école de
l'élève, la super-administration. L'élève garde son propre accès. Le tirage
passe à `crypto.randomInt`.

## 8. Facturation : évolution minimale et rétrocompatible

- **Paiement contextualisé** : `getMobileMoneyOverview` et
  `submitMobileMoneyPayment` acceptent `beneficiaryStudentId`. Le serveur vérifie
  le lien approuvé, résout l'école **depuis l'enfant**, charge l'offre de cette
  école, et n'essaie plus de deviner l'école du parent. Les anciennes versions
  sans bénéficiaire gardent l'ancien comportement.
- **Champs additifs**, sans changement d'identifiant : la demande enregistre
  `payerType`, `payerId`, `beneficiaryStudentId`, `establishmentId`, `offerId`
  et `coveredStudentIds` (enfants couverts au moment de la demande) ; le droit
  enregistre `payerType`, `payerId`, `beneficiaryScope` et le dernier
  bénéficiaire désigné.
- **Sémantique inchangée (A)** : un paiement parent + école couvre les enfants
  liés de ce parent dans cette école. L'interface le dit explicitement avant
  paiement (« Ce paiement couvre : … »). Passer à un abonnement par élève (B)
  est une décision commerciale, non prise ici.
- Auto-paiement élève et financement par un établissement : modélisés
  (`payerType`), **non exposés**.

## 9. Notifications multi-écoles

Une annonce d'école destinée aux parents (ou à tout l'établissement) atteint
aussi les parents **liés** aux élèves de cette école, quelle que soit l'école
de leur propre profil. Le tableau de bord parent lit les annonces des écoles de
**tous** ses enfants, chacune avec son école.

## 10. Routeur

Cause exacte : à chaque changement d'un état observé (session adoptée,
préférences, prévisualisation), go_router ré-analyse la configuration en place ;
l'adresse transmise à la redirection de premier niveau est celle de la route
**de base** d'une pile poussée (`/auth` sous `/auth/parent` sous `/auth/phone`).
Une décision prise pour cet écran caché remplaçait toute la pile.

Correction à la source (`AppRouterNotifier.activeLocation`) : lors de ce
rafraîchissement — reconnu parce que l'information de route n'est pas une
navigation `go`/`push` — la redirection décide pour le **sommet** de la pile.
Une navigation explicite garde sa propre cible. La redirection travaille ainsi
sur l'identité authentifiée, le rôle autoritaire du compte et l'expérience
demandée (intention d'entrée), sans écran caché qui décide.

Les tests d'intégration du routeur utilisent la **vraie table de routes**
(`appRouterProvider`) ; seuls les contenus d'écrans sont remplaçables
(`appRouteSlotsProvider`). Le harnais « appareil » des parcours famille et du
sceau 237 tourne désormais lui aussi sur cette table.

## 11. Règles Firestore

`student_access_credentials`, `student_access_codes`,
`student_access_attempts`, `pending_student_accounts`, `child_access_requests`
et `child_access_quotas` : aucun accès client, super-administration comprise.
`student_access_audit` et `auth_phone_migrations` (sans secret) : lecture par la
seule super-administration, aucune écriture client. Aucune règle existante n'est
affaiblie ; les tests de règles vérifient aussi qu'une direction A ne lit jamais
l'élève B, même quand un même parent est lié aux deux écoles.

## 12. Actions de production (aucune n'est exécutée ici)

1. Créer le secret `STUDENT_ACCESS_CODE_PEPPER` (au moins 32 caractères
   aléatoires) : `firebase functions:secrets:set STUDENT_ACCESS_CODE_PEPPER`.
   Sans lui, les trois callables d'accès refusent de fonctionner.
2. Donner au compte de service d'exécution des Functions le rôle
   `roles/iam.serviceAccountTokenCreator` sur lui-même (jetons personnalisés
   signés sans clé).
3. Déployer les Functions ajoutées (`issueStudentAccessCode`,
   `signInWithStudentAccessCode`, `migrateStudentPhoneToParent`,
   `createChildStudentAccess`, `listParentChildren`) et modifiées (`ensureStudentLinkCode`,
   `rotateStudentLinkCode`, `getMobileMoneyOverview`,
   `submitMobileMoneyPayment`, `reviewMobileMoneyPayment`,
   `fanoutAnnouncementNotifications`), puis les règles Firestore.
4. Aucune migration de données : les migrations de numéro sont déclenchées
   famille par famille, sur confirmation.
5. Tant que ces fonctions ne sont pas déployées, l'application dégrade
   proprement : les enfants restent listés depuis Firestore, sans école
   nommée, méthode d'accès ni abonnement résolus.
