import '../../core/api/firestore_rest_client.dart';
import '../audit/domain/audit_entry.dart';
import 'api_contracts.dart';
import 'control_plane_client.dart';

class RealControlPlaneApi implements ControlPlaneApi {
  RealControlPlaneApi({
    required this.controlPlaneClient,
    required this.firestoreClient,
  });

  final ControlPlaneClient controlPlaneClient;
  final FirestoreRestClient firestoreClient;

  @override
  Future<Map<String, dynamic>> manageAccount({
    required String action,
    required String accountId,
    required String reason,
  }) async {
    return controlPlaneClient.manageAccountAction(
      action: action,
      accountId: accountId,
      reason: reason,
    );
  }

  @override
  Future<Map<String, dynamic>> reviewStaffAccount({
    required String reviewId,
    required bool approved,
    String? establishmentId,
  }) async {
    return controlPlaneClient.reviewStaffAccount(
      reviewId: reviewId,
      approved: approved,
      establishmentId: establishmentId,
    );
  }

  @override
  Future<Map<String, dynamic>> changeAccountEstablishment({
    required String accountId,
    required String establishmentId,
    required String reason,
  }) async {
    return controlPlaneClient.changeAccountEstablishment(
      accountId: accountId,
      establishmentId: establishmentId,
      reason: reason,
    );
  }

  @override
  Future<Map<String, dynamic>> saveFlowPublication({
    String? id,
    required Map<String, dynamic> content,
  }) async {
    return controlPlaneClient.saveFlowPublication(item: content);
  }

  @override
  Future<Map<String, dynamic>> saveLessonPublication({
    required String lessonId,
    required Map<String, dynamic> lesson,
  }) async {
    final classLevel = lesson['classLevel'] as String? ?? 'terminale';
    final subjectId = lesson['subjectId'] as String? ?? 'general';
    final chapterId = lesson['chapterId'] as String? ?? 'general';
    final publish =
        lesson['status'] == 'published' ||
        (lesson['publish'] as bool? ?? false);

    return controlPlaneClient.saveLessonPublication(
      classLevel: classLevel,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
      publish: publish,
      content: lesson,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listMobileMoneyPayments({
    String status = 'pending',
  }) async {
    return controlPlaneClient.listMobileMoneyPayments(status: status);
  }

  @override
  Future<Map<String, dynamic>> reviewMobileMoneyPayment({
    required String requestId,
    required String decision,
    String? reviewNote,
  }) async {
    return controlPlaneClient.reviewMobileMoneyPayment(
      requestId: requestId,
      decision: decision,
      reviewNote: reviewNote,
    );
  }

  @override
  Future<Map<String, dynamic>> getStudyReserve({
    required String studentId,
  }) async {
    return controlPlaneClient.getStudyReserve(studentId: studentId);
  }

  @override
  Future<String> ensureStudentLinkCode({required String studentId}) async {
    final res = await controlPlaneClient.ensureStudentLinkCode(
      studentId: studentId,
    );
    return res['linkCode'] as String? ?? res['code'] as String? ?? '';
  }

  @override
  Future<String> rotateStudentLinkCode({required String studentId}) async {
    final res = await controlPlaneClient.rotateStudentLinkCode(
      studentId: studentId,
    );
    return res['linkCode'] as String? ?? res['code'] as String? ?? '';
  }

  @override
  Future<List<AuditEntry>> fetchAuditLogs({int limit = 50}) async {
    try {
      final docs = await firestoreClient.listDocuments(
        'account_management_audit',
        pageSize: limit,
      );

      return docs.map((d) {
        return AuditEntry(
          id: d.id,
          actorId: d['actorId'] as String? ?? 'unknown',
          targetId: d['targetId'] as String? ?? 'unknown',
          action: d['action'] as String? ?? 'unknown',
          previousStatus: d['previousStatus'] as String? ?? '',
          status: d['status'] as String? ?? '',
          reason: d['reason'] as String? ?? 'Action de gestion',
          createdAt:
              d.createTime ??
              (d['createdAt'] is String
                  ? DateTime.tryParse(d['createdAt'] as String) ??
                        DateTime.now()
                  : DateTime.now()),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
