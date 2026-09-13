# Connexion téléphone et administration — 12 septembre 2026

## État constaté

La connexion téléphone fonctionne à nouveau : confirmation explicite de
l’utilisateur pendant l’intervention. Firebase Auth enregistre une connexion
avec le numéro concerné le 12 septembre à 15:31:20 UTC (16:31 au Cameroun).
Le profil correspondant est un profil élève terminé.

L’origine précise du blocage initial n’a pas pu être établie. Ne pas présenter
le retour du SMS comme la preuve que le code du nouveau bundle l’a débloqué :
ce bundle n’était pas encore installé lors de la confirmation.

Contrôles de production effectués sur `edunova-aabd1` :

- Authentification téléphone activée ; Cameroun autorisé ; facturation active.
- Le numéro concerné n’est pas un numéro de test Firebase.
- Six SMS envoyés dans la fenêtre de 48 heures examinée initialement. Rien
  n’indiquait un épuisement du plafond quotidien général.
- Identité Android cohérente : `com.edunova.app`, application Firebase
  `1:199517096075:android:bcc88158174b9458d8ac8e` dans les configurations natives
  et Dart. Les empreintes du certificat local de signature release sont
  enregistrées dans Firebase. Le certificat distribué par Play n’a pas pu être
  comparé directement, faute d’accès au téléphone/à une session Play Console.
- L’API Authentication est autorisée dans les restrictions de la clé Android.
- API Keys API activée pour lire ces restrictions ; aucune clé ni restriction
  de sécurité n’a été changée.
- Les journaux d’activité Authentication étaient désactivés. Leur activation
  a été refusée car le projet n’utilise pas Identity Platform. Aucun changement
  d’offre ou de facturation n’a été effectué.
- Trois profils élèves Firestore portent le même numéro. Le compte Auth actif
  correspond à l’un d’eux. Aucun ancien profil n’a été fusionné ou supprimé.

## Corrections dans l’application

- Espacement des demandes de SMS partagé entre les écrans téléphone, y compris
  après fermeture/réouverture. Ce délai local de 60 secondes n’est pas une
  promesse de déblocage du serveur Firebase.
- Le jeton de renvoi forcé n’est utilisé que pour un renvoi explicite.
- Rejet des callbacks tardifs d’une demande précédente ; une réponse tardive
  ne ramène plus une vérification réussie vers un écran d’erreur.
- Annulation de la prise en compte d’une vérification automatique abandonnée.
- Messages français/anglais corrigés : aucune promesse de déblocage en
  quelques minutes, distinction entre blocage, quota et vérification Android.
- Référence de diagnostic affichée. Crashlytics reçoit uniquement une catégorie
  non sensible en release, conformément au consentement existant. Aucun OTP,
  numéro, jeton ou message technique brut n’est envoyé par ce diagnostic.
- Rôle `superAdmin` canonique reconnu et conservation de la portée générale
  lors d’une restauration de session, y compris avec le cache du même UID.
- Conservation du rattachement scolaire dans le cache des autres comptes.
- Les comptes suspendus/supprimés sont déconnectés lorsque leur statut est lu.
- Actions d’administration disposées pour laisser le nom et les commandes
  lisibles sur écran étroit ; vérification des contrôles à 320 px et texte 1,6×.

## Droits et changements de production

Le compte `calvinekena1@gmail.com`, UID
`H2RFVv2GUFQUIcMDUnQz3Y49J5t2`, a été vérifié dans Firebase Auth et Firestore.
Son ancien rôle `super_admin`, sans indicateur de profil terminé, a été
normalisé en `superAdmin`, `accountStatus: active`, `profileCompleted: true`.
Les autres champs du document et les identifiants de connexion sont préservés.
L’écriture ciblée a utilisé une précondition sur la version du document.

L’administration générale garde la portée de toutes les écoles et du contenu
national. Les contrôles ne reposent pas sur une adresse e-mail envoyée par le
client : le serveur vérifie le rôle du compte authentifié.

Ajouts accessibles exclusivement à l’administration générale :

- Provisionner un élève par téléphone dans une école existante. Son profil
  scolaire sera complété par l’élève après connexion. Les répétitions de la
  même requête ne créent pas de deuxième identité.
- Suspendre/réactiver un élève, parent, enseignant ou chef d’établissement.
- Supprimer un profil des annuaires et bloquer son accès, avec restauration
  possible. Il s’agit d’une suppression réversible, explicitée dans l’écran,
  et non d’un effacement définitif des données.
- Préserver le statut antérieur lors d’une restauration : restaurer une
  demande en attente ne l’approuve pas implicitement.

Les approbations et changements d’établissement restent disponibles dans
leurs parcours existants. Les chefs d’établissement ne reçoivent pas les
commandes d’ajout/suppression d’élèves.

La fonction `manageAccount`, les contrôles d’accès des callables actuelles,
les règles Firestore et Storage sont déployés. Un compte suspendu/supprimé
est refusé par ces règles et ces callables même avec un jeton encore valide.
Le statut personnel reste lisible pour que l’application sorte proprement de
la session. Les décisions d’administration sont consignées côté serveur.

Trois anciennes fonctions hors de ce dépôt (`chatWithDavid`,
`generateExercises`, `gradeAnswer`, région `us-central1`) ont été laissées en
place. Elles ne sont pas couvertes par le nouveau garde des callables.

## Validation

- 270 tests Flutter distincts sur l’authentification, l’administration et le
  routage ; contrôles responsifs et visibilité selon le rôle inclus.
- 128 tests serveur.
- 66 tests de règles Firestore/Storage et 3 tests d’intégration transactionnelle
  de création, suspension, suppression et restauration sur émulateur.
- Analyse statique des zones modifiées sans problème après correction des
  avertissements de style.
- `manageAccount` en état `ACTIVE` en production ; un appel sans authentification
  retourne HTTP 401 `UNAUTHENTICATED`.
- Le compte de service de la fonction possède déjà les permissions du projet
  nécessaires ; aucune permission IAM n’a été ajoutée.

Bundle généré et signature JAR vérifiée : **3.3.1, code 26**, flavor
`production`, point d’entrée `lib/main_production.dart`. Le manifeste fusionné
confirme `com.edunova.app`, `versionCode=26`, `versionName=3.3.1`.

- Fichier : `build/app/outputs/bundle/productionRelease/app-production-release.aab`
- Taille : 77 595 234 octets.
- SHA-256 : `B51D7BBFBE01E57883857E10831AFC4E2389873C644D2E3DAB7A1C74E58C8DC0`

Publication Play Store non effectuée. La compilation émet encore des
avertissements sur les versions Gradle/AGP/Kotlin et la police Cupertino
optionnelle ; aucune erreur de compilation. Ces avertissements ne constituent
pas une explication démontrée du blocage OTP.

## Références officielles

- https://firebase.google.com/docs/auth/limits
- https://firebase.google.com/docs/auth/android/phone-auth
- https://docs.cloud.google.com/identity-platform/docs/activity-logging
