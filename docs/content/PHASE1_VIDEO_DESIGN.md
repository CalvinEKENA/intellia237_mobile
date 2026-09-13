# Phase 1 — contrat avant implémentation

Base Git des correctifs précédents : a6bb3ce. Aucun push. Production interdite pour les essais.

## Compatibilité auditée

Le catalogue utilise les clés de SchoolClassX (6eme…Terminale, Form1…UpperSixth). AcademicLevelIdentity distingue système et général/technique. Les champs historiques classLevels, series/allowedSeries et scope sont hétérogènes. Ils restent lisibles via un adaptateur ; pas de migration de production automatique.

## Décision audience

Un document optionnel `audience: {version: 1, clauses: [...]}` décrit une union de groupes. Dans chaque groupe, les dimensions sont intersectées : educationSystems, educationTypes, classLevels, series, tracks, languages, establishments. Une liste vide signifie « sans restriction de cette dimension ». Les systèmes/types sont explicites ; le moteur ne contient aucun cas C/D. Les classes utilisent les identifiants historiques canoniques, conservés pour les catalogues. Le scope existant reste le périmètre maximal d’écriture ; une audience ne peut pas l’élargir. Le profil d’élève est relu côté serveur et l’établissement provient de users, jamais du candidat d’inscription.

Sans audience explicite : adaptation du niveau du chemin/classLevels, series/allowedSeries et scope. Un document malformé avec audience ne retombe jamais sur un accès global. Les restrictions parentales restent applicables aux enfants et aux compagnons.

Les lectures de découverte passent par des projections serveur : éviter d’exposer les index contenant des titres de brouillons et éviter un produit cartésien de champs d’index tableaux. Lecture directe des contenus réservée au personnel légitime ; les anciens élèves ont besoin de la mise à jour initiale lors du déploiement des nouvelles règles. Ne pas déployer les règles seules avant le client et les callables.

## Média

MediaBlock existant, MP4/H.264/AAC <=150 MiB. Chemin canonique inchangé. Résolution autorisée côté serveur pour l’élève ; URL courte durée après contrôle du propriétaire logique (leçon) et audience. Les brouillons Storage restent réservés aux auteurs. Aucun token de téléchargement durable incorporé au document.

## Validation

Matrice audience FR/EN, général/technique, classes multiples, séries, tout secondaire, établissements. FLOW : 320/360/390/412/480/600+ × échelles 1/1.15/1.3/1.5/2 ; longs textes et formules sans compression ni troncature. Lecteur réseau et source locale, cycle de vie et retrait du viewport. Tests MP4 réels sur environnement isolé ; staging distant inaccessible au début (403 ou projet absent).
