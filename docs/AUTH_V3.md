# Auth V3 — identité d'abord, espace ensuite

Branche `feat/content-engine`, à partir de `8cc0f941044fb2b9218efe8748fe5e8c7553fe04`.
Cette mission est séparée des packs pédagogiques et des cartes de l'application.

## Porte publique

Téléphone et Google restent les actions principales. L'e-mail public et le code
élève sont les autres méthodes. Le lien public « Personnel scolaire » disparaît.
Aucun rôle n'est demandé avant l'identité. Les liens directs vers une inscription
élève ou parent reviennent à la porte publique en l'absence de session.

Une nouvelle identité téléphone, Google ou e-mail arrive au choix d'objectif :
« Créer mon espace élève » en premier, « Suivre mon enfant », puis « Découvrir
INTELLIA237 ». La découverte n'est plus imposée à une nouvelle identité Google.
L'inscription réutilise l'identité prouvée, y compris pour l'e-mail ; elle ne crée
pas un deuxième utilisateur Firebase et ne redemande pas son mot de passe.

Un élève existant ouvre son espace directement. Yahoo, Gmail et Outlook suivent
exactement le même résolveur de profil serveur. Un compte exclusivement
professionnel entré par la porte publique est déconnecté et orienté vers le
bouclier. Un compte parent + personnel utilise son espace parent par l'entrée
publique, sans catalogue de rôles professionnels.

## Personnel

Le bouclier « Accès établissement » ouvre :

- Enseignant : intention `teacher`, connexion ou demande d'inscription existante.
- Direction / Proviseur : intention `admin`, accréditation existante conservée.
- Administration INTELLIA : intention `admin`, avec vérification supplémentaire
  du statut `isSuperAdmin` issu du profil serveur.

Les paramètres d'URL ne donnent aucun droit. Les rôles principaux et additifs
autorisés par le serveur restent compatibles. `RoleSelectorScreen` est réservé
aux espaces déjà accordés ; ce n'est pas une étape de l'onboarding public.
Aucune adresse e-mail n'accorde un rôle ou un niveau scolaire dans Flutter.

Vérification de production en lecture seule : le compte propriétaire
possède actuellement `users.role: student`, sans rôle
global dans ce profil. Le contrôle d'administration globale le refuse donc
avec ces données. Aucun droit n'a été ajouté ou modifié. Ce constat de données
doit être résolu séparément ; aucun privilège ne peut venir de l'adresse.


## Numéro familial et protection de l'espace parent

Un numéro reste associé à une seule identité Firebase Auth. Après une connexion
téléphone publique reconnue comme parent, le routeur bloque les pages privées
derrière le choix des enfants. Ce choix survit à un redémarrage interrompu.

`listParentChildren` réutilise les liens approuvés et `ParentChildSummary`.
Un enfant unique est ouvert automatiquement. Plusieurs enfants sont affichés
par leur nom, leur classe et, lorsqu'il est connu, leur établissement.

La nouvelle callable `openLinkedChildSession` exige une preuve récente
(cinq minutes), un parent actif et un lien approuvé, relu à chaque appel.
Elle retourne un custom token portant uniquement l'UID élève existant, sans
claims parent. Le client remplace effectivement sa session par celle de l'enfant
et ne conserve aucun jeton permettant de revenir au parent. Les données, la
progression et les profils ne sont pas dupliqués. Les codes élève et la migration
explicite d'un ancien téléphone élève vers le parent restent disponibles.

L'entrée « Espace parent » des réglages élève présente une explication puis
ferme la session enfant avant une nouvelle connexion téléphone ou e-mail sous
l'intention parent. Il n'existe aucune bascule locale vers le rôle parent,
aucun PIN en clair, aucun accès parental par le seul bouton. Les règles existantes
refusent à l'UID élève les profils parentaux, les abonnements et les autres enfants.
L'espace parent existant conserve sa liste et ses vues des enfants liés.

## Provisionnement et conversion explicite du compte de test

`functions/scripts/provisionStudent.ts` utilise Firebase Admin avec un projet
explicite. Le mode normal est idempotent et refuse tout profil adulte existant.
Il fonctionne à blanc par défaut ; `--apply` est nécessaire pour écrire.

La conversion limitée d'un ancien compte enseignant de test exige **à la fois**
`--convert-role teacher:student`, `--confirm` et, pour écrire, `--apply`.
Elle ne crée pas d'identité, ne modifie pas le mot de passe et n'envoie aucun
message. Les adresses sont des paramètres administratifs, jamais des règles
client ni des fixtures identifiant une personne réelle.

Depuis `functions`, précontrôle sans écriture :

```powershell
npx tsx scripts/provisionStudent.ts --project <projet> --email <adresse> --role student --class terminale --series D --convert-role teacher:student --confirm
```

Ajouter `--apply` après examen du précontrôle pour exécuter la conversion.
Le script refuse les rôles additionnels autres qu'enseignant, claims inconnus,
comptes désactivés/suspendus, profils parent/admin/élève préexistants,
rattachements d'établissement, affectations, contenus enseignants, liens
familiaux, documents administratifs et données financières associés.

Avant toute écriture, une sauvegarde logique est enregistrée **hors du dépôt**,
dans `~/.intellia237-private/role-migrations/`, avec création exclusive du fichier.
Elle contient les documents initiaux, leurs révisions, l'UID et les claims
contrôlés, sans export des mots de passe, empreintes ou jetons Firebase Auth.
Les timestamps conservent secondes et nanosecondes. Les champs susceptibles de
contenir des identifiants secrets et les types non gérés font refuser la sauvegarde.

Une transaction Firestore relit les documents et relations puis effectue les
changements ensemble : rôle élève, retrait des rôles additionnels, compte actif,
profil académique officiel, archivage non destructif du profil enseignant et
journal serveur. Le profil terminé et les noms existants sont conservés lorsqu'ils
sont complets ; seuls les consentements déjà enregistrés sont repris. Aucun
consentement ni choix personnel nouveau n'est inventé.

Les champs scolaires sont `classLevel: "Terminale"`, `series: "D"`,
`educationalSubsystem: "francophone"`, `educationType: "general"`,
`academicLevelId: "fr_general_terminale"`, `streamOrSpeciality: "D"` et
`accountLinkage: "individual"`. Le `ClassKey` correspondant est `terminale-d` :
mathématiques D, anglais commun et physique C-D sont admissibles ; les packs
réservés à d'autres séries ne le sont pas.

Les éventuels claims enseignant sont retirés avant la transaction. Si elle échoue
sans commit et si la révision reste identique, ces claims sont restaurés. Si sa
réponse est incertaine, le journal est relu avant toute compensation : aucun droit
enseignant n'est réaccordé après un commit. Un échec de lecture laisse l'opération
à vérifier puis à reprendre, sans restauration aveugle. Auth et Firestore ne
partagent pas de transaction ; les anciennes sessions sont révoquées après le
commit, avec reprise idempotente si cette dernière étape échoue. Une exécution
terminée est ensuite sans écriture. Le mot de passe reste inchangé.

En cas de restauration manuelle nécessaire, comparer les révisions et le journal
avant de restaurer les documents typés de la sauvegarde avec Firebase Admin.
Ne jamais écraser une activité postérieure à la migration. L'outil exporte
`decodeMigrationSnapshot` pour reconstruire les timestamps ; il n'expose pas
une commande de restauration automatique non contrôlée.

La vérification réelle et son résultat sont conservés localement hors des fichiers
versionnés. Aucun snapshot, UID ni adresse personnelle n'est inclus dans ce guide.

## Code et déploiement

Le client et la callable sont préparés dans le dépôt. **La callable n'est pas
déployée par cette mission.** Le parcours familial nécessite son déploiement
séparément autorisé ; si le service est absent ou refuse l'accès, l'application
n'ouvre pas silencieusement l'espace parent. Aucune règle n'est élargie.

Les vérifications couvrent les parcours Auth, les règles Firestore, l'échange
de session sur émulateurs et les largeurs 320/360/412 dp à texte 1,0/1,3.
Le bilan chiffré final figure dans la PR #11. Les tests de widgets ne remplacent
pas une validation sur appareil Android réel.

La version locale `3.2.1+34`, `pubspec.lock`, les fichiers utilisateur et les packs
pédagogiques sont conservés. Aucun déploiement, aucune fusion, aucun envoi Play.
