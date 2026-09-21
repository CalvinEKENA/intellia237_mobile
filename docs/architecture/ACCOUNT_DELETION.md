# Suppression de compte — politique technique

Statut : implémentée sur `fix/release-hardening-sep2026`, **non déployée**.
Public : produit, support, super-administration, développement.

INTELLIA237 traite des données de mineurs. Une suppression mal contrôlée est
irréversible ; une suppression qui n'aboutit jamais est une promesse non tenue
(Google Play exige qu'une demande de suppression soit réellement traitée). Ce
document fixe ce qui se passe, dans quel ordre, et ce qui est conservé.

## 1. Parcours

| Étape | Qui | Effet |
| --- | --- | --- |
| Demande | Titulaire du compte (Paramètres › Supprimer mon compte) | `account_deletion_requests/{uid}` passe en `scheduled`, échéance **J+7**. Rien n'est effacé. |
| Délai de grâce | Titulaire | Le compte reste utilisable. L'écran affiche la date prévue et « Annuler la demande ». |
| Annulation | Titulaire, avant l'échéance | `cancelled`. Une nouvelle demande repart de J+7. |
| Traitement | Serveur (`processAccountDeletions`, toutes les heures) | Étapes ci-dessous, idempotentes et reprises en cas d'échec. |
| Fin | Serveur | `completed` ; le compte n'existe plus, la connexion échoue. |

Le délai de grâce protège d'un geste involontaire, d'un téléphone partagé ou
d'un enfant qui supprime le compte sans mesurer la conséquence ; il ne retarde
qu'une semaine un droit qui reste entier.

## 2. Invariants

1. **Rien n'est détruit à la demande.** Seul le traitement serveur efface.
2. **Ordre fixe** : (a) désactiver le compte Auth et révoquer ses sessions,
   (b) effacer ou anonymiser Firestore, (c) effacer Storage, (d) supprimer le
   compte Auth **en dernier**. Un échec au milieu laisse un compte désactivé,
   jamais des données orphelines rattachées à un identifiant réutilisable.
3. **Idempotence** : chaque étape peut être rejouée sans effet de bord ; une
   reprise après échec recommence au début sans risque.
4. **Bail de traitement** : une demande est réclamée par transaction
   (`processing`, bail de 15 min) ; deux exécutions ne la traitent jamais en même temps.
5. **Échec et reprise** : `failed`, compteur de tentatives, reprise à 1 h,
   6 h, 24 h puis 72 h ; après 5 échecs, `needs_attention`, visible dans Studio.
   Le message d'erreur stocké est un code, jamais une donnée personnelle.
6. **Trace minimale** : après traitement, la demande garde `uid`, rôle, dates,
   statut et nombres d'éléments traités par étape. Ni nom, ni e-mail, ni
   téléphone.
7. **Super-administration** : un compte super-administrateur ne peut pas se
   supprimer par ce chemin (risque de perte de contrôle de la plateforme) ; il
   est traité manuellement.
8. **Mineurs** : quand un élève demande la suppression, ses parents liés
   (liens approuvés) reçoivent une notification. Ils ne peuvent pas s'y
   opposer : la décision de veto parental est une question juridique à
   trancher par le propriétaire (voir §6).

## 3. Données par catégorie

### Effacées

| Données | Clé | Rôles |
| --- | --- | --- |
| `student_profiles/{uid}` et `lessonProgress/*` | document + sous-collection | élève |
| `parent_profiles/{uid}`, `teacher_profiles/{uid}`, `admin_profiles/{uid}` | document | selon rôle |
| `settings/{uid}`, `streaks/{uid}`, `study_reserve/{uid}` et `ledger/*` | document (+ sous-collection) | élève |
| `children_links` | `studentId == uid` ou `parentId == uid` | élève, parent |
| `notifications`, `notification_devices` | `userId == uid` | tous |
| `quiz_attempts`, `progress`, `recommendations` | `studentId == uid` | élève |
| `flow_completions`, `flow_events`, `flow_daily_points` | `studentId == uid` | élève |
| `ai_tutor_daily_usage`, `tutor_requests`, `ai_conversations` | `userId == uid` | élève |
| `student_link_codes` | `studentId == uid` | élève |
| `student_access_credentials/{uid}`, son index `student_access_codes/{lookupKey}`, `pending_student_accounts/{uid}` | documents | élève |
| `link_attempts/{uid}`, `child_access_quotas/{uid}`, `child_access_requests` (`parentId == uid`) | documents | parent |
| Storage `avatars/{uid}/**` | préfixe | tous |
| Compte Firebase Auth | uid | tous |

### Remplacées par une pierre tombale

| Données | Traitement |
| --- | --- |
| `users/{uid}` | Réécrit en `{ uid, role, accountStatus: "deleted", deletedAt }` : aucune donnée personnelle. Un jeton Firebase reste valide jusqu'à une heure après la désactivation ; tant que ce document existe avec `deleted`, les règles refusent toute lecture ou écriture à cet uid, et il ne peut pas recréer de profil. |

### Retirées d'un document partagé

| Données | Traitement |
| --- | --- |
| `classes.studentIds`, `classes.teacherIds` | l'uid est retiré ; la classe reste |

### Conservées (avec raison)

| Données | Raison |
| --- | --- |
| `mobile_money_payment_requests`, `mobile_money_reference_keys`, `entitlements` | Pièces comptables d'un paiement (payeur = parent) ; obligation de conservation. Accès limité à l'administration. |
| `account_management_audit`, `student_access_audit`, `establishment_changes`, `staff_account_reviews`, `auth_phone_migrations` | Traces de sécurité et d'administration, pseudonymes (uid), sans contenu pédagogique. |
| Contenus publiés par le personnel (leçons, quiz, cartes Parcours, annonces) | Contenus institutionnels de l'école ; l'uid d'auteur reste une référence pseudonyme. |
| `account_deletion_requests/{uid}` | Trace minimale de la suppression elle-même (§2.6). |

Durées de conservation exactes des pièces comptables et des journaux : à fixer
par le propriétaire avec son conseil (voir §6).

## 4. Conséquences visibles

- **Élève** : ses parents perdent l'accès à son suivi ; ses classes ne le
  listent plus ; son abonnement payé par un parent n'est pas remboursé
  automatiquement.
- **Parent** : ses enfants gardent leurs comptes ; les liens disparaissent,
  donc l'abonnement qu'il a payé ne couvre plus ses enfants tant qu'un autre
  parent ne se lie pas. Les pièces de paiement restent.
- **Enseignant / direction** : ses contenus restent ; il est retiré des classes.

## 5. Confirmation

- À la demande : l'application affiche la date prévue et la possibilité
  d'annuler.
- Après traitement : le compte n'existe plus. L'application n'a aucun canal
  e-mail ou SMS sortant pour confirmer après coup ; la preuve est l'état
  `completed` consultable par la super-administration dans Studio. Un canal de
  confirmation sortant est un chantier séparé.

## 6. Décisions laissées au propriétaire

- Veto ou accord parental pour la suppression du compte d'un mineur.
- Durées de conservation des pièces comptables et des journaux d'audit.
- Page web de demande de suppression (exigée par Google Play pour les
  personnes qui n'ont plus l'application).

## 7. Déploiement requis

- Callables `requestAccountDeletion` (modifiée), `cancelAccountDeletion`.
- Fonction planifiée `processAccountDeletions` (API Cloud Scheduler active).
- Règle Firestore : le titulaire lit sa demande ; la super-administration lit
  toutes les demandes.
- Index composite `account_deletion_requests (status, dueAt)`.
