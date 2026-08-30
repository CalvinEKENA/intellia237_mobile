enum IntelliaOffer { essentiel, plus, max }

enum IntelliaCapability {
  lessons,
  exercises,
  quizzes,
  flow,
  arena,
  kiraAndLeoText,
  textSummariesAndExplanations,
  voice,
  vision,
  extendedMultimodal,
  advancedMultimodal,
}

class IntelliaOfferDetails {
  const IntelliaOfferDetails({
    required this.offer,
    required this.monthlyPriceXaf,
    required this.supportLabelFr,
    required this.supportLabelEn,
    required this.voice,
    required this.vision,
    required this.multimodalLevel,
    required this.capabilities,
  });

  final IntelliaOffer offer;
  final int monthlyPriceXaf;
  final String supportLabelFr;
  final String supportLabelEn;
  final bool voice;
  final bool vision;
  final int multimodalLevel;
  final Set<IntelliaCapability> capabilities;

  bool includes(IntelliaCapability capability) =>
      capabilities.contains(capability);

  static const values = <IntelliaOffer, IntelliaOfferDetails>{
    IntelliaOffer.essentiel: IntelliaOfferDetails(
      offer: IntelliaOffer.essentiel,
      monthlyPriceXaf: 5000,
      supportLabelFr: 'Accompagnement essentiel',
      supportLabelEn: 'Essential support',
      voice: false,
      vision: false,
      multimodalLevel: 0,
      capabilities: {
        IntelliaCapability.lessons,
        IntelliaCapability.exercises,
        IntelliaCapability.quizzes,
        IntelliaCapability.flow,
        IntelliaCapability.arena,
        IntelliaCapability.kiraAndLeoText,
        IntelliaCapability.textSummariesAndExplanations,
      },
    ),
    IntelliaOffer.plus: IntelliaOfferDetails(
      offer: IntelliaOffer.plus,
      monthlyPriceXaf: 10000,
      supportLabelFr: 'Accompagnement étendu',
      supportLabelEn: 'Extended support',
      voice: true,
      vision: true,
      multimodalLevel: 1,
      capabilities: {
        IntelliaCapability.lessons,
        IntelliaCapability.exercises,
        IntelliaCapability.quizzes,
        IntelliaCapability.flow,
        IntelliaCapability.arena,
        IntelliaCapability.kiraAndLeoText,
        IntelliaCapability.textSummariesAndExplanations,
        IntelliaCapability.voice,
        IntelliaCapability.vision,
        IntelliaCapability.extendedMultimodal,
      },
    ),
    IntelliaOffer.max: IntelliaOfferDetails(
      offer: IntelliaOffer.max,
      monthlyPriceXaf: 15000,
      supportLabelFr: 'Accompagnement complet',
      supportLabelEn: 'Complete support',
      voice: true,
      vision: true,
      multimodalLevel: 2,
      capabilities: {
        IntelliaCapability.lessons,
        IntelliaCapability.exercises,
        IntelliaCapability.quizzes,
        IntelliaCapability.flow,
        IntelliaCapability.arena,
        IntelliaCapability.kiraAndLeoText,
        IntelliaCapability.textSummariesAndExplanations,
        IntelliaCapability.voice,
        IntelliaCapability.vision,
        IntelliaCapability.extendedMultimodal,
        IntelliaCapability.advancedMultimodal,
      },
    ),
  };
}

enum IntelliaEnergyLevel { available, balanced, limited }
