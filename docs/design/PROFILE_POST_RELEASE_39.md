# Profil INTELLIA — post-release +39

## Audit et architecture

La vraie surface élève est `StudentProfileTab` dans `student_home_screen.dart`.
Les écrans Settings, EditProfile et AvatarPicker sont les surfaces associées.
L'ancien profil juxtaposait des cartes et lignes Material, avec une identité
peu structurée et des réglages visuellement hétérogènes. Il disposait déjà de
services et d'indicateurs utiles : ces contrats sont réutilisés.

La nouvelle composition suit : identité INTELLIA PASS → progression et objectif
hebdomadaire → Compagnon → Réserve d'étude → accès parent → réglages → sortie.
L'identité reprend le prénom authentifié, la classe/série et l'établissement
déclaré. Une indisponibilité scolaire reste explicite. Le PASS est un élément
d'identité, sans badge d'abonnement ni certification d'établissement.

Papier clair, indigo, typographies INTELLIA, halo d'avatar et séparateurs fins
constituent le langage visuel. Les regroupements et contrôles Cupertino gardent
le comportement tactile attendu sur Android. Pas de blur animé permanent.

## Choix Cupertino

| Widget étudié | Décision et raison |
|---|---|
| CupertinoListSection.insetGrouped | utilisé pour structurer les sections |
| CupertinoListTile | remplacé par une ligne maison à hauteur naturelle ; les textes et contrôles se réorganisent sur 320 px/grand texte |
| CupertinoButton | utilisé pour les lignes, l'édition, l'avatar et la sauvegarde |
| CupertinoSwitch / CupertinoSlider | utilisés pour les préférences réelles |
| CupertinoFormSection / CupertinoTextFormFieldRow | utilisés dans l'éditeur ; labels au-dessus des champs |
| CupertinoActionSheet | galerie, caméra, suppression et annulation ; route adaptée à Reduce Motion |
| CupertinoAlertDialog / CupertinoDialogAction | confirmations de sortie et suppression du compte |
| CupertinoSlidingSegmentedControl | non retenu pour les vibrations : trois lignes intégrales sont plus lisibles en grand texte |
| CupertinoSliverNavigationBar | non retenu : le profil vit dans le shell élève avec son en-tête existant ; aucun second système de navigation |

## Fonctionnalités conservées

Édition du prénom/nom/téléphone avec validation existante ; email de connexion
immuable ; vérification email et liaison téléphone ; avatar galerie/caméra/
suppression ; choix du Compagnon ; objectif hebdomadaire et rappels ; taille du
texte, vibrations, Reduce Motion, économie de données et consentement aux
diagnostics ; rôle courant et changement d'espace quand disponible ; accès
parent ; confidentialité, liens légaux et suppression du compte ; déconnexion.
Les indicateurs de progression et de Réserve gardent leurs sources existantes.
Les services Firebase, règles de sécurité et chemins Auth ne sont pas refaits.

L'avatar initialise son service uniquement après une action explicite. Une
annulation ne lance pas d'upload. Une écriture réseau échouée rétablit l'avatar
antérieur et indique l'erreur ; la prévisualisation n'est pas présentée comme
une sauvegarde réussie. Une image absente ou illisible revient à l'initiale.
Les champs restent saisis après un échec d'édition.

## Validation

23 tests dédiés : profil réel et Settings en FR/EN sur 320/360/412/480 px avec
texte ×2, préférences effectivement persistées, sauvegarde/échec de l'éditeur,
email immuable, erreurs caméra/galerie et annulation, capture optionnelle.
Contrôle des exceptions de layout et des paragraphes tronqués. Les suites
préexistantes couvrent notamment la suppression du compte, le rôle et les
indicateurs serveur. Les totaux finaux figurent dans le rapport global.

Capture locale vérifiée : `build/post_release_39/profile_412.png`, polices
réelles, données de test Amina. Elle est un rendu de widget, pas une capture
d'un compte de production ni une mesure de performance d'un appareil Android.
Les transitions sont finies ; Reduce Motion supprime les transitions de popup
et de confirmation. Le champ téléphone évite un placeholder tronqué et
l'éditeur adapte la hauteur de son titre au grand texte.
