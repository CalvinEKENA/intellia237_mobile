class SchoolEstablishment {
  const SchoolEstablishment({required this.id, required this.name, this.city});

  final String id;
  final String name;
  final String? city;

  String get displayName {
    if (city == null || city!.trim().isEmpty) {
      return name;
    }
    return '$name - ${city!.trim()}';
  }

  factory SchoolEstablishment.fromMap(String id, Map<String, dynamic> json) {
    final primaryName = (json['name'] as String?)?.trim();
    final displayName = (json['displayName'] as String?)?.trim();
    final schoolName = (json['schoolName'] as String?)?.trim();
    final city =
        (json['city'] as String?)?.trim() ??
        (json['location'] as String?)?.trim();

    return SchoolEstablishment(
      id: id,
      name: primaryName?.isNotEmpty == true
          ? primaryName!
          : (displayName?.isNotEmpty == true ? displayName! : schoolName ?? ''),
      city: city,
    );
  }
}
