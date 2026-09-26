enum MobileMoneyAvailability {
  available,
  notConfigured,
  schoolNotLinked,
  multipleSchools;

  static MobileMoneyAvailability fromWire(Object? value) => switch (value) {
    'available' => available,
    'school_not_linked' => schoolNotLinked,
    'multiple_schools' => multipleSchools,
    _ => notConfigured,
  };
}

enum MobileMoneyPaymentStatus {
  pending,
  approved,
  rejected;

  static MobileMoneyPaymentStatus fromWire(Object? value) => switch (value) {
    'approved' => approved,
    'rejected' => rejected,
    _ => pending,
  };
}

class MobileMoneyOperator {
  const MobileMoneyOperator({
    required this.code,
    required this.label,
    required this.recipientPhone,
    this.instructions,
  });

  final String code;
  final String label;
  final String recipientPhone;
  final String? instructions;

  factory MobileMoneyOperator.fromMap(Map<String, dynamic> map) {
    return MobileMoneyOperator(
      code: _string(map['code']),
      label: _string(map['label']),
      recipientPhone: _string(map['recipientPhone']),
      instructions: _nullableString(map['instructions']),
    );
  }
}

class MobileMoneyOffer {
  const MobileMoneyOffer({
    required this.id,
    required this.establishmentId,
    required this.title,
    required this.description,
    required this.amountXaf,
    required this.durationDays,
    required this.operators,
  });

  final String id;
  final String establishmentId;
  final String title;
  final String description;
  final int amountXaf;
  final int durationDays;
  final List<MobileMoneyOperator> operators;

  factory MobileMoneyOffer.fromMap(Map<String, dynamic> map) {
    final operators = _mapList(map['operators'])
        .map(MobileMoneyOperator.fromMap)
        .where(
          (operator) =>
              operator.code.isNotEmpty && operator.recipientPhone.isNotEmpty,
        )
        .toList(growable: false);
    return MobileMoneyOffer(
      id: _string(map['id']),
      establishmentId: _string(map['establishmentId']),
      title: _string(map['title']),
      description: _string(map['description']),
      amountXaf: _integer(map['amountXaf']),
      durationDays: _integer(map['durationDays']),
      operators: operators,
    );
  }
}

class ParentPaymentStatus {
  const ParentPaymentStatus({
    required this.requestId,
    this.establishmentId,
    this.beneficiaryStudentId,
    required this.offerTitle,
    required this.amountXaf,
    required this.operatorLabel,
    required this.status,
    required this.referenceHint,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
  });

  final String requestId;
  final String? establishmentId;
  final String? beneficiaryStudentId;
  final String offerTitle;
  final int amountXaf;
  final String operatorLabel;
  final MobileMoneyPaymentStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String referenceHint;
  final String? reviewNote;

  factory ParentPaymentStatus.fromMap(Map<String, dynamic> map) {
    return ParentPaymentStatus(
      requestId: _string(map['requestId']),
      establishmentId: _nullableString(map['establishmentId']),
      beneficiaryStudentId: _nullableString(map['beneficiaryStudentId']),
      offerTitle: _string(map['offerTitle']),
      amountXaf: _integer(map['amountXaf']),
      operatorLabel: _string(map['operatorLabel']),
      status: MobileMoneyPaymentStatus.fromWire(map['status']),
      submittedAt: _date(map['submittedAt']),
      reviewedAt: _date(map['reviewedAt']),
      referenceHint: _string(map['referenceHint']),
      reviewNote: _nullableString(map['reviewNote']),
    );
  }
}

/// Un enfant lié et l'école qui détermine son offre.
class MobileMoneyChild {
  const MobileMoneyChild({
    required this.studentId,
    required this.firstName,
    required this.establishmentId,
  });

  final String studentId;
  final String firstName;
  final String establishmentId;

  factory MobileMoneyChild.fromMap(Map<String, dynamic> map) =>
      MobileMoneyChild(
        studentId: _string(map['studentId']),
        firstName: _string(map['firstName']),
        establishmentId: _string(map['establishmentId']),
      );
}

class MobileMoneyOverview {
  const MobileMoneyOverview({
    required this.availability,
    required this.recentRequests,
    this.offer,
    this.children = const [],
    this.beneficiary,
    this.coveredStudentIds = const [],
    this.supportsBeneficiary = false,
  });

  final MobileMoneyAvailability availability;
  final MobileMoneyOffer? offer;
  final List<ParentPaymentStatus> recentRequests;

  /// Enfants liés, chacun avec son école.
  final List<MobileMoneyChild> children;

  /// Enfant pour qui l'offre est présentée, s'il a été choisi.
  final MobileMoneyChild? beneficiary;

  /// Enfants de ce parent qu'un paiement pour cette école couvre.
  final List<String> coveredStudentIds;

  /// Le serveur accepte un bénéficiaire explicite. Une version antérieure
  /// refuserait ce champ : il n'est alors jamais envoyé.
  final bool supportsBeneficiary;

  factory MobileMoneyOverview.fromMap(Map<String, dynamic> map) {
    final offerMap = _nullableMap(map['offer']);
    final beneficiaryMap = _nullableMap(map['beneficiary']);
    return MobileMoneyOverview(
      availability: MobileMoneyAvailability.fromWire(map['availability']),
      offer: offerMap == null ? null : MobileMoneyOffer.fromMap(offerMap),
      recentRequests: _mapList(
        map['recentRequests'],
      ).map(ParentPaymentStatus.fromMap).toList(growable: false),
      children: _mapList(
        map['children'],
      ).map(MobileMoneyChild.fromMap).toList(growable: false),
      beneficiary: beneficiaryMap == null
          ? null
          : MobileMoneyChild.fromMap(beneficiaryMap),
      coveredStudentIds: [
        for (final id in (map['coveredStudentIds'] as List?) ?? const [])
          if (id is String && id.isNotEmpty) id,
      ],
      supportsBeneficiary: map.containsKey('children'),
    );
  }
}

class AdminPaymentRequest {
  const AdminPaymentRequest({
    required this.requestId,
    required this.parentName,
    required this.offerTitle,
    required this.amountXaf,
    required this.operatorLabel,
    required this.payerPhone,
    required this.transactionReference,
    required this.status,
    this.submittedAt,
  });

  final String requestId;
  final String parentName;
  final String offerTitle;
  final int amountXaf;
  final String operatorLabel;
  final String payerPhone;
  final String transactionReference;
  final MobileMoneyPaymentStatus status;
  final DateTime? submittedAt;

  factory AdminPaymentRequest.fromMap(Map<String, dynamic> map) {
    return AdminPaymentRequest(
      requestId: _string(map['requestId']),
      parentName: _string(map['parentName']),
      offerTitle: _string(map['offerTitle']),
      amountXaf: _integer(map['amountXaf']),
      operatorLabel: _string(map['operatorLabel']),
      payerPhone: _string(map['payerPhone']),
      transactionReference: _string(map['transactionReference']),
      status: MobileMoneyPaymentStatus.fromWire(map['status']),
      submittedAt: _date(map['submittedAt']),
    );
  }
}

String formatXaf(int amount) {
  final digits = amount.abs().toString();
  final chunks = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, digits.length);
    chunks.add(digits.substring(start, end));
  }
  final formatted = chunks.reversed.join(' ');
  return '${amount < 0 ? '-' : ''}$formatted FCFA';
}

Map<String, dynamic>? _nullableMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value.map(_nullableMap).whereType<Map<String, dynamic>>().toList();
}

String _string(Object? value) => value is String ? value.trim() : '';

String? _nullableString(Object? value) {
  final string = _string(value);
  return string.isEmpty ? null : string;
}

int _integer(Object? value) => value is num ? value.round() : 0;

DateTime? _date(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
