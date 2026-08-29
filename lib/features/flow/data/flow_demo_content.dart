import '../domain/flow_card.dart';
import '../domain/flow_subject.dart';

/// Feed de démonstration du Flow.
///
/// Contenu en dur (100 % UX), pensé pour des élèves camerounais du secondaire.
/// Ordonné comme une histoire : on découvre une notion, on la voit s'animer,
/// on se teste, on est récompensé, puis on glisse naturellement vers la suite.
/// Structuré pour être remplacé plus tard par un vrai repository sans changer
/// la présentation.
abstract final class FlowDemoContent {
  static List<FlowCard> build() => const <FlowCard>[
    FlowNotionCard(
      id: 'm-pythagore',
      subject: FlowSubjects.maths,
      title: 'Pythagore, en une image',
      insight:
          'Dans un triangle rectangle, le carré de l’hypoténuse égale la '
          'somme des carrés des deux autres côtés.',
      points: [
        'a² + b² = c²',
        'Vrai uniquement si l’angle est droit',
        'Sert à mesurer sans règle : toits, terrains, écrans',
      ],
    ),
    FlowAnimationCard(
      id: 'm-parabole',
      subject: FlowSubjects.maths,
      title: 'La parabole, trajectoire du ballon',
      caption:
          'Un tir au but suit une parabole : y = a·x² + b·x + c. La courbe '
          'monte, atteint un sommet, puis redescend.',
      kind: FlowAnimationKind.parabola,
    ),
    FlowMiniQuizCard(
      id: 'm-quiz-pythagore',
      subject: FlowSubjects.maths,
      question:
          'Un triangle a pour côtés 3 cm et 4 cm autour de l’angle droit. '
          'Quelle est l’hypoténuse ?',
      options: ['5 cm', '6 cm', '7 cm', '12 cm'],
      correctIndex: 0,
      explanation: '3² + 4² = 9 + 16 = 25, et √25 = 5 cm.',
    ),
    FlowRewardCard(
      id: 'reward-1',
      subject: FlowSubjects.maths,
      title: 'Bien lancé !',
      message:
          'Tu viens de valider ta première notion. On continue sur ta lancée.',
    ),
    FlowAnecdoteCard(
      id: 'pc-volta',
      subject: FlowSubjects.pc,
      title: 'D’où vient le mot « volt » ?',
      story:
          'Du physicien Alessandro Volta, inventeur de la première pile en 1800. '
          'Aujourd’hui, ta lampe torche lui doit encore son nom.',
    ),
    FlowAnimationCard(
      id: 'pc-pendule',
      subject: FlowSubjects.pc,
      title: 'Le pendule et l’énergie',
      caption:
          'En haut, l’énergie est potentielle. En bas, elle devient cinétique. '
          'Rien ne se perd : tout se transforme.',
      kind: FlowAnimationKind.pendulum,
    ),
    FlowQuestionCard(
      id: 'pc-ciel-bleu',
      subject: FlowSubjects.pc,
      question: 'Pourquoi le ciel est-il bleu ?',
      answer:
          'La lumière du soleil est diffusée par l’air. Le bleu, de courte '
          'longueur d’onde, se disperse le plus : c’est lui qu’on voit partout.',
    ),
    FlowVideoCard(
      id: 'svt-photosynthese',
      subject: FlowSubjects.svt,
      title: 'La photosynthèse',
      description:
          'Comment une feuille transforme la lumière, l’eau et le CO₂ en '
          'énergie — et libère l’oxygène que tu respires.',
      durationLabel: '0:45',
    ),
    FlowAnimationCard(
      id: 'svt-mitose',
      subject: FlowSubjects.svt,
      title: 'La mitose, une cellule qui se divise',
      caption:
          'Une cellule copie son ADN, s’étire, puis se sépare en deux cellules '
          'identiques. C’est ainsi que ton corps grandit et se répare.',
      kind: FlowAnimationKind.cellDivision,
    ),
    FlowMiniQuizCard(
      id: 'svt-quiz-photo',
      subject: FlowSubjects.svt,
      question: 'Quel gaz la photosynthèse libère-t-elle ?',
      options: [
        'Le dioxygène (O₂)',
        'Le dioxyde de carbone',
        'L’azote',
        'L’hydrogène',
      ],
      correctIndex: 0,
      explanation:
          'La plante absorbe le CO₂ et rejette du dioxygène (O₂), indispensable '
          'à la respiration.',
    ),
    FlowRewardCard(
      id: 'reward-2',
      subject: FlowSubjects.svt,
      title: 'Tu explores large',
      message:
          'Maths, physique, SVT… Ta curiosité couvre déjà plusieurs matières.',
    ),
    FlowAnecdoteCard(
      id: 'fr-mongo-beti',
      subject: FlowSubjects.francais,
      title: 'Une plume camerounaise',
      story:
          'Mongo Beti a écrit « Ville cruelle » sous un pseudonyme pour déjouer '
          'la censure. La littérature, aussi, peut être un acte de courage.',
    ),
    FlowNotionCard(
      id: 'fr-metaphore',
      subject: FlowSubjects.francais,
      title: 'La métaphore',
      insight:
          'Une image directe, sans « comme » : on dit qu’une chose EST une autre.',
      points: [
        '« Cet homme est un lion » → courage',
        'Pas de mot de comparaison',
        'Crée une émotion en une seule image',
      ],
    ),
    FlowQuestionCard(
      id: 'en-polite',
      subject: FlowSubjects.anglais,
      question: 'How do you ask for help politely in English?',
      answer:
          '« Could you help me, please? » — « could » et « please » rendent la '
          'demande douce et respectueuse.',
    ),
    FlowMiniQuizCard(
      id: 'en-quiz',
      subject: FlowSubjects.anglais,
      question: 'Which sentence is the most polite?',
      options: [
        'Could you open the window, please?',
        'Open the window.',
        'Window, now!',
        'You, window.',
      ],
      correctIndex: 0,
      explanation:
          '« Could you… please? » est la forme la plus courtoise pour demander '
          'un service.',
    ),
    FlowMiniQuizCard(
      id: 'math-equation-1',
      subject: FlowSubjects.maths,
      question: 'Si 3x + 5 = 20, combien vaut x ?',
      options: ['3', '5', '8', '15'],
      correctIndex: 1,
      explanation: '3x = 15, donc x = 15 ÷ 3 = 5.',
    ),
    FlowMiniQuizCard(
      id: 'math-fraction-1',
      subject: FlowSubjects.maths,
      question: 'Quelle fraction est égale à 0,75 ?',
      options: ['1/4', '2/3', '3/4', '4/5'],
      correctIndex: 2,
      explanation: '3 ÷ 4 = 0,75.',
    ),
    FlowMiniQuizCard(
      id: 'math-percent-1',
      subject: FlowSubjects.maths,
      question: 'Quel est 20 % de 15 000 FCFA ?',
      options: ['1 500', '2 000', '3 000', '5 000'],
      correctIndex: 2,
      explanation: '20 % = 0,2 ; 15 000 × 0,2 = 3 000 FCFA.',
    ),
    FlowMiniQuizCard(
      id: 'pc-ohm-1',
      subject: FlowSubjects.pc,
      question: 'Dans la loi d’Ohm U = R × I, quelle est l’unité de R ?',
      options: ['Volt', 'Ampère', 'Ohm', 'Watt'],
      correctIndex: 2,
      explanation: 'La résistance électrique R se mesure en ohms (Ω).',
    ),
    FlowMiniQuizCard(
      id: 'pc-energy-1',
      subject: FlowSubjects.pc,
      question: 'Une lampe transforme surtout l’énergie électrique en…',
      options: ['lumière et chaleur', 'masse', 'pression', 'magnétisme seul'],
      correctIndex: 0,
      explanation:
          'Une lampe émet de la lumière et dissipe aussi de la chaleur.',
    ),
    FlowMiniQuizCard(
      id: 'pc-density-1',
      subject: FlowSubjects.pc,
      question: 'La masse volumique est le rapport entre…',
      options: [
        'masse et volume',
        'force et temps',
        'distance et vitesse',
        'énergie et puissance',
      ],
      correctIndex: 0,
      explanation: 'ρ = m/V : masse divisée par volume.',
    ),
    FlowMiniQuizCard(
      id: 'svt-cell-1',
      subject: FlowSubjects.svt,
      question: 'Quel organite contient principalement l’ADN ?',
      options: ['Le noyau', 'La membrane', 'Le cytoplasme', 'La vacuole'],
      correctIndex: 0,
      explanation:
          'Chez les cellules eucaryotes, l’essentiel de l’ADN est dans le noyau.',
    ),
    FlowMiniQuizCard(
      id: 'svt-blood-1',
      subject: FlowSubjects.svt,
      question: 'Quelles cellules transportent principalement le dioxygène ?',
      options: ['Globules rouges', 'Plaquettes', 'Neurones', 'Globules blancs'],
      correctIndex: 0,
      explanation:
          'L’hémoglobine des globules rouges fixe et transporte le dioxygène.',
    ),
    FlowMiniQuizCard(
      id: 'svt-ecosystem-1',
      subject: FlowSubjects.svt,
      question: 'Dans une chaîne alimentaire, une plante verte est…',
      options: [
        'un producteur',
        'un consommateur',
        'un prédateur',
        'un décomposeur',
      ],
      correctIndex: 0,
      explanation:
          'Elle produit sa matière organique grâce à la photosynthèse.',
    ),
    FlowMiniQuizCard(
      id: 'fr-grammar-1',
      subject: FlowSubjects.francais,
      question: 'Dans « Les élèves révisent », quel est le sujet ?',
      options: ['Les élèves', 'révisent', 'élèves révisent', 'Les'],
      correctIndex: 0,
      explanation: 'Le groupe nominal « Les élèves » accomplit l’action.',
    ),
    FlowMiniQuizCard(
      id: 'fr-figure-1',
      subject: FlowSubjects.francais,
      question: '« Il court comme le vent » est…',
      options: [
        'une comparaison',
        'une métaphore',
        'une litote',
        'une personnification',
      ],
      correctIndex: 0,
      explanation: 'Le mot-outil « comme » signale une comparaison.',
    ),
    FlowMiniQuizCard(
      id: 'fr-agreement-1',
      subject: FlowSubjects.francais,
      question: 'Quelle phrase est correctement accordée ?',
      options: [
        'Elles sont arrivées',
        'Elles sont arrivé',
        'Elles est arrivées',
        'Elle sont arrivée',
      ],
      correctIndex: 0,
      explanation:
          'Avec « être », le participe passé s’accorde avec le sujet féminin pluriel.',
    ),
    FlowMiniQuizCard(
      id: 'en-tense-1',
      subject: FlowSubjects.anglais,
      question: 'Choose the correct sentence.',
      options: [
        'She goes to school.',
        'She go to school.',
        'She going school.',
        'She gone to school every day.',
      ],
      correctIndex: 0,
      explanation: 'In the present simple, “she” takes the verb ending -s.',
    ),
    FlowMiniQuizCard(
      id: 'en-vocab-1',
      subject: FlowSubjects.anglais,
      question: 'What is the opposite of “difficult”?',
      options: ['Easy', 'Heavy', 'Slow', 'Late'],
      correctIndex: 0,
      explanation: '“Easy” means “facile”, the opposite of “difficult”.',
    ),
    FlowMiniQuizCard(
      id: 'en-past-1',
      subject: FlowSubjects.anglais,
      question: 'Complete: Yesterday, we ___ football.',
      options: ['played', 'play', 'plays', 'playing'],
      correctIndex: 0,
      explanation: '“Yesterday” calls for the simple past: played.',
    ),
    FlowMiniQuizCard(
      id: 'hg-cameroon-1',
      subject: FlowSubjects.histoireGeo,
      question: 'En quelle année le Cameroun a-t-il accédé à l’indépendance ?',
      options: ['1960', '1958', '1965', '1972'],
      correctIndex: 0,
      explanation:
          'La République du Cameroun devient indépendante le 1er janvier 1960.',
    ),
    FlowMiniQuizCard(
      id: 'hg-capital-1',
      subject: FlowSubjects.histoireGeo,
      question: 'Quelle est la capitale politique du Cameroun ?',
      options: ['Yaoundé', 'Douala', 'Garoua', 'Bafoussam'],
      correctIndex: 0,
      explanation:
          'Yaoundé est la capitale politique ; Douala est la capitale économique.',
    ),
    FlowMiniQuizCard(
      id: 'hg-climate-1',
      subject: FlowSubjects.histoireGeo,
      question: 'Quel instrument mesure les précipitations ?',
      options: [
        'Le pluviomètre',
        'Le thermomètre',
        'La girouette',
        'Le baromètre',
      ],
      correctIndex: 0,
      explanation: 'Le pluviomètre mesure la quantité de pluie tombée.',
    ),
    FlowMiniQuizCard(
      id: 'philo-truth-1',
      subject: FlowSubjects.philo,
      question: 'Une opinion est-elle nécessairement une vérité ?',
      options: [
        'Non',
        'Oui, toujours',
        'Seulement si elle est populaire',
        'Seulement si elle est ancienne',
      ],
      correctIndex: 0,
      explanation:
          'Une opinion doit être examinée et justifiée pour prétendre à la vérité.',
    ),
    FlowMiniQuizCard(
      id: 'philo-freedom-1',
      subject: FlowSubjects.philo,
      question:
          'Être libre signifie-t-il simplement faire tout ce que l’on veut ?',
      options: [
        'Non, la liberté implique aussi responsabilité et règles',
        'Oui, sans aucune limite',
        'Oui, si personne ne regarde',
        'Non, car personne n’est libre',
      ],
      correctIndex: 0,
      explanation:
          'La liberté se pense avec la responsabilité et celle des autres.',
    ),
    FlowNotionCard(
      id: 'philo-conscience',
      subject: FlowSubjects.philo,
      title: 'La conscience',
      insight:
          'C’est la capacité de se savoir soi-même : penser, et savoir que l’on pense.',
      points: [
        'Conscience immédiate : je ressens',
        'Conscience réfléchie : je m’observe',
        '« Je pense, donc je suis » — Descartes',
      ],
    ),
    FlowTrueFalseCard(
      id: 'tf-math-square',
      subject: FlowSubjects.maths,
      statement: 'Le carré d’un nombre négatif est toujours positif ou nul.',
      correctValue: true,
      explanation:
          'Multiplier deux nombres de même signe donne un résultat positif ; 0² vaut 0.',
    ),
    FlowTrueFalseCard(
      id: 'tf-pc-series-current',
      subject: FlowSubjects.pc,
      statement:
          'Dans un circuit en série, l’intensité du courant est la même en tout point.',
      correctValue: true,
      explanation:
          'Le courant ne rencontre qu’un seul chemin : la même intensité traverse chaque dipôle.',
    ),
    FlowTrueFalseCard(
      id: 'tf-svt-genes',
      subject: FlowSubjects.svt,
      statement: 'Les gènes sont portés par les chromosomes.',
      correctValue: true,
      explanation:
          'Un chromosome est constitué d’ADN et porte de nombreux gènes.',
    ),
    FlowTrueFalseCard(
      id: 'tf-hg-capital',
      subject: FlowSubjects.histoireGeo,
      statement: 'Douala est la capitale politique du Cameroun.',
      correctValue: false,
      explanation:
          'Yaoundé est la capitale politique ; Douala est la capitale économique.',
    ),
    FlowFillBlankCard(
      id: 'fill-math-equation',
      subject: FlowSubjects.maths,
      prompt: 'Complète : si 7x = 42, alors x = ___.',
      acceptedAnswers: ['6', 'six'],
      hint: 'Divise les deux membres par 7.',
      explanation: '42 ÷ 7 = 6, donc x = 6.',
    ),
    FlowFillBlankCard(
      id: 'fill-fr-author',
      subject: FlowSubjects.francais,
      prompt:
          'Complète : l’auteur camerounais de « Mission terminée » est ___.',
      acceptedAnswers: ['Mongo Beti', 'Beti'],
      hint: 'Son nom apparaît dans une autre carte du Flow.',
      explanation:
          'Mongo Beti est l’un des grands romanciers camerounais du XXᵉ siècle.',
    ),
    FlowFillBlankCard(
      id: 'fill-en-past-go',
      subject: FlowSubjects.anglais,
      prompt: 'Complete: Yesterday, Amina ___ to school. (go)',
      acceptedAnswers: ['went'],
      hint: '“Go” is an irregular verb.',
      explanation: 'The simple past of “go” is “went”.',
    ),
    FlowFillBlankCard(
      id: 'fill-svt-photosynthesis',
      subject: FlowSubjects.svt,
      prompt:
          'Complète : pendant la photosynthèse, la plante absorbe le dioxyde de ___.',
      acceptedAnswers: ['carbone', 'carbone co2', 'CO2'],
      hint: 'Sa formule est CO₂.',
      explanation:
          'La plante absorbe le dioxyde de carbone et libère du dioxygène.',
    ),
    FlowOrderingCard(
      id: 'order-math-equation',
      subject: FlowSubjects.maths,
      instruction:
          'Remets les étapes de résolution de 3x + 5 = 20 dans l’ordre.',
      items: [
        'Soustraire 5 aux deux membres',
        'Obtenir 3x = 15',
        'Diviser les deux membres par 3',
        'Vérifier que x = 5',
      ],
      explanation:
          'On isole progressivement x, puis on remplace x dans l’équation pour vérifier.',
    ),
    FlowOrderingCard(
      id: 'order-science-method',
      subject: FlowSubjects.pc,
      instruction: 'Remets la démarche scientifique dans son ordre logique.',
      items: [
        'Observer un phénomène',
        'Formuler une hypothèse',
        'Réaliser une expérience',
        'Interpréter et conclure',
      ],
      explanation:
          'Une expérience teste l’hypothèse issue de l’observation ; les résultats permettent ensuite de conclure.',
    ),
    FlowOrderingCard(
      id: 'order-fr-narrative',
      subject: FlowSubjects.francais,
      instruction: 'Remets les grandes étapes d’un récit dans l’ordre.',
      items: [
        'Situation initiale',
        'Élément perturbateur',
        'Péripéties',
        'Dénouement',
        'Situation finale',
      ],
      explanation:
          'Ce schéma narratif aide à comprendre comment une histoire se transforme.',
    ),
    FlowOrderingCard(
      id: 'order-hg-cameroon',
      subject: FlowSubjects.histoireGeo,
      instruction:
          'Classe ces repères de l’histoire du Cameroun du plus ancien au plus récent.',
      items: [
        'Indépendance du Cameroun oriental — 1960',
        'Réunification — 1961',
        'État unitaire — 1972',
      ],
      explanation:
          'Ces trois dates structurent la formation institutionnelle du Cameroun contemporain.',
    ),
    FlowRewardCard(
      id: 'reward-final',
      subject: FlowSubjects.philo,
      title: 'Belle session !',
      message:
          'Tu as parcouru tout un fil de savoirs. Reviens demain : ta série '
          't’attend, et de nouvelles cartes aussi.',
    ),
  ];
}
