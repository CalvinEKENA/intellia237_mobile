# Design System Intellia237 Web

Ce document recense les tokens de design réels extraits du code source du projet de référence Web (`C:\projets\FlutterProjects\Intellia237\intellia237`).

---

## 1. Palette de Couleurs

### A. Couleurs de Marque (Brand Colors)
Définies dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L12-L16) et [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L14-L16).
* **Brand Indigo** : `#5856D6` (`--brand-indigo`)
* **Brand Purple** : `#AF52DE` (`--brand-purple`)
* **Brand Blue** : `#007AFF` (`--brand-blue`)

### B. Couleurs Nationales du Cameroun
Définies dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L29-L33) pour les touches locales.
* **Cameroon Green** : `#007A5E`
* **Cameroon Red** : `#CE1126`
* **Cameroon Yellow** : `#FCD116`

### C. Couleurs Système et Surfaces (Neutrals)
Définies dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L17-L22) et [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L5-L11).
* **Background Primary** : `#FFFFFF` (`--bg-primary` / `bg-white`)
* **Background Secondary** : `#F6F6F3` (`--bg-secondary`) / `#E5E5EA` (`system.bg2` / `bg-system-bg2`)
* **Background Tertiary** : `#E9E9E3` (`--bg-tertiary`)
* **Background System (iOS)** : `#F2F2F7` (`system.bg` / `bg-system-bg`)
* **Premium Background** : `#FBFAF7` (`--bg-premium`)
* **Surface Premium** : `rgba(255, 255, 255, 0.92)` (`--surface-premium`)
* **Text Primary (Label)** : `#121316` (`--text-primary`) / `#3C3C43` (`system.label` / `--text-secondary`)
* **Text Secondary (Tertiary Label)** : `#8E8E93` (`system.tertiary` / `--text-tertiary`)

### D. Couleurs de Statut et Progression
Définies dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L23-L28) et [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L45-L49).
* **Success** : `#34C759` (`--success`)
* **Warning** : `#FF9500` (`--warning`)
* **Error** : `#FF3B30` (`--error`)
* **XP Gold** : `#FFD60A` (`--xp-gold`)

---

## 2. Dégradés Signature (Gradients)

Définis dans [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L18-L29) et [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L65-L74).

* **Brand Gradient** : `linear-gradient(135deg, #5856D6 0%, #AF52DE 100%)` (`--gradient-brand`)
* **Surface Gradient** : `linear-gradient(180deg, rgba(255,255,255,0.9) 0%, rgba(242,242,247,0.95) 100%)` (`--gradient-surface`)
* **Math Gradient** : `linear-gradient(135deg, #007AFF 0%, #5856D6 100%)` (`--gradient-math`)
* **English Gradient** : `linear-gradient(135deg, #FF9500 0%, #FF6B6B 100%)` (`--gradient-english`)
* **Kira Gradient** : `linear-gradient(135deg, #FF9ECD 0%, #AF52DE 100%)` (`--gradient-kira` - voir [companion.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/lib/companion.ts#L55))
* **Léo Gradient** : `linear-gradient(135deg, #5AC8FA 0%, #5856D6 100%)` (`--gradient-leo` - voir [companion.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/lib/companion.ts#L77))
* **Physics Gradient** : `linear-gradient(135deg, #34C759 0%, #00C7BE 100%)`
* **Spanish Gradient** : `linear-gradient(135deg, #FF3B30 0%, #FF9500 100%)`
* **German Gradient** : `linear-gradient(135deg, #1D1D1F 0%, #FFD60A 100%)`

---

## 3. Typographies et Échelles de Texte

Définies dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L41-L64) et [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L94-L96).

### A. Polices de Caractères
* **Display Font (Titres)** : `var(--font-display)`, `-apple-system`, `BlinkMacSystemFont`, `sans-serif` (Didot par défaut selon les configurations globales utilisateur).
* **Body Font (Corps de texte)** : `var(--font-body)`, `-apple-system`, BlinkMacSystemFont, `sans-serif` (Montserrat par défaut selon les configurations globales utilisateur).

### B. Échelles Typographiques
* **hero** : `36px` | Hauteur de ligne : `1.15` | Graisse : `700` (Bold)
* **title1** : `28px` | Hauteur de ligne : `1.2` | Graisse : `700` (Bold)
* **title2** : `22px` | Hauteur de ligne : `1.25` | Graisse : `650` (Medium-Bold)
* **title3** : `18px` | Hauteur de ligne : `1.3` | Graisse : `600` (Semi-Bold)
* **body** : `16px` | Hauteur de ligne : `1.5` | Graisse : `400` (Regular)
* **callout** : `15px` | Hauteur de ligne : `1.4` | Graisse : `500` (Medium)
* **caption** : `13px` | Hauteur de ligne : `1.35` | Graisse : `400` (Regular)
* **micro** : `11px` | Hauteur de ligne : `1.2` | Graisse : `500` (Medium)

---

## 4. Radii et Shapes (Rayons de Bordure)

Définis dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L35-L40) et [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L51-L56).
* **Radius SM** (`ios-sm`) : `10px` (petits éléments, tags)
* **Radius MD** (`ios` / `--radius-md`) : `16px` (boutons de taille moyenne, inputs)
* **Radius LG** (`ios-lg` / `--radius-lg`) : `22px` (cartes, boutons larges)
* **Radius XL** (`ios-xl` / `--radius-xl`) : `28px` (panneaux, sélecteurs, popups)
* **Radius Full** (`--radius-full`) : `9999px` (avatars, pilules)

---

## 5. Ombres (Shadows)

Définis dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L75-L83) et [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L58-L67).
* **Shadow XS** (`ios-xs`) : `0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)`
* **Shadow SM** (`ios-sm`) : `0 4px 12px rgba(0,0,0,0.08), 0 2px 4px rgba(0,0,0,0.04)`
* **Shadow MD** (`ios`) : `0 8px 24px rgba(0,0,0,0.10), 0 4px 8px rgba(0,0,0,0.06)`
* **Shadow LG** (`ios-lg`) : `0 16px 48px rgba(0,0,0,0.12), 0 8px 16px rgba(0,0,0,0.06)`
* **Brand Shadow** (`brand`) : `0 8px 32px rgba(88, 86, 214, 0.25)`
* **Brand Strong Shadow** (`brand-strong`) : `0 8px 32px rgba(88, 86, 214, 0.35)`
* **Glass Shadow** (`glass`) : `0 8px 32px rgba(0,0,0,0.08)` / `0 12px 34px rgba(18, 19, 22, 0.07)`

---

## 6. Flous d'Arrière-Plan (Backdrop Blur)

Définis dans [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts#L84-L89) et [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css#L69-L73).
* **Blur SM** : `8px`
* **Blur MD** : `16px`
* **Blur LG** : `24px`
* **Blur XL** : `40px`

---

## 7. Base UI Components Styles

### A. Boutons (`Button`)
Stylisés dans [button.tsx](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/components/ui/button.tsx#L8-L39).
* **Forme** : Toujours `rounded-full` (Radius infini / capsule).
* **Animations** : `active:scale-[0.97]` pour un retour haptique visuel doux à la pression (150ms).
* **Variantes de styles** :
  * **Primary** : `bg-brand-indigo text-white shadow-brand-strong hover:brightness-105`
  * **Secondary** : `bg-system-bg text-brand-indigo hover:bg-system-bg2`
  * **Ghost** : `border border-brand-indigo/30 text-brand-indigo bg-transparent hover:bg-brand-indigo/5`
  * **Danger** : `bg-status-error text-white shadow-[0_8px_32px_rgba(255,59,48,0.3)] hover:brightness-105`
  * **Companion** : Gradient dynamique du compagnon actif (`#FF9ECD` to `#AF52DE` pour Kira, `#5AC8FA` to `#5856D6` pour Léo), texte blanc et ombre `shadow-brand-strong`.

### B. Cartes (`Card`)
Stylisées dans [card.tsx](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/components/ui/card.tsx#L7-L38).
* **Forme** : Coins arrondis en `rounded-ios-lg` (`22px`).
* **Animations interactives** : `transition: transform 120ms` + `active:scale(0.96)`.
* **Variantes de styles** :
  * **Glass** (default) : `glass-card border border-white/70` (Mélange de fond `--glass-bg` blanc translucide à 78% et flou XL `40px`).
  * **Solid** : `bg-system-bg border border-black/[0.04]`
  * **Elevated** : `premium-surface` (Fond blanc opaque à 92%, fine bordure noire à 6%, ombre portée `0 14px 38px rgba(18,19,22,0.07)`).
  * **Gradient** : `bg-brand-gradient text-white shadow-brand`
  * **Outline** : `bg-white/92 border border-black/[0.07]`
  * **Quiet** : `bg-white/70 border border-black/[0.04] shadow-ios-xs`
