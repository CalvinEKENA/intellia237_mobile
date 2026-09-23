# Refonte finale Auth V2 — rapport (23 septembre 2026)

| | |
| --- | --- |
| SHA source (revu) | `7ea5cf084f679b044debf30aa470843b37ea05e4` (`feat/auth-experience-v2-google`, non modifiée) |
| Branche | `fix/auth-v2-final-rework` (créée depuis exactement 7ea5cf0) |
| SHA final | tête de `fix/auth-v2-final-rework` : le commit de documentation qui contient ce rapport (un commit ne peut pas citer son propre SHA ; il est donné dans le message de livraison). Code testé : `d63eb1c`. |
| Version | `3.2.1+30`, inchangée |
| Déploiement | aucun ; aucune console Firebase ou Google Cloud modifiée ; aucun APK/AAB ; rien envoyé au Play Store ; branche non poussée |

## 1. Commits

| SHA | Objet |
| --- | --- |
| `548e8c0` | feat(functions): probe a Google identity without creating a user |
| `18fe579` | fix(functions,rules): honour additive roles everywhere, server-governed |
| `d7d8491` | feat(i18n): Auth V2 strings in the ARB files (FR + EN) |
| `31e2a8d` | feat(auth): official Google "G" asset for "Continuer avec Google" |
| `d5aa239` | fix(auth): one Cameroon phone normalizer; OTP field fits 200 % text |
| `a9c9ed5` | feat(auth): credential-first Google access, one session resolver, identity-first entry |
| `8307724` | feat(auth): reachable space switching, roles read like the server |
| `d63eb1c` | test(functions): inactive staff gains nothing from additive spaces |
| (tête) | docs(auth): owner Google checklist, P0 evidence, final rework report |

## 2. Les quatre P0

Reproduits sur 7ea5cf0 **avant** toute correction (test et sortie conservés :
`docs/release/evidence/auth_v2_p0_repro_7ea5cf0_*`) : `+2 -5`.

| P0 | Constat sur 7ea5cf0 | État | Preuve |
| --- | --- | --- | --- |
| P0-1 Un succès Google ne connecte personne | statut resté `unauthenticated` | **Corrigé** | `google_access_journey_test` « existing parent: straight to the parent space, same UID » ; garde : aucun écran n'appelle `completeBootstrap` |
| P0-2 Identité créée avant toute décision | `signInWithProvider` appelé d'emblée | **Corrigé** | ordre des appels `google.acquire → server.probe` seulement (coordinateur et parcours) ; `createdByGoogle` vide jusqu'à « Non, continuer » ; garde : ni `signInWithProvider` ni `signInWithPopup` dans `lib/` |
| P0-3 Liaison à l'envers, fausse preuve e-mail | `EmailAuthProvider.credential` + `linkWithCredential` sur la session Google | **Corrigé** | récupération réelle (SMS ou `signInWithEmailAndPassword`) puis Google rattaché au MÊME UID, égalité vérifiée ; gardes sur `lib/features/auth/presentation` |
| P0-4 Suite rouge (auth : 52 littéraux) | 2 échecs | **Corrigé** | cliquet i18n vert ; suite Flutter complète verte (§ 15) |

## 3. Premier lancement

Premier lancement comme retour : la même porte neutre (`/auth`) —
« Continuer avec mon numéro », « Continuer avec Google », « J'ai un code
élève », accès personnel discret. Aucun écran de rôles : `RegisterScreen`
(cartes de rôle) et `ParentEntryScreen` (code enfant avant l'identité) sont
supprimés ; `/register` et `/auth/parent` redirigent vers la porte. L'onboarding
et le lien « Créer un compte » de la connexion e-mail n'y mènent plus.

## 4. Architecture Google (preuve d'abord)

1. `GoogleCredentialSource` (`google_sign_in` 7.2, Credential Manager) :
   acquiert un jeton d'identité Google, sans session Firebase.
2. `GoogleIdentityProbe` → callable `probeGoogleIdentity` : vérifie signature
   RS256 (clés publiques Google), émetteur, audience (clients OAuth Web
   configurés), expiration ; cherche l'UID qui porte ce `sub` Google ; répond
   `existing` ou `unknown`, jamais d'UID, de rôle ni d'adresse. Aucune
   recherche par e-mail.
3. `GoogleAccessCoordinator` : connu → `signInWithCredential` puis adoption
   explicite ; inconnu → question « Vous utilisez déjà INTELLIA237 ? » ;
   « Oui » → récupération ; « Non » → nouvelle identité, Découverte.
4. `FirebaseIdentityPort` : seul point d'accès à Firebase Auth pour ce
   parcours ; erreurs normalisées en codes, jamais en messages.

**UID temporaire : aucun.** Le SDK client ne sait pas tester une preuve
fédérée sans connexion (`signInWithCredential` crée l'utilisateur ;
`fetchSignInMethodsForEmail` est vide sous la protection contre l'énumération
d'adresses et ne verrait pas un compte ouvert par téléphone) ; la sonde
serveur répond donc à la place. Deux identités neuves restent possibles et
sont supprimées aussitôt, de façon déterministe : un numéro inconnu saisi
pendant la récupération (identité vide créée par le SMS), et la course
« compte connu puis disparu » entre la sonde et la connexion. Si la
suppression échoue, l'écran le dit ; l'identité restante n'a aucun profil ni
lien Google.

## 5. Préservation de l'UID

Récupération par téléphone ou e-mail : connexion réelle au compte A, puis
`linkWithCredential` de la preuve Google en attente sur la session A ; le
coordinateur exige `currentUid == A` avant, et `linkedUid == A` après. Tests :
« existing phone account + Google: UID preserved » (`parent-uid`), « existing
e-mail account + Google » (`teacher-uid`), et `linkPendingTo` refusant toute
autre session.

## 6. Collisions

- Compte Google déjà porté par un autre UID : arrêt, « Ce compte Google est
  déjà associé à un autre compte INTELLIA237. », rien n'est fusionné, copié ni
  réattribué ; choix « Ouvrir mon espace sans Google » ou « Annuler » (la
  session du compte prouvé se referme).
- Compte existant déjà lié à un autre compte Google : message dédié, même
  arrêt.
- `account-exists-with-different-credential` : la preuve est conservée ; la
  récupération par e-mail s'ouvre, adresse préremplie ; aucun second compte.
- Preuve expirée : renouvelée une fois, pour le même `sub` uniquement.

## 7. Téléphone sans rôle présélectionné

Compte parent, enseignant ou direction : l'espace s'ouvre directement.
Nouvelle identité : écran de décision (`/auth/welcome`) — « Je suis parent »,
« Rejoindre mon école », « Découvrir INTELLIA237 » — jamais « profil
introuvable ». Numéro d'un compte **élève** : confirmation « Ce numéro ouvre
l'espace élève de Awa » → « Continuer comme Awa » ou « Je suis son parent ».
Choix délibéré : la décision propriétaire du round 2 (un parent qui saisit le
numéro familial ne doit jamais atterrir en silence dans l'espace de l'enfant)
reste tenue sans rôle demandé avant l'identité, au prix d'un toucher pour
l'élève ; « Je suis son parent » ouvre la migration du téléphone familial
existante. Une reprise de migration inachevée se termine aussi depuis l'accès
neutre.

## 8. Rattachement parent

Téléphone → « Je suis parent » → inscription parent (identité) → accueil
parent → « Rattacher mon enfant » → code → l'enfant apparaît. Le code enfant
n'est jamais demandé avant l'identité. `children_links` inchangé : liaison par
la callable `linkChildByCode`, qui exige désormais l'espace parent via
`hasUserRole` (un enseignant-parent peut rattacher, un enseignant seul non).
Parcours « A · new parent » sur les vrais écrans.

## 9. Code élève

Inchangé et toujours de premier niveau (porte, Découverte) : code →
vérification serveur → jeton personnalisé → UID élève → accueil. Parcours
famille D, E/I et « NEW FAMILY » verts.

## 10. Découverte

Identité Google sans profil (« Non, continuer ») → Découverte ; persistée par
UID et dérivée d'une identité Google seule, donc de retour après un
redémarrage (testé). Aucune route privée atteignable (routeur, testé sur
17 routes) ; l'écran n'importe ni Firestore, ni Functions, ni aucun module IA
(garde de source) ; aucune identité fictive (`discovery-visitor` supprimé).
L'exemple « Samuel (3ème), 4 h 15, 86 % » est remplacé par des exemples
génériques annoncés comme fictifs.

## 11. Multi-rôle côté serveur

`functions/src/auth/userRoles.ts` (`resolveUserRoles`, `hasUserRole`,
`isSuperAdminUser`, `planRoleChange`) lit `role` + `roles` comme les règles.
Contrôles convertis : paiements, liaison enfant, accès enfant, codes d'accès,
réserve d'étude, liste des enfants, périmètre tuteur, points Parcours, état
académique, audience et rédaction des contenus, import de pages, classes,
établissements, comptes, configuration IA, revue du personnel, changement
d'école, diffusion des annonces. Modèle : élève exclusif ; personne ne devient
élève par `roles` ; super-administration lue dans `role` seulement (règles
alignées). `role` reste le rôle principal : les anciennes versions
fonctionnent.

Écritures : callable `manageUserRoles` (super-administration seule) —
`role` et `roles` écrits ensemble, en transaction, avec journal
`account_role_changes`. Révocation : retrait secondaire → `roles` seul ;
retrait du principal → l'espace suivant (direction > enseignant > parent)
devient `role` ; dernier espace → refusé (suspendre le compte) ; `roles`
supprimé s'il ne reste qu'un espace. Les clients ne peuvent pas écrire
`roles` (règles, testé). Limite : aucune interface d'administration n'appelle
encore `manageUserRoles`, et accorder « enseignant » par `roles` ne crée pas
de `teacher_profiles` (les indicateurs enseignant restent vides).

## 12. Changement d'espace

Sélecteur localisé, uniquement les espaces accordés ; affiché une fois avant
tout accueil si aucun espace n'est retenu sur l'appareil ; choix mémorisé par
UID ; espace retiré par le serveur abandonné à la résolution suivante.
« Changer d'espace » : Paramètres (élève, parent, enseignant), onglet Profil
du parent, barre de l'administration ; sans déconnexion. Compte à un seul
espace : jamais de sélecteur.

## 13. i18n

115 clés ajoutées (FR + EN), 2 clés inutilisées réécrites. Littéraux français
en dur : auth 52 → 0, découverte 39 → 0 ; cliquet vert. Aucun message
technique affiché : `authErrorMessage` couvre réseau, code SMS, trop de
tentatives, compte existant avec une autre méthode, identifiant déjà utilisé,
mot de passe, compte suspendu, fournisseur déjà lié, configuration Google
absente, sélecteur indisponible, étape expirée, numéro invalide ; tout code
inconnu → message générique. Annulations silencieuses : `canceled` (plugin
7.2, vérifié dans `GoogleSignInExceptionCode`), `web-context-canceled`,
`popup-closed-by-user`, `cancelled-popup-request`. Un seul normaliseur
camerounais (`CameroonPhoneNumber`) partout, y compris profil, recherche
d'administration et contact parent du Pass.

## 14. Marque Google et checklist

Logo « G » officiel extrait du SDK Google Play services
(`play-services-base` 18.9.0, `googleg_standard_color_18.png`, 1× à 3×,
empreintes dans `docs/branding/GOOGLE_G_LOGO_SOURCE.md`), 18 dp, fond blanc,
contour #747775, libellé #1F1F1F Roboto Medium 14, 52 dp. Le peintre maison
est supprimé.

`docs/auth/OWNER_GOOGLE_SETUP_CHECKLIST.md` corrigée : production
`com.edunova.app` (`edunova-aabd1`), staging `com.intellia237.app.staging`
(`intellia237-staging`) ; flux natif Credential Manager ; SHA debug, clé de
téléversement et signature Play ; `google-services.json` avec
`oauth_client` 1 et 3 (aujourd'hui absents dans les deux fichiers) ou
`GOOGLE_SERVER_CLIENT_ID` ; `GOOGLE_OAUTH_CLIENT_IDS` pour la sonde.

## 15. Tests (sur le SHA final)

Portes exécutées sur `d63eb1c` (le commit suivant ne change que la
documentation) :

| Porte | Résultat |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 0 fichier à modifier |
| `dart run tool/check_brand_references.dart` | réussi |
| `flutter analyze` | aucun problème |
| `flutter test` | **1670 / 1670** (7ea5cf0 : 1568 réussis, 2 échecs) |
| Functions `npm test` | 48 fichiers, **423 / 423** |
| Functions `npm run build` | `tsc` sans erreur |
| Règles Firestore (dont 11 tests `roles[]`) | 78 / 78 |
| Règles Storage | 9 / 9 |
| Règles des ressources éducatives | 16 / 16 |
| Intégration accès famille + facturation | 17 / 17 |
| Intégration réserve d'étude | 8 / 8 |
| Intégration annonces | 4 / 4 |
| Intégration suppression de compte | 8 / 8 |
| Intégration Parcours | 6 / 6 |
| Intégration comptes admin | 4 / 4 |
| Intégration publication | 9 / 9 |
| Intégration tuteur | 13 / 13 |
| Studio `flutter analyze` / `flutter test` | aucun problème / 55 / 55 (Studio non modifié) |

Suites émulateur lancées une par une ; un émulateur d'une autre session
occupait les ports par défaut, d'où un fichier de ports temporaire
(`firebase.altports.local.json`), supprimé ensuite et jamais commité.

Nouveaux tests notables : `google_access_coordinator_test` (ordre des
appels), `google_access_journey_test` (15 parcours sur les vrais écrans :
P0-1 à P0-3, récupération téléphone et e-mail, collisions, numéro, code et
mot de passe faux, réseau, annulation, Découverte après redémarrage, perte de
session), `auth_v2_redirect_test`, `auth_v2_responsive_test` (320 × 568,
360, texte 130 % et 200 %, FR/EN : porte, bouton Google, téléphone et OTP,
question Google, récupération, décision, sélecteur d'espace, confirmation du
téléphone familial), `auth_v2_p0_regression_test` (gardes de source),
`parent_identity_first_journey_test`, `multi_role_auth_test` réécrit ;
côté serveur `googleIdentityProbe.test`, `userRoles.test`,
`userRolesManagementCallable.test`, `userRoles.rules.test`. Le harnais
« appareil » ne transforme plus les anciennes clés de la porte en
`router.push` : les 26 parcours du sceau et les 10 parcours famille
traversent la vraie porte neutre.

## 16. Incertitudes réservées à l'appareil (NON VÉRIFIÉES)

- Sélecteur de comptes Google (Credential Manager) : apparence, annulation,
  code renvoyé quand la configuration est incomplète.
- Connexion Google Firebase réelle ; acceptation par Firebase du même jeton
  après la sonde, et pour `linkWithCredential` après la récupération (chemin
  de renouvellement présent, non éprouvé).
- Liaison réelle d'un compte Google à un compte téléphone ou e-mail existant.
- Comportement « une identité par adresse » de Firebase face à un compte
  e-mail non vérifié.
- Envoi du SMS, lecture automatique du code (SMS Retriever / autofill).
- Suppression immédiate de l'identité créée par un numéro inconnu pendant la
  récupération.
- Émission de `authStateChanges` à la révocation d'un jeton sur Android.
- TalkBack sur la porte, la question Google, la récupération, la décision et
  le sélecteur (seules les sémantiques de test sont vérifiées).
- Rendu du logo sur écrans xxxhdpi (variante 3× agrandie).

## 17. Préalables du propriétaire avant la QA appareil

Google ne peut pas fonctionner sur téléphone avant : checklist Google (étapes
1 à 4) et `GOOGLE_OAUTH_CLIENT_IDS`, puis déploiement des Functions
(`probeGoogleIdentity`, `manageUserRoles`, contrôles de rôles) et des règles
Firestore — en plus des déploiements déjà en attente (secret
`STUDENT_ACCESS_CODE_PEPPER`, IAM). Les parcours téléphone, code élève,
parent et Découverte ne dépendent pas de Google.

READY FOR PHYSICAL DEVICE QA
