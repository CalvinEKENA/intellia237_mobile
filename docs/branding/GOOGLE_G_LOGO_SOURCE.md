# Logo « G » de Google — provenance

Les fichiers de `assets/branding/google/` sont le logo « G » officiel fourni par Google, sans aucune
modification (ni redessin, ni recoloration, ni recompression).

- Source : SDK Google Play services, artefact Maven
  `com.google.android.gms:play-services-base:18.9.0` (dépendance transitive de
  `google_sign_in_android` via `play-services-auth`), ressource Android
  `googleg_standard_color_18.png`. C'est l'image que Google utilise dans ses
  propres boutons de connexion ; elle est de toute façon embarquée dans l'APK
  par cette dépendance.
- Extraction : copie octet pour octet depuis l'AAR du cache Gradle local, le
  23 septembre 2026. Aucun téléchargement tiers.

| Fichier Flutter | Densité Android d'origine | Taille | SHA-256 |
| --- | --- | --- | --- |
| `googleg_standard_color_18.png` | `drawable-mdpi` | 18 × 18 | `788a3b9472e9a46e1b6b68d918cd1571914b732e93aab014d77f20be5374e9de` |
| `1.5x/googleg_standard_color_18.png` | `drawable-hdpi` | 27 × 27 | `f221f962a62c954a11b1734e9631fc8531e34bee557665fea864aa4386e25e39` |
| `2.0x/googleg_standard_color_18.png` | `drawable-xhdpi` | 36 × 36 | `90c44675525e290332f7dba6adb97c7af3b8299e56cf5211e893d0e1dec41547` |
| `3.0x/googleg_standard_color_18.png` | `drawable-xxhdpi` | 54 × 54 | `549a81cda776769840f37f184d34eb673ff9e5c0671c67172818e91273753e1a` |

Usage (consignes de marque Google, thème clair) : logo affiché à 18 dp, sur
fond blanc, contour #747775, libellé #1F1F1F en Roboto Medium 14. Voir
`lib/features/auth/presentation/widgets/google_sign_in_button.dart`.

Ne pas remplacer ces fichiers par un dessin, une vectorisation maison ou une
image trouvée en ligne.
