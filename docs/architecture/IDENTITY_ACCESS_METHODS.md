# Identité, méthodes d’accès et rôles — architecture cible

Document d’architecture du 22 septembre 2026. **Rien n’est implémenté dans
ce cycle** : ni Google Sign-In, ni multi-rôle, ni refonte de l’entrée. La
refonte de l’authentification reste au backlog immédiat.

## Principes du propriétaire

1. **Google est une méthode d’accès**, pas un rôle et pas une autorisation.
2. Une **identité** (UID Firebase) est indépendante du fournisseur utilisé
   pour la prouver.
3. Un **rôle** est indépendant du fournisseur : il ne vient jamais du fait
   de s’être connecté par téléphone, par Google ou par code.
4. Google pourra authentifier à terme un **parent**, un **élève**, un
   **enseignant** ou un **dirigeant d’établissement**.
5. Google n’**attribue jamais** : rôle enseignant, rôle administration,
   établissement, classe, permission. Ces droits viennent toujours d’un
   workflow serveur ou administratif (invitation, validation par l’école,
   super-administration).

## Modèle

| Notion | Définition | Aujourd’hui |
| --- | --- | --- |
| Identity | un UID Firebase | un UID par personne ; exceptions à éviter : doublons par fournisseur (voir liaison) |
| AccessMethod | `PHONE`, `GOOGLE`, `STUDENT_ACCESS_CODE` (et `EMAIL`, existant pour le personnel) | PHONE, STUDENT_ACCESS_CODE, EMAIL ; GOOGLE absent |
| Role | ce que l’identité est autorisée à faire | un seul `users/{uid}.role` |
| Relationship | lien parent-enfant approuvé, appartenance d’école accordée par le serveur | `children_links` canoniques ; `establishmentId` écrit par le serveur |
| Beneficiary / Payer | facturation par enfant | inchangé |

Une même identité peut posséder plusieurs méthodes d’accès (téléphone +
Google), liées par les mécanismes Firebase (`linkWithCredential`, ou lien
de fournisseur côté serveur avec preuve des deux moyens), jamais par une
fusion artisanale de données.

## Ce que les règles garantissent déjà

La création d’un profil par le client lui-même (`isPublicUserCreate`)
n’accepte que les rôles `student` et `parent`, sans établissement. C’est une
règle d’**auto-inscription**, pas une limite de fournisseur : un enseignant
ou un dirigeant connecté par Google devra recevoir son rôle d’un workflow
serveur (invitation acceptée, validation d’école), exactement comme
aujourd’hui avec le téléphone ou l’e-mail. Un compte Google ne peut donc pas
s’attribuer lui-même un rôle de personnel, tant que cette règle est gardée.

## Personnel : invitation plutôt que saisie

Collection `staff_invitations` (à créer) : émise par une administration
autorisée, avec téléphone ou e-mail, usage unique, expiration. Après
authentification (téléphone vérifié ou e-mail Google **vérifié**), le serveur
rapproche l’invitation : « Vous avez été invité par École X » [Accepter].
L’adresse Gmail seule n’est jamais une preuve : elle ne sert qu’à retrouver
une invitation émise par une personne habilitée.

## Élèves et Google

À décider par le propriétaire (non tranché) : proposer Google aux comptes
élèves, et à partir de quel âge. Les comptes Google de mineurs obéissent à
des règles propres à Google (âge minimum selon le pays, comptes supervisés).
Le code élève reste, dans tous les cas, l’accès des élèves sans téléphone :
aucun élève n’est obligé de créer un compte Google.

## Multi-rôle — décision à préparer (prochain cycle)

Besoin : une identité peut être **parent + enseignant** sans deux comptes.

Aujourd’hui : `users/{uid}.role` unique, lu par les règles (`getUserRole()`)
et par le routeur (`auth.role`). Un enseignant qui est aussi parent a besoin
de deux comptes.

Options (aucune n’est choisie) :

| Option | Principe | Coût de migration |
| --- | --- | --- |
| A. `roles: string[]` sur `users` | tableau écrit par le serveur | toutes les règles `isRole()` à réécrire ; tous les lecteurs de `role` (app, Studio, Functions) ; période de double écriture `role` + `roles` |
| B. collection `role_grants/{uid}_{role}` | une autorisation par document, avec origine (invitation, validation) et date | règles par `exists()` ; `role` conservé comme rôle principal ; migration additive |
| C. `role` inchangé + espace parent dérivé des liens | le rôle parent se déduit de `children_links` approuvés | ne couvre que parent + autre rôle ; règles parent inchangées |

Audit de migration requis avant de choisir : inventaire de chaque lecture de
`role` (règles, Functions, app, Studio), stratégie de double écriture, tests
de règles pour chaque combinaison, compatibilité des versions installées
(qui lisent `role`). **Ne pas introduire `roles: string[]` sans cet audit.**

## Entrée cible (backlog immédiat)

> [ Continuer avec mon numéro ]
> [ G  Continuer avec Google ]
> [ J’ai un code élève ]

Puis résolution automatique du rôle après l’identité : un seul espace ⇒
ouverture directe ; plusieurs ⇒ « Comment voulez-vous utiliser INTELLIA237
aujourd’hui ? » ; aucun ⇒ « Que souhaitez-vous faire ? ». Le rôle n’est pas
demandé avant l’identité, sauf nécessité démontrée. Le parcours se juge du
**premier écran jusqu’à l’espace final**, pas seulement sur « numéro →
code SMS ». Détail de l’audit : `docs/release/OWNER_QA_GATE_2026-09-21.md`,
section 11.
