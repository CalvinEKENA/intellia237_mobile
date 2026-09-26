# INTELLIA 237 web — mise en ligne sur Hostinger (savoir.intellia237.com)

La version web est la même application que la version Android, compilée pour
le navigateur à partir du même code. Toute amélioration de l'app profite aux
deux ; il suffit de reconstruire et de redéposer le site.

## 1. Construire le site

Depuis la racine du projet :

```
flutter build web --release -t lib/main_production.dart --base-href /
```

Sous Git Bash, préfixer par `MSYS_NO_PATHCONV=1` (sinon « / » devient un
chemin Windows). Si la compilation échoue avec « PathExistsException »,
supprimer `build/web` et relancer.

Le résultat est dans `build/web` (fichier `.htaccess` compris). Une archive
prête à déposer est produite dans `build/intellia237_web_savoir.zip`.

## 2. Créer le sous-domaine (une seule fois)

hPanel Hostinger → Domaines → Sous-domaines → créer `savoir` sur
`intellia237.com`. Hostinger crée son dossier (par exemple
`public_html/savoir`). Activer le certificat SSL du sous-domaine
(hPanel → Sécurité → SSL) : la connexion par SMS exige HTTPS.

## 3. Déposer le site

Gestionnaire de fichiers Hostinger → dossier du sous-domaine → vider son
contenu → importer `intellia237_web_savoir.zip` → Extraire. Vérifier que
`index.html` et `.htaccess` sont directement dans le dossier (pas dans un
sous-dossier). Afficher les fichiers cachés pour voir `.htaccess`.

## 4. Réglages Firebase et Google (une seule fois)

| Réglage | État |
|---|---|
| Domaine autorisé pour la connexion (Firebase Authentication) | fait par le propriétaire le 23/09/2026 (vérifié) |
| Accès du site aux images des cours (CORS du stockage) | à appliquer : `gcloud storage buckets update gs://edunova-aabd1.firebasestorage.app --cors-file=docs/web/storage-cors.json` |
| Google sur le web | plus tard : origine `https://savoir.intellia237.com` dans le client OAuth Web, puis bouton Google web à développer |

## 5. Vérifier après chaque mise en ligne

- Ouvrir https://savoir.intellia237.com sur un téléphone Android, un iPhone
  et un ordinateur : page d'attente INTELLIA 237, puis l'onboarding.
- Connexion par numéro : le SMS arrive, le code est accepté.
- Images d'une leçon et du Parcours affichées (après le réglage CORS).
- iPhone : Safari → Partager → « Sur l'écran d'accueil » : l'app s'ouvre
  comme une application.

## Différences connues avec l'app Android

- Pas de rappels ni de notifications push (le navigateur ne les reçoit pas
  sans configuration dédiée ; sur iPhone, seulement une fois le site ajouté à
  l'écran d'accueil).
- Google : « bientôt disponible », comme indiqué plus haut.
- Premier chargement : environ 3 Mo compressés (le code et le moteur
  d'affichage) ; ensuite le navigateur les garde et ne revérifie que les
  changements.
- Ordinateur : l'application s'affiche dans une colonne centrée de la
  largeur d'un grand téléphone, pour garder des lignes lisibles.
