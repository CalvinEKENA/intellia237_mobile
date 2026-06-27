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
