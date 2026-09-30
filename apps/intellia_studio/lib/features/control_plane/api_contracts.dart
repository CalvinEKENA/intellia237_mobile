import '../audit/domain/audit_entry.dart';

abstract class ControlPlaneApi {
  // Admin & Accounts
  Future<Map<String, dynamic>> manageAccount({
    required String action, // 'suspend' | 'reactivate' | 'delete' | 'restore'
    required String accountId,
    required String reason,
  });

  Future<Map<String, dynamic>> reviewStaffAccount({
    required String reviewId,
    required bool approved,
    String? establishmentId,
  });

  Future<Map<String, dynamic>> changeAccountEstablishment({
    required String accountId,
    required String establishmentId,
    required String reason,
  });

  // FLOW & Content
  Future<Map<String, dynamic>> saveFlowPublication({
    String? id,
    required Map<String, dynamic> content,
  });

  Future<Map<String, dynamic>> saveLessonPublication({
    required String lessonId,
    required Map<String, dynamic> lesson,
  });

  // Mobile Money & Finance
  Future<List<Map<String, dynamic>>> listMobileMoneyPayments({
    String status = 'pending',
  });

  Future<Map<String, dynamic>> reviewMobileMoneyPayment({
    required String requestId,
    required String decision, // 'approved' | 'rejected'
    String? reviewNote,
  });

  // Study Reserve
  Future<Map<String, dynamic>> getStudyReserve({required String studentId});

  // Child Linking
  Future<String> ensureStudentLinkCode({required String studentId});
  Future<String> rotateStudentLinkCode({required String studentId});

  // Audit
  Future<List<AuditEntry>> fetchAuditLogs({int limit = 50});
}
