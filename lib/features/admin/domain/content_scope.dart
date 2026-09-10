/// Type of content tenancy scope.
enum ContentScopeType {
  /// National curriculum content accessible to all students in the class level.
  global,

  /// Institution/establishment-specific content accessible only to students
  /// and staff of the designated establishment.
  establishment;

  static ContentScopeType fromString(String? value) {
    return ContentScopeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContentScopeType.global,
    );
  }
}

/// Tenancy scope for educational content and assets.
class ContentScope {
  const ContentScope({
    this.type = ContentScopeType.global,
    this.establishmentId,
  }) : assert(
         type != ContentScopeType.establishment ||
             (establishmentId != null && establishmentId.length > 0),
         'establishmentId is required when type is establishment',
       );

  final ContentScopeType type;
  final String? establishmentId;

  /// Default global national curriculum scope.
  static const ContentScope global = ContentScope(
    type: ContentScopeType.global,
  );

  bool get isGlobal => type == ContentScopeType.global;
  bool get isEstablishment => type == ContentScopeType.establishment;

  /// Identifier used in storage paths and firestore tenancy queries:
  /// 'global' for national curriculum, or the specific [establishmentId].
  String get scopeId =>
      isEstablishment ? (establishmentId ?? 'unknown') : 'global';

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'type': type.name,
    if (establishmentId != null) 'establishmentId': establishmentId,
  };

  factory ContentScope.fromFirestore(dynamic data) {
    if (data == null || data is! Map) return ContentScope.global;
    final map = Map<String, dynamic>.from(data);
    final type = ContentScopeType.fromString(map['type'] as String?);
    return ContentScope(
      type: type,
      establishmentId: map['establishmentId'] as String?,
    );
  }

  ContentScope copyWith({ContentScopeType? type, String? establishmentId}) {
    return ContentScope(
      type: type ?? this.type,
      establishmentId: establishmentId ?? this.establishmentId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentScope &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          establishmentId == other.establishmentId;

  @override
  int get hashCode => Object.hash(type, establishmentId);

  @override
  String toString() =>
      'ContentScope(type: ${type.name}, establishmentId: $establishmentId)';
}
