import '../../../core/api/firestore_rest_client.dart';

enum PaymentOperator { orangeMoney, mtnMomo }

enum PaymentRequestStatus { pending, approved, rejected }

enum EntitlementStatus { active, expired, suspended }

enum DataCollectionClassification {
  observedInProduction,
  declaredExpectedByCode,
  legacyRequiresClassification,
  notYetProvisioned,
  unknown,
}

class StudioSubscriptionPlan {
  final String id;
  final String name;
  final int priceXaf;
  final String billingPeriod;
  final List<String> features;
  final bool isProvisionedInFirestore;
  final String establishmentId;

  const StudioSubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceXaf,
    required this.billingPeriod,
    required this.features,
    this.isProvisionedInFirestore = false,
    required this.establishmentId,
  });

  String get formattedPrice =>
      '${priceXaf.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
}

class StudioEntitlement {
  final String id;
  final String parentId;
  final String establishmentId;
  final String offerId;
  final EntitlementStatus status;
  final String startsAt;
  final String endsAt;

  const StudioEntitlement({
    required this.id,
    required this.parentId,
    required this.establishmentId,
    required this.offerId,
    required this.status,
    required this.startsAt,
    required this.endsAt,
  });

  bool get isActive => status == EntitlementStatus.active;
}

class StudioPaymentRequest {
  final String id;
  final String parentId;
  final String parentName;
  final String establishmentId;
  final int amountXaf;
  final PaymentOperator operator;
  final String reference;
  final String phoneNumber;
  final PaymentRequestStatus status;
  final String createdAt;
  final String? reviewedAt;
  final String? reviewedByUid;
  final String? rejectionReason;

  const StudioPaymentRequest({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.establishmentId,
    required this.amountXaf,
    required this.operator,
    required this.reference,
    required this.phoneNumber,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedByUid,
    this.rejectionReason,
  });

  factory StudioPaymentRequest.fromMap(String id, Map<String, dynamic> map) {
    final opStr = (map['operator'] as String? ?? 'orange').toLowerCase();
    final stStr = (map['status'] as String? ?? 'pending').toLowerCase();

    return StudioPaymentRequest(
      id: id,
      parentId: map['parentId'] as String? ?? map['userId'] as String? ?? '',
      parentName: map['parentName'] as String? ?? map['userName'] as String? ?? 'Parent',
      establishmentId: map['establishmentId'] as String? ?? '',
      amountXaf: (map['amountXaf'] as num?)?.toInt() ?? (map['amount'] as num?)?.toInt() ?? 0,
      operator: opStr.contains('mtn') ? PaymentOperator.mtnMomo : PaymentOperator.orangeMoney,
      reference: map['reference'] as String? ?? map['transactionId'] as String? ?? id,
      phoneNumber: map['phoneNumber'] as String? ?? map['phone'] as String? ?? '',
      status: stStr == 'approved'
          ? PaymentRequestStatus.approved
          : (stStr == 'rejected' ? PaymentRequestStatus.rejected : PaymentRequestStatus.pending),
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      reviewedAt: map['reviewedAt'] as String?,
      reviewedByUid: map['reviewedByUid'] as String?,
      rejectionReason: map['rejectionReason'] as String? ?? map['reviewNote'] as String?,
    );
  }

  factory StudioPaymentRequest.fromFirestore(FirestoreDocument doc) {
    return StudioPaymentRequest.fromMap(doc.id, doc.fields);
  }

  String get formattedAmount =>
      '${amountXaf.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
}

class StudioStudyReserve {
  final String studentId;
  final String studentName;
  final String classLevel;
  final int allowanceInternal;
  final int consumedInternal;
  final String cycleStart;
  final String cycleEnd;
  final String? latestThresholdEmitted;

  const StudioStudyReserve({
    required this.studentId,
    required this.studentName,
    required this.classLevel,
    required this.allowanceInternal,
    required this.consumedInternal,
    required this.cycleStart,
    required this.cycleEnd,
    this.latestThresholdEmitted,
  });

  factory StudioStudyReserve.fromMap(Map<String, dynamic> map) {
    return StudioStudyReserve(
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Élève',
      classLevel: map['classLevel'] as String? ?? '',
      allowanceInternal: (map['allowanceInternal'] as num?)?.toInt() ?? 100,
      consumedInternal: (map['consumedInternal'] as num?)?.toInt() ?? 0,
      cycleStart: map['cycleStart'] as String? ?? '',
      cycleEnd: map['cycleEnd'] as String? ?? '',
      latestThresholdEmitted: map['latestThresholdEmitted'] as String?,
    );
  }

  double get consumptionRatio =>
      allowanceInternal > 0 ? (consumedInternal / allowanceInternal).clamp(0.0, 1.0) : 0.0;

  int get consumptionPercent => (consumptionRatio * 100).round();

  /// Canonical remaining percentage
  int get remainingPercent {
    if (allowanceInternal <= 0) return 0;
    final rem = allowanceInternal - consumedInternal;
    return ((rem / allowanceInternal) * 100).round().clamp(0, 100);
  }

  /// Canonical server status according to RESERVE_THRESHOLDS = [75, 50, 25, 5, 0]
  String get canonicalStatus {
    final rem = remainingPercent;
    if (allowanceInternal <= 0) return 'unavailable';
    if (rem > 75) return 'healthy';
    if (rem > 50) return 'warning';
    if (rem > 25) return 'low';
    if (rem > 0) return 'critical';
    return 'depleted';
  }

  bool get isCritical => allowanceInternal > 0 && remainingPercent <= 25;
}

class StudioStudyReservePlan {
  final String offerId;
  final String establishmentId;
  final int allowanceInternal;
  final int cycleDays;
  final String updatedAt;

  const StudioStudyReservePlan({
    required this.offerId,
    required this.establishmentId,
    required this.allowanceInternal,
    required this.cycleDays,
    required this.updatedAt,
  });
}

class LegacyFinancialRecord {
  final String id;
  final String collectionName;
  final String userId;
  final Map<String, dynamic> rawData;
  final DataCollectionClassification classification;
  final String timestamp;

  const LegacyFinancialRecord({
    required this.id,
    required this.collectionName,
    required this.userId,
    required this.rawData,
    required this.classification,
    required this.timestamp,
  });
}
