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

  String get formattedPrice => '${priceXaf.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
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

  String get formattedAmount => '${amountXaf.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
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

  double get consumptionRatio =>
      allowanceInternal > 0 ? (consumedInternal / allowanceInternal).clamp(0.0, 1.0) : 0.0;

  int get consumptionPercent => (consumptionRatio * 100).round();

  bool get isCritical => consumptionRatio >= 0.8;
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
