enum AccessTier { all, freeOnly, premiumOnly }

class StudioAudienceRule {
  final String id;
  final String name;
  final List<String> classLevels;
  final List<String> series;
  final String scopeType; // 'global' | 'establishment'
  final String? establishmentId;
  final AccessTier accessTier;
  final int estimatedStudentReach;

  const StudioAudienceRule({
    required this.id,
    required this.name,
    required this.classLevels,
    this.series = const [],
    this.scopeType = 'global',
    this.establishmentId,
    this.accessTier = AccessTier.all,
    this.estimatedStudentReach = 0,
  });

  bool matches({
    required String studentClassLevel,
    String? studentSeries,
    String? studentEstablishmentId,
    required bool isPremium,
  }) {
    if (classLevels.isNotEmpty && !classLevels.contains(studentClassLevel)) {
      return false;
    }
    if (series.isNotEmpty &&
        studentSeries != null &&
        !series.contains(studentSeries)) {
      return false;
    }
    if (scopeType == 'establishment' &&
        establishmentId != null &&
        establishmentId != studentEstablishmentId) {
      return false;
    }
    if (accessTier == AccessTier.premiumOnly && !isPremium) {
      return false;
    }
    if (accessTier == AccessTier.freeOnly && isPremium) {
      return false;
    }
    return true;
  }
}
