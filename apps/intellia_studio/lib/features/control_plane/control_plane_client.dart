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
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String region;
  final String projectId;
  final AuthSession? Function() sessionProvider;

  String get _functionsBaseUrl =>
      'https://$region-$projectId.cloudfunctions.net';

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
    final response = await _http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.idToken}',
      },
      body: jsonEncode({'data': data}),
    );

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
}
