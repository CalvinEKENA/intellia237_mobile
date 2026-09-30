import '../audit/domain/audit_entry.dart';
import 'api_contracts.dart';

class FakeControlPlaneApi implements ControlPlaneApi {
  final List<AuditEntry> _auditLogs = [
    AuditEntry(
      id: 'audit_01',
      actorId: 'admin_test_01',
      targetId: 'std_test_02',
      action: 'suspend',
      previousStatus: 'active',
      status: 'suspended',
      reason: 'Audit trimestriel de conformité',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Future<Map<String, dynamic>> manageAccount({
    required String action,
    required String accountId,
    required String reason,
  }) async {
    final entry = AuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      actorId: 'current_admin',
      targetId: accountId,
      action: action,
      previousStatus: 'active',
      status: action == 'delete'
          ? 'deleted'
          : (action == 'suspend' ? 'suspended' : 'active'),
      reason: reason,
      createdAt: DateTime.now(),
    );
    _auditLogs.insert(0, entry);
    return {'accountId': accountId, 'status': entry.status};
  }

  @override
  Future<Map<String, dynamic>> reviewStaffAccount({
    required String reviewId,
    required bool approved,
    String? establishmentId,
  }) async {
    return {
      'reviewId': reviewId,
      'status': approved ? 'approved' : 'rejected',
      'establishmentId': establishmentId ?? 'est_01',
    };
  }

  @override
  Future<Map<String, dynamic>> changeAccountEstablishment({
    required String accountId,
    required String establishmentId,
    required String reason,
  }) async {
    return {'accountId': accountId, 'establishmentId': establishmentId};
  }

  @override
  Future<Map<String, dynamic>> saveFlowPublication({
    String? id,
    required Map<String, dynamic> content,
  }) async {
    return {'id': id ?? 'flow_generated_id'};
  }

  @override
  Future<Map<String, dynamic>> saveLessonPublication({
    required String lessonId,
    required Map<String, dynamic> lesson,
  }) async {
    return {'lessonId': lessonId, 'status': 'published'};
  }

  @override
  Future<List<Map<String, dynamic>>> listMobileMoneyPayments({
    String status = 'pending',
  }) async {
    return [
      {
        'requestId': 'req_pay_01',
        'parentId': 'parent_01',
        'parentName': 'Jean Mballa',
        'establishmentId': 'est_douala_01',
        'offerTitle': 'Abonnement Annuel Intellia',
        'amountXaf': 15000,
        'currency': 'XAF',
        'operatorCode': 'orange_money',
        'operatorLabel': 'Orange Money',
        'payerPhone': '+237699112233',
        'transactionReference': 'OM237-9948271',
        'status': status,
        'submittedAt': DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> reviewMobileMoneyPayment({
    required String requestId,
    required String decision,
    String? reviewNote,
  }) async {
    return {
      'requestId': requestId,
      'status': decision,
      'entitlementId': decision == 'approved'
          ? 'parent_01_est_douala_01'
          : null,
      'idempotentReplay': false,
    };
  }

  @override
  Future<Map<String, dynamic>> getStudyReserve({
    required String studentId,
  }) async {
    return {
      'status': 'active',
      'percentageRemaining': 72.5,
      'cycleStart': DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
      'cycleEnd': DateTime.now()
          .add(const Duration(days: 20))
          .toIso8601String(),
      'offerId': 'est_douala_01',
    };
  }

  @override
  Future<String> ensureStudentLinkCode({required String studentId}) async {
    return 'LNK73829';
  }

  @override
  Future<String> rotateStudentLinkCode({required String studentId}) async {
    return 'ROT99214';
  }

  @override
  Future<List<AuditEntry>> fetchAuditLogs({int limit = 50}) async {
    return List.unmodifiable(_auditLogs);
  }
}
