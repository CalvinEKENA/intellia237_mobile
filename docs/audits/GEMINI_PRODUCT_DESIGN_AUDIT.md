# Rapport d'Audit Produit & UX : Intellia237

**Auteurs** : Directeur Produit, Directeur Artistique Numérique, UX Designer Senior, Expert Flutter  
**Contexte** : Migration et Rebranding de l'application EduNova vers Intellia237 Mobile  
**Date** : 18 Juin 2026

---

## 1. Résumé Exécutif

Cet audit compare le projet Web de référence **Intellia237** et le projet mobile existant **EduNova** (en cours de rebranding). Notre inspection révèle une divergence totale d'identité visuelle, de philosophie d'accompagnement (tuteurs) et de fonctionnalités de monétisation (paywall absent sur mobile).

L'objectif de cette migration n'est pas une simple réplication ou l'intégration d'une WebView, mais une transposition fidèle des forces esthétiques du web (clarté, fluidité, glassmorphism de style iOS, boutons capsules, duo de compagnons Kira et Léo) dans une architecture Flutter moderne et robuste.

---

## 2. Identité Visuelle Actuelle : Web vs Mobile

### A. Le Projet Web (Référence)
* **Esthétique** : Style "iOS Premium", très clair, aéré, moderne. Il repose sur du glassmorphic translucide (blanc à 78%, flou d'arrière-plan de 40px) et des contours fins.
* **Palette** : Indigo (`#5856D6`), Purple (`#AF52DE`), et Blue (`#007AFF`) avec les couleurs du Cameroun (Vert `#007A5E`, Rouge `#CE1126`, Jaune `#FCD116`).
* **Formes** : Les boutons sont strictement des capsules (`rounded-full`), les cartes ont des angles généreux (`22px`).
* **Typographie** : Didot pour les titres (élégant, classique) et Montserrat pour le corps (neutre, lisible).
* **Fichiers clés** : [tailwind.config.ts](file:///C:/projets/FlutterProjects/Intellia237/intellia237/tailwind.config.ts), [globals.css](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/globals.css).

### B. Le Projet Mobile Existant (EduNova)
* **Esthétique** : Style "Sombre et Solennel", dominé par du bleu marine foncé et des touches dorées/sarcelle. Le design fait très "académique classique".
* **Palette** : Navy (`#0B1F4A`), Bleu (`#1451E1`), Sarcelle (`#11AFA5`), et Or (`#F5A623`).
* **Formes** : Angles plus secs (`AppRadius.md` = 18px pour les boutons et `AppRadius.lg` = 26px pour les cartes).
* **Typographie** : Playfair Display pour les titres et Manrope pour les chiffres.
* **Fichiers clés** : [design_tokens.dart](file:///C:/projets/FlutterProjects/Intellia237/lib/app/theme/design_tokens.dart).

> [!WARNING]
> **Divergence Majeure** : Le mobile a été conçu avec une palette bleu marine sombre, tandis que le web utilise un univers clair, blanc et violet. Pour assurer la cohérence de marque, le mobile doit abandonner son thème sombre au profit de la palette claire et violette/indigo d'Intellia.

---

## 3. Qualité et Différences de l'Onboarding

### Web Onboarding
* **Structure** : 4 slides interactives défilant automatiquement toutes les 4 secondes (ou par balayage).
* **Visuels** : Entièrement construits en CSS vectoriel animé via Framer Motion. Pas de fichiers d'images matricielles (pixels) lourdes, ce qui permet un chargement instantané.
* **Copie** : Axée sur le compagnon d'étude, la clarté et l'absence de stress. Aucune mention d'intelligence artificielle ou de robot.
* **Fichier clé** : [page.tsx (onboarding)](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/app/%28public%29/onboarding/page.tsx).

### Mobile Onboarding
* **Structure** : 4 slides pilotées par un `PageController` avec une barre de progression animée de 6 secondes.
* **Visuels** : Utilise 4 grandes images JPEG (`assets/onboarding/slide_1.jpg`, etc.) pesant près de 1 Mo chacune, ce qui surcharge le package de l'application.
* **Copie** : Utilise des expressions comme "Ton compagnon artificiel" ou "Un tuteur IA" et affiche un émoji de robot.
* **Fichier clé** : [onboarding_screen.dart](file:///C:/projets/FlutterProjects/Intellia237/lib/features/onboarding/presentation/onboarding_screen.dart).

> [!IMPORTANT]
> **Règle Pédagogique Non Négociable** : Le projet web applique une interdiction stricte de mentionner l'expression "IA" ou de dessiner des robots. Les compagnons sont des personnages de fiction pour désinhiber les adolescents. L'onboarding mobile doit être nettoyé et harmonisé sur les textes du web.

---

## 4. Représentation de Kira et Léo : L'Écart Majeur

Il s'agit de la divergence fonctionnelle la plus critique constatée lors de notre audit :

* **Sur le Web** : Kira (la tutrice patiente) et Léo (le coach stimulant) sont les **deux seuls et uniques compagnons** disponibles pour tous les élèves. Ils sont présentés dès l'onboarding et choisis à l'étape 3 de l'inscription (voir [CompanionSelector.tsx](file:///C:/projets/FlutterProjects/Intellia237/intellia237/src/components/auth/CompanionSelector.tsx)).
* **Sur Mobile** : Kira et Léo sont totalement absents. Le mobile implémente un catalogue de **6 tuteurs d'examens différents** (Ethan, Grâce, Armel, Cynthia, Nathan, Marianne) segmentés par examen (BEPC, Probatoire, Baccalauréat), visibles dans [tutor_persona.dart](file:///C:/projets/FlutterProjects/Intellia237/lib/features/tutor/domain/tutor_persona.dart).

### Solution Pédagogique Mobile Recommandée
1. Supprimer le catalogue des 6 tuteurs d'examens.
2. Implémenter Kira et Léo comme les deux compagnons uniques du parcours élève.
3. Intégrer les illustrations PNG/SVG de Kira et Léo (disponibles dans le dossier `public/companions/` du web) dans le dossier `assets/tutors/` du mobile.

---

## 5. Analyse des Forces et Faiblesses du Projet Mobile

### Forces à Préserver
* **Architecture Propre** : Découpée en fonctionnalités (Features), respectant les principes SOLID et la Clean Architecture (data, domain, presentation).
* **Stack Robuste** : Utilisation de Riverpod pour la gestion des états, GoRouter pour la navigation typée, et Shimmer pour les chargements.
* **Backend Callables** : Les appels vers l'IA utilisent déjà des Cloud Functions Firebase v2 (`askTutor`), centralisant la sécurité et le coût des tokens.

### Faiblesses à Corriger
* **Absence Totale de Paywall/Facturation** : Aucune ligne de code ou écran n'est dédié au paiement mobile (Orange Money / MTN) ou à la limitation à $m$ questions gratuites.
* **Ergonomie Administrative** : La sélection de la classe et des matières à l'inscription utilise des menus déroulants tristes (`DropdownButtonFormField`), loin de l'expérience ludique et premium du web.
* **Assets Lourdes** : Les images d'onboarding font plus de 3.5 Mo au total.

---

## 6. Direction UX pour les Trois Groupes d'Âge

Bien que l'application soit unique, l'interface doit s'adapter dynamiquement selon la classe déclarée de l'élève pour éviter d'infantiliser les lycéens :

### GROUPE A : Collège Cycle 1 (Sixième & Cinquième)
* **Densité** : Faible, très aérée. Gros boutons.
* **Animations** : Fréquentes, célébrations expressives avec confettis sonores.
* **Ton** : Kira est très maternelle et encourageante. Léo utilise un vocabulaire imagé ("Deviens le roi des fractions !").
* **Visuels** : Illustrations colorées et ludiques.

### GROUPE B : Collège Cycle 2 (Quatrième & Troisième)
* **Densité** : Moyenne. Structure claire axée sur l'examen du BEPC.
* **Animations** : Modérées, axées sur la complétion de jalons d'apprentissage.
* **Ton** : Kira insiste sur la méthodologie. Léo met en avant des défis de rapidité et d'évaluation.
* **Visuels** : Équilibre entre schémas et illustrations stylisées.

### GROUPE C : Lycée (Seconde, Première & Terminale)
* **Densité** : Élevée. Plus d'informations à l'écran, schémas de cours techniques.
* **Animations** : Subtiles (transitions de pages rapides, micro-pulsations de boutons). Aucun effet de confettis enfantin.
* **Ton** : Kira s'exprime comme une tutrice universitaire (vocabulaire précis, rigoureux). Léo utilise la métaphore du "coach de performance sportive" orienté vers la réussite du Probatoire et du Baccalauréat.
* **Visuels** : Épurés, minimalistes, axés sur la clarté conceptuelle.

---

## 7. Recommandations de Migration et Plan d'Action

Nous classons nos préconisations par ordre d'importance pour guider l'équipe de développement :

### A. Indispensable (Haute Priorité)
1. **Intégration du Paywall Parent** : Créer l'écran de présentation de l'offre (5 000 FCFA) et le formulaire d'envoi de la référence de transaction Mobile Money (Orange Money & MTN MoMo).
2. **Rebranding Graphique** : Remplacer le nom "EduNova" (lors de la phase de reconstruction future), mettre à jour la palette de couleurs Flutter (`design_tokens.dart`) avec les couleurs claires d'Intellia et adapter les radii à `22px`.
3. **Migration Kira & Léo** : Supprimer les 6 tuteurs existants et intégrer Kira et Léo comme compagnons exclusifs de l'application mobile.

### B. Fortement Recommandé (Moyenne Priorité)
1. **Refonte de l'Onboarding** : Remplacer les images lourdes par les 4 slides textuelles d'Intellia et nettoyer les mentions de robots/IA.
2. **Ergonomie des Formulaires** : Remplacer les listes déroulantes de choix de classe par une grille de cartes interactives avec sélection de série dynamique.
3. **Implémentation de la Limite $m$** : Créer la variable configurable $m$ dans la configuration locale (Zustand/Riverpod) pour verrouiller le chat de l'élève dès le seuil atteint.

### C. Amélioration (Basse Priorité)
1. **L'Intellia Flow** : Initier le flux vertical à la TikTok avec une fin de session stricte à 10 cartes pour encourager des sessions d'apprentissage quotidiennes courtes et qualitatives.
2. **Retour Haptique** : Implémenter des vibrations légères de validation d'exercices.

---

## 8. Questions Ouvertes

Avant de passer à la phase d'exécution, nous soumettons ces questions à la validation de l'équipe produit :
1. **Validation de la Limite $m$** : Quelle valeur par défaut devons-nous attribuer à la variable $m$ ? Le web propose 3 questions libres, est-ce optimal pour le mobile ou devrions-nous passer à 5 ?
2. **Vérification Manuelle des Paiements** : Les requêtes soumises par le parent (Référence + Téléphone) sont validées par une équipe administrative via l'API `/api/payment-requests` du web. Comment le mobile doit-il interagir avec cette validation ? Devons-nous utiliser une Firebase Function d'écoute ou un polling léger ?
3. **Transition Sonore** : Souhaitez-vous intégrer une synthèse vocale (Text-to-Speech) pour que Kira et Léo lisent leurs explications à haute voix (idéal pour le Groupe A) ?
