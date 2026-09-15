import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/domain/auth_session.dart';

class ControlPlaneException implements Exception {
  const ControlPlaneException(this.code, this.message, [this.details]);
  final String code;
  final String message;
  final dynamic details;

  @override
  String toString() => 'ControlPlaneException: [$code] $message';
}

class ControlPlaneClient {
  ControlPlaneClient({
    http.Client? httpClient,
    this.region = 'europe-west1',
    this.projectId = 'edunova-aabd1',
    required this.sessionProvider,
    this.tokenRefresher,
    this.onSessionExpired,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String region;
  final String projectId;
  final AuthSession? Function() sessionProvider;
  final Future<AuthSession?> Function()? tokenRefresher;
  final Future<void> Function()? onSessionExpired;

  Future<AuthSession?>? _inFlightRefresh;

  String get _functionsBaseUrl =>
      'https://$region-$projectId.cloudfunctions.net';

  Future<AuthSession?> _performSingleRefresh() {
    if (_inFlightRefresh != null) return _inFlightRefresh!;
    if (tokenRefresher == null) return Future.value(null);

    _inFlightRefresh = tokenRefresher!().whenComplete(() {
      _inFlightRefresh = null;
    });
    return _inFlightRefresh!;
  }

  Future<T> call<T>({
    required String functionName,
    Map<String, dynamic> data = const {},
    T Function(dynamic rawResult)? parser,
  }) async {
    final session = sessionProvider();
    if (session == null) {
      throw const ControlPlaneException(
        'unauthenticated',
        'Session d\'administration requise.',
      );
    }

    final uri = Uri.parse('$_functionsBaseUrl/$functionName');
    final payload = jsonEncode({'data': data});

    var response = await _http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.idToken}',
      },
      body: payload,
    );

    if (response.statusCode == 401 || (response.statusCode == 403 && response.body.contains('UNAUTHENTICATED'))) {
      if (tokenRefresher != null) {
        final refreshed = await _performSingleRefresh();
        if (refreshed != null) {
          response = await _http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${refreshed.idToken}',
            },
            body: payload,
          );
        } else if (onSessionExpired != null) {
          await onSessionExpired!();
        }
      } else if (onSessionExpired != null) {
        await onSessionExpired!();
      }
    }

    if (response.statusCode >= 400) {
      _handleHttpError(response);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body.containsKey('error')) {
      final err = body['error'] as Map<String, dynamic>;
      throw ControlPlaneException(
        err['status'] as String? ?? 'internal',
        err['message'] as String? ?? 'Erreur du serveur de contrôle.',
        err['details'],
      );
    }

    final result = body['result'];
    if (parser != null) {
      return parser(result);
    }
    return result as T;
  }

  void _handleHttpError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body.containsKey('error')) {
        final err = body['error'] as Map<String, dynamic>;
        throw ControlPlaneException(
          err['status'] as String? ?? 'http-${response.statusCode}',
          err['message'] as String? ?? 'Erreur HTTP ${response.statusCode}',
        );
      }
    } catch (_) {}
    throw ControlPlaneException(
      'http-${response.statusCode}',
      'Erreur HTTP ${response.statusCode}',
    );
  }

  // -------------------------------------------------------------
  // Canonical Backend Callables
  // -------------------------------------------------------------

  /// manageAccount (suspend, reactivate, delete, restore)
  Future<Map<String, dynamic>> manageAccountAction({
    required String action,
    required String accountId,
    required String reason,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'manageAccount',
      data: {
        'action': action,
        'accountId': accountId,
        'reason': reason,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// Alias for manageAccountAction
  Future<Map<String, dynamic>> manageAccount({
    required String action,
    required String accountId,
    required String reason,
  }) => manageAccountAction(action: action, accountId: accountId, reason: reason);

  /// manageAccount (createStudent)
  Future<Map<String, dynamic>> createStudent({
    required String requestId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? email,
    required String establishmentId,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'manageAccount',
      data: {
        'action': 'createStudent',
        'requestId': requestId,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        'establishmentId': establishmentId,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// reviewStaffAccount
  Future<Map<String, dynamic>> reviewStaffAccount({
    required String reviewId,
    required bool approved,
    String? establishmentId,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'reviewStaffAccount',
      data: {
        'reviewId': reviewId,
        'approved': approved,
        if (establishmentId != null) 'establishmentId': establishmentId,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// changeAccountEstablishment
  Future<Map<String, dynamic>> changeAccountEstablishment({
    required String accountId,
    required String establishmentId,
    String? reason,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'changeAccountEstablishment',
      data: {
        'accountId': accountId,
        'establishmentId': establishmentId,
        if (reason != null) 'reason': reason,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// saveLessonPublication (draft or publish)
  Future<Map<String, dynamic>> saveLessonPublication({
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required bool publish,
    Map<String, dynamic>? content,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'saveLessonPublication',
      data: {
        'classLevel': classLevel,
        'subjectId': subjectId,
        'chapterId': chapterId,
        'lessonId': lessonId,
        'publish': publish,
        if (content != null) 'content': content,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// createCatalogChapter
  Future<Map<String, dynamic>> createCatalogChapter({
    required String classLevel,
    required String subjectId,
    required String title,
    required String description,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'createCatalogChapter',
      data: {
        'classLevel': classLevel,
        'subjectId': subjectId,
        'title': title,
        'description': description,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// deleteCatalogContent
  Future<Map<String, dynamic>> deleteCatalogContent({
    required String classLevel,
    required String subjectId,
    String? chapterId,
    String? lessonId,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'deleteCatalogContent',
      data: {
        'classLevel': classLevel,
        'subjectId': subjectId,
        if (chapterId != null) 'chapterId': chapterId,
        if (lessonId != null) 'lessonId': lessonId,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// listEditorialFlow
  Future<List<Map<String, dynamic>>> listEditorialFlow({
    required String classLevel,
  }) async {
    return call<List<Map<String, dynamic>>>(
      functionName: 'listEditorialFlow',
      data: {'classLevel': classLevel},
      parser: (res) {
        final map = res as Map<String, dynamic>? ?? {};
        final list = map['items'] as List<dynamic>? ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      },
    );
  }

  /// saveFlowPublication
  Future<Map<String, dynamic>> saveFlowPublication({
    required Map<String, dynamic> item,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'saveFlowPublication',
      data: item,
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// educationalMedia delete
  Future<Map<String, dynamic>> deleteEducationalMedia({
    required String storagePath,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'educationalMedia',
      data: {
        'storagePath': storagePath,
        'action': 'delete',
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// listMobileMoneyPayments
  Future<List<Map<String, dynamic>>> listMobileMoneyPayments({
    String status = 'pending',
  }) async {
    return call<List<Map<String, dynamic>>>(
      functionName: 'listMobileMoneyPayments',
      data: {'status': status},
      parser: (res) {
        if (res is List) {
          return res.map((e) => e as Map<String, dynamic>).toList();
        }
        return [];
      },
    );
  }

  /// reviewMobileMoneyPayment
  Future<Map<String, dynamic>> reviewMobileMoneyPayment({
    required String requestId,
    required String decision,
    String? reviewNote,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'reviewMobileMoneyPayment',
      data: {
        'requestId': requestId,
        'decision': decision,
        if (reviewNote != null && reviewNote.isNotEmpty) 'reviewNote': reviewNote,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// getStudyReserve
  Future<Map<String, dynamic>> getStudyReserve({
    required String studentId,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'getStudyReserve',
      data: {'studentId': studentId},
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// ensureStudentLinkCode
  Future<Map<String, dynamic>> ensureStudentLinkCode({
    required String studentId,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'ensureStudentLinkCode',
      data: {'studentId': studentId},
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// rotateStudentLinkCode
  Future<Map<String, dynamic>> rotateStudentLinkCode({
    required String studentId,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'rotateStudentLinkCode',
      data: {'studentId': studentId},
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// importCoursePages
  Future<Map<String, dynamic>> importCoursePages({
    required List<Map<String, dynamic>> pages,
    required String classLevel,
    required String subjectId,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'importCoursePages',
      data: {
        'pages': pages,
        'classLevel': classLevel,
        'subjectId': subjectId,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// manageEstablishment
  Future<Map<String, dynamic>> manageEstablishment({
    required String action,
    String? id,
    String? establishmentId,
    String? name,
    String? code,
    String? city,
    String? region,
    String? address,
    String? status,
    String? reason,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'manageEstablishment',
      data: {
        'action': action,
        if (id != null) 'id': id,
        if (establishmentId != null) 'establishmentId': establishmentId,
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (city != null) 'city': city,
        if (region != null) 'region': region,
        if (address != null) 'address': address,
        if (status != null) 'status': status,
        if (reason != null) 'reason': reason,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }

  /// manageSchoolClass
  Future<Map<String, dynamic>> manageSchoolClass({
    required String action,
    String? name,
    String? classLevel,
    String? series,
    String? establishmentId,
    String? classId,
    String? reason,
  }) async {
    return call<Map<String, dynamic>>(
      functionName: 'manageSchoolClass',
      data: {
        'action': action,
        if (name != null) 'name': name,
        if (classLevel != null) 'classLevel': classLevel,
        if (series != null) 'series': series,
        if (establishmentId != null) 'establishmentId': establishmentId,
        if (classId != null) 'classId': classId,
        if (reason != null) 'reason': reason,
      },
      parser: (res) => (res as Map<String, dynamic>? ?? {}),
    );
  }
}

