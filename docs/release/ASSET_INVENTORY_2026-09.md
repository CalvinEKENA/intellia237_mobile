# Inventaire des ressources — septembre 2026

Relevé du 21 septembre 2026 sur `fix/release-hardening-sep2026`. Chaque fichier
de `assets/` a été recherché par nom dans `lib/`, `apps/intellia_studio/lib`,
`test/`, `web/`, `android/app/src/main`, `ios/Runner` et `pubspec.yaml`.
**Rien n’a été supprimé** : ce document donne les preuves et la liste à
valider par le propriétaire.

`pubspec.yaml` n’embarque que trois dossiers : `assets/fonts/`,
`assets/branding/`, `assets/companions/`. Les autres dossiers ne sont **pas**
dans l’APK : ils ne pèsent que sur le dépôt (≈ 13 Mo sur 17 Mo).

## Embarqué et utilisé

| Fichier | Usage |
| --- | --- |
| `branding/icone.png` | `IntelliaAssets.appIcon`, icône de lancement |
| `branding/icone_adaptive_foreground.png` | icône adaptative Android |
| `branding/identity_master.png`, `branding/affiche.jpg` | identité, affiche de l’accueil |
| `companions/kira.png`, `companions/leo.png` | portraits de Kira et Léo |
| `companions/*_onboarding_full_body.png` | accueil |
| `fonts/*.ttf` (13) | Barlow Condensed et Manrope déclarées, Montserrat et Playfair Display chargées hors ligne par `google_fonts` |
| `fonts/OFL-*.txt` (4) | licences ; Barlow Condensed ajoutée à la page des licences dans `b31e919` |

## Embarqué mais inutilisé par le produit (≈ 41 Ko dans l’APK)

| Fichier | Taille | Preuve |
| --- | ---: | --- |
| `branding/apple-touch-icon.png` | 4 Ko | aucune référence |
| `branding/favicon.svg` | 1 Ko | aucune référence (le web a ses propres fichiers) |
| `branding/icon-192.png` | 4 Ko | cité uniquement par des tests qui **interdisent** son usage |
| `branding/icon-512.png` | 12 Ko | aucune référence |
| `branding/intellia237_app_icon.png` | 12 Ko | aucune référence |
| `companions/kira.svg`, `companions/leo.svg` | 8 Ko | aucune référence (les PNG sont utilisés) |

Proposition : lister les fichiers un par un dans `pubspec.yaml` plutôt que le
dossier `branding/`, ou déplacer ces fichiers hors de `assets/`. Gain
négligeable en taille ; intérêt surtout de clarté.

## Non embarqué, sans référence (dépôt uniquement)

| Dossier / fichier | Taille | Remarque |
| --- | ---: | --- |
| logo de l’ancienne marque (dossier `icons/`) | 2,0 Mo | antérieur au changement de marque ; nom exact dans `docs/audits/CODEX_MIGRATION_INVENTORY.json` |
| `icons/logo.png` | 272 Ko | aucune référence |
| `icons/icone.png`, `icone_final.png`, `logo_android12.png`, `logo_splash.png` | 2,0 Mo | cités seulement par des tests qui vérifient qu’ils ne sont **plus** utilisés |
| `images/student_portrait_v2.png` | 660 Ko | aucune référence |
| `lottie/*.json` (6) | 470 Ko | aucune référence ; `lottie` n’est même pas une dépendance |
| `onboarding/slide_1..4.jpg` | 3,6 Mo | ancien accueil en diapositives |
| `tutors/{bac,bepc,proba}_{boy,girl}.jpg` | 3,8 Mo | anciens tuteurs par examen, remplacés par Kira et Léo |
| `animations/rive/intellia_splash.riv` | 1 Ko | aucune référence |

Proposition : supprimer ces fichiers dans un commit dédié après accord, en
gardant les tests « ne doit plus être utilisé » qui ne dépendent que des
chemins (ils continuent de passer sans les fichiers). Vérifier d’abord
qu’aucun document de marque (`docs/rebranding/`) ne les cite comme source.

Le risque R-017 de `docs/audits/CODEX_RISK_REGISTER.md` (« images lourdes,
application plus grosse ») est en partie obsolète : le logo de l’ancienne marque, les
diapositives et les portraits de tuteurs ne sont plus embarqués. Les chemins
figurent encore dans `docs/audits/CODEX_MIGRATION_INVENTORY.json` comme
historique de migration.
