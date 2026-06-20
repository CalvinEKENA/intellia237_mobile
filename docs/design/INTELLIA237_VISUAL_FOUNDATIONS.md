# Charte Graphique & Visual Foundations - INTELLIA237

Ce document spécifie les fondations visuelles, le design system, la charte graphique premium claire, ainsi que les composants visuels réutilisables d'INTELLIA237.

---

## 1. Design Tokens Centralisés

Tous les jetons visuels (design tokens) sont centralisés dans [design_tokens.dart](file:///C:/projets/FlutterProjects/Intellia237/lib/app/theme/design_tokens.dart).

### A. Couleurs (`IntelliaColors`)
* **Brand Indigo** : `0xFF5856D6` - Couleur principale de marque claire et premium.
* **Brand Purple** : `0xFFAF52DE` - Couleur d'accent secondaire et compagnon Kira.
* **Brand Blue** : `0xFF007AFF` - Couleur d'accent tertiaire et compagnon Léo.
* **Background Primary** : `0xFFFCFCFF` - Fond principal propre, clair et aéré.
* **Background Premium** : `0xFFFBFAF7` - Fond ivoire haut de gamme utilisé sur le Splash et l'Onboarding.
* **Surface Solid** : `0xFFFFFFFF` - Surface des cartes et formulaires.
* **Surface Glass** : `0xB8FFFFFF` (opacité 72%) - Verre translucide flouté (glassmorphism).

### B. Dégradés (`IntelliaGradients`)
* **Brand** : Indigo vers Purple - Utilisé pour l'identité principale.
* **Kira** : Rose clair vers Purple - Gradient caractéristique de Kira.
* **Leo** : Bleu clair vers Indigo - Gradient caractéristique de Léo.
* **Math, French, Physics, English, History** : Gradients thématiques dédiés pour chaque matière scolaire.

### C. Typographies (`IntelliaTypography`)
* **Titres** : Didot (chargé via Google Fonts `Playfair Display`) - Élégant, raffiné et historique.
* **Corps de texte** : `Montserrat` - Géométrique, moderne et très lisible sur écrans mobiles.

### D. Espacements & Radii
* **IntelliaSpacing** : Échelle logique de `xxs` (4px) à `xxxl` (56px).
* **IntelliaRadii** : Rayons harmonieux de `small` (10px), `medium` (16px), `large` (22px), `extraLarge` (28px).

### E. Animations (`IntelliaMotion`)
* Durées standardisées : `instant` (80ms), `press` (150ms), `fast` (180ms), `medium` (280ms), `slow` (420ms), `cinematic` (700ms).

---

## 2. Thème Global de l'Application

Le thème global est configuré dans [app_theme.dart](file:///C:/projets/FlutterProjects/Intellia237/lib/app/theme/app_theme.dart) :
* Une architecture **Matières 3** propre avec une charte de couleurs claires dominante (sans fond noir, bleu marine lourd ou saturé).
* Personnalisation poussée de `FilledButtonTheme`, `OutlinedButtonTheme`, `InputDecorationTheme`, `CardTheme` et `AppBarTheme`.
* Configuration des transitions de page natives fluides (`CupertinoPageTransitionsBuilder` sur iOS et `ZoomPageTransitionsBuilder` sur Android).

---

## 3. Composants Communs Premium (`lib/core/widgets/`)

### A. IntelliaScaffold
* Encapsule la structure de base claire de l'application.
* Intègre une halo radial subtil et dégradé (`brandIndigo` / `brandPurple`) au sommet de l'écran (opacité 0.08) pour un effet de lumière premium.

### B. IntelliaPressable
* Base de tous les boutons et éléments cliquables tactiles.
* **Effet d'Échelle** : Réduction légère de la taille à `0.97` de façon fluide lors du maintien (150ms).
* **Retour Haptique** : Déclenchement de vibrations physiques (`selectionClick`) lors du clic.
* **Double-tap Guard** : Empêche les clics répétés accidentels (debounce de 350ms) pour sécuriser la navigation.

### C. Intellia Buttons (`intellia_buttons.dart`)
* **IntelliaPrimaryButton** : Bouton solide avec dégradé de marque et lueur (shadow glow).
* **IntelliaGlassButton** : Effet de verre flouté premium.
* **IntelliaOutlineButton** : Bordure fine sophistiquée.
* **IntelliaTextButton** / **IntelliaIconButton** : Variantes minimalistes réactives.

### D. IntelliaCard
* Cartes aux coins arrondis (`22px`) déclinées en variantes : `quiet`, `solid`, `elevated`, `glass`, `gradient`, `outline`.

### E. IntelliaTextField & IntelliaPasswordField
* Champs de saisie élégants avec bordure fine, support de thème clair/sombre, et bouton d'affichage/masquage intégré pour les mots de passe.

---

## 4. Design Guidelines Premium
1. **Pas d'illustrations de robots** ni de références froides d'IA ("Tuteur IA"). L'utilisateur interagit uniquement avec les compagnons humains bienveillants (Kira et Léo).
2. **Aucun overflow toléré** grâce à l'utilisation systématique de dispositions fluides, de `SingleChildScrollView` et de tailles de texte dynamiques.
3. **Contrastes élevés** conformes aux standards d'accessibilité WCAG tout en conservant une identité visuelle chic et épurée.
