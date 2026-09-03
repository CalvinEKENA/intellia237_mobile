enum EstablishmentType {
  lycee,
  college,
  technicalSchool,
  governmentHighSchool,
  privateSecondarySchool,
}

enum EstablishmentSubsystem { francophone, anglophone, bilingual }

enum EstablishmentEducationType { general, technical }

enum EstablishmentCatalogStatus { active, inactive }

class Establishment {
  const Establishment({
    required this.id,
    required this.officialName,
    required this.normalizedName,
    required this.aliases,
    required this.region,
    required this.city,
    required this.type,
    required this.subsystem,
    required this.educationTypes,
    required this.status,
  });

  final String id;
  final String officialName;
  final String normalizedName;
  final List<String> aliases;
  final String region;
  final String city;
  final EstablishmentType type;
  final EstablishmentSubsystem subsystem;
  final List<EstablishmentEducationType> educationTypes;
  final EstablishmentCatalogStatus status;
}

class EstablishmentSearchResult {
  const EstablishmentSearchResult({
    required this.establishment,
    required this.score,
    required this.highlightStart,
    required this.highlightEnd,
    required this.isDominant,
  });

  final Establishment establishment;
  final int score;
  final int highlightStart;
  final int highlightEnd;
  final bool isDominant;
}

class EstablishmentSuggestion {
  const EstablishmentSuggestion({
    required this.name,
    required this.city,
    required this.region,
  });

  final String name;
  final String city;
  final String region;
}
