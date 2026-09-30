# INTELLIA AWAKENS — provenance Higgsfield et leçons (29/09/2026)

Ce document garde ce que le dépôt ne dit pas : comment le clip du lancement a
été obtenu, ce qui a échoué, et ce qu'il faut refaire (ou ne pas refaire) pour
la transition Authentification → Home.

## Périmètre

Higgsfield produit une **matière** : verre, réfraction, lumière diffuse,
profondeur. Tout ce qui doit être exact reste du Flutter : le logo
(`assets/branding/logo.png`), le 2-3-7, les fragments, le LOCK, le sweep, la
vibration, le Pass, les noms, les classes, les menus, la Home. Aucune vidéo ne
contient de logo, de texte ou d'interface. L'application n'appelle jamais
Higgsfield : elle embarque un fichier (`assets/branding/cinematic/`).

## Génération V1

| | |
|---|---|
| Modèle | Wan 3.0 (Higgsfield), mode « réflexion » |
| Format | 9:16, 3 s, sortie 720×1280, H.264 30 fps, sans audio |
| Job | `7fea0137-ada8-4aa5-bba1-29865425c5cd` (29/09/2026) |
| Coût | 5,25 crédits (plan gratuit : 10 crédits d'inscription, 4,75 restants) |
| Poids brut | 3,4 Mo (≈ 9 Mb/s), une seule image clé : non embarquable tel quel |

Prompt (anglais, tel qu'envoyé) : environnement lumineux menthe → bleu glacier,
profondeur de verre, lumière volumétrique très douce, particules à peine
visibles, « fragments géométriques élégants » qui émergent de la profondeur et
« convergent vers le centre sans jamais former de lettres », dolly-in lent avec
un micro-arc, onde de lumière à mi-parcours, balayage de lumière de gauche à
droite, fin sur une surface calme avec un centre dégagé ; interdits : mots,
lettres, logos, interface, personnes, néon, cyberpunk.

## Verdict du V1 brut

Belle matière, mais inutilisable comme fond direct :

- teinte gris-teal (première image à ≈ 80 unités RVB de `#F2F9FC`) et clip qui
  s'assombrit jusqu'à la fin ;
- de grandes formes de verre **typographiques** occupent le centre : le modèle a
  traduit « fragments qui convergent » et « identité qui se verrouille » en
  lettres de verre, malgré « no letters » ;
- fin chargée, pas calme ; aucune boucle ; le « 7 » or du logo tombait à un
  contraste de 1,1 (1,97 sur le splash actuel).

## Le sauvetage (variante « E »)

Un voile clair par-dessus ne suffit pas : à 35 / 50 / 65 %, le fond reste gris
(écart moyen à `#F2F9FC` de 55 / 42 / 30 à 1300 ms). Ce qui marche : ne garder
que la **structure fine** (passe-haut) posée sur le dégradé de marque, puis
adoucir les arêtes. Résultat à 1300 ms : écart moyen ≈ 2, contraste du logo
≈ 99 % de celui du splash actuel, « 7 » or compris (1,95 contre 1,97).

Le passe-haut seul rend les pseudo-lettres *plus* lisibles ; il faut lui
ajouter le voile Flutter (45 %), le centre calme (50 %), un flou léger et
l'échelle 1,10. Le détail exact est dans `tool/branding/derive_awaken_clip.sh`
et `LaunchMatter`.

## Leçons pour la prochaine génération

1. **Ne jamais demander de fragments, d'identité ou de « lock »** : Flutter
   construit déjà les fragments du vrai logo. Demander un environnement de verre
   et de lumière *vide*, centre dégagé.
2. **Conditionner la première ET la dernière image** sur une surface unie (Wan 3.0
   accepte `start_image` / `end_image`). Le fichier se téléverse par le widget
   d'upload Higgsfield.
3. **Cuire le traitement à l'encodage** (ffmpeg), pas au runtime : le passe-haut
   et le flou coûteraient trop sur une texture vidéo. Au runtime, seulement des
   dégradés à transparence, une échelle et un voile de fondu.
4. **Vérifier la plage colorimétrique** : un fichier sans étiquette est lu en
   plage vidéo (tv) par Android et ffmpeg ; le décodeur Windows d'aperçu l'étend
   moins. Étiqueter la sortie (bt709, tv).
5. **Ne pas régénérer le splash.** Le V1 récupéré est la direction retenue.

## Prochaine étape : Authentification → Home

Les crédits restants (4,75) sont réservés à cette transition. Contrat :

- **Première image** : le fond de l'écran d'authentification, la crème
  `#FBF8F1` (pas le mint du splash), avec une impulsion lumineuse minuscule au
  point d'authentification.
- **Dernière image** : la même crème, très claire et calme, le haut de l'écran
  dégagé pour le vrai Pass ; aucune image finale n'est cuite dans la vidéo.
- **Contenu** : un court voyage abstrait (courbe, orbite, membrane cellulaire,
  géométrie, glyphes illisibles, points de données), 0,5 à 0,75 s, sans texte
  lisible, sans écran Home, sans Pass, sans logo.
- **Rendu réel** : Flutter fait apparaître le Pass réel (`LivingPass`, vol du
  Hero) et la Home réelle ; point d'insertion unique : `buildPassHomePage`
  (`lib/features/auth/presentation/widgets/pass_home_arrival.dart`), durée
  choisie dans `AppRouterNotifier.redirect`. Réduire les animations : pas de
  tunnel, transition courte.
- Même pipeline que le splash : génération, passe-haut, flou, fondus en Flutter,
  repli sur la transition actuelle si le clip manque.

Prompt de base (à adapter avec les leçons ci-dessus) : transition ultra-courte à
travers un monde abstrait de connaissance, depuis une petite impulsion lumineuse
sur une surface claire, la caméra accélère doucement dans un court tunnel où
passent, en profondeur, une courbe mathématique, un mouvement orbital, une
membrane cellulaire, des structures géométriques, des glyphes de langue
illisibles et des points de données ; rien de lisible, aucune page de manuel,
aucun néon ; après environ une demi-seconde l'espace s'ouvre sur une composition
claire et calme, zone centrale et haute libre pour l'identité de l'élève.
