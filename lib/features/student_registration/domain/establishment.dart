enum EstablishmentType {
  lycee,
  college,
  technicalSchool,
  governmentHighSchool,
  privateSecondarySchool,
}

enum EstablishmentSubsystem { francophone, anglophone, bilingual, trilingual }

/// Public ou privé, tel que l'indique la source.
enum EstablishmentOwnership { public, private }

/// Enseignement général, technique, ou les deux.
enum EstablishmentTrack { general, technical, polyvalent }

/// Qualité de la source d'un établissement du catalogue de référence.
enum EstablishmentConfidence { high, medium, declared }

/// D'où vient un établissement : utile à l'administration et à la qualité
/// des données, jamais affiché à l'inscription.
class EstablishmentProvenance {
  const EstablishmentProvenance({
    required this.source,
    required this.confidence,
    this.url,
  });

  final String source;
  final EstablishmentConfidence confidence;
  final String? url;
}

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
    this.district,
    this.ownership,
    this.track,
    this.isPartner = false,
    this.referenceId,
    this.provenance,
  });

  /// Identifiant stable : celui du serveur pour un établissement partenaire,
  /// celui du catalogue de référence sinon.
  final String id;
  final String officialName;
  final String normalizedName;
  final List<String> aliases;
  final String region;
  final String city;
  final EstablishmentType type;

  /// Langue d'enseignement ; `null` tant que la source ne la confirme pas.
  final EstablishmentSubsystem? subsystem;
  final List<EstablishmentEducationType> educationTypes;
  final EstablishmentCatalogStatus status;

  /// Arrondissement ; `null` s'il n'est pas confirmé.
  final String? district;
  final EstablishmentOwnership? ownership;
  final EstablishmentTrack? track;

  /// Établissement réellement connecté à INTELLIA : seul le serveur le dit.
  /// Un établissement du catalogue ne reçoit aucune fonction
  /// d'établissement du simple fait d'être choisi.
  final bool isPartner;

  /// Identifiant dans le catalogue de référence, quand un partenaire serveur
  /// y a été reconnu.
  final String? referenceId;
  final EstablishmentProvenance? provenance;

  Establishment asPartner({required String serverId, String? name}) =>
      Establishment(
        id: serverId,
        officialName: name ?? officialName,
        normalizedName: normalizedName,
        aliases: aliases,
        region: region,
        city: city,
        type: type,
        subsystem: subsystem,
        educationTypes: educationTypes,
        status: status,
        district: district,
        ownership: ownership,
        track: track,
        isPartner: true,
        referenceId: id,
        provenance: provenance,
      );
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

/// Un établissement proposé par l'élève : une suggestion à vérifier, jamais
/// ajoutée d'office au catalogue.
class EstablishmentSuggestion {
  const EstablishmentSuggestion({
    required this.name,
    required this.city,
    required this.region,
    this.district,
  });

  final String name;
  final String city;
  final String region;
  final String? district;
}
