import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intellia_studio/features/auth/domain/auth_session.dart';
import 'package:intellia_studio/features/control_plane/control_plane_client.dart';

void main() {
  test('a server refusal keeps its status and authorized message', () {
    final error = parseCallableError(
      403,
      jsonEncode({
        'error': {
          'status': 'PERMISSION_DENIED',
          'message': 'Cross-establishment payment review is forbidden.',
          'details': {'reason': 'scope'},
        },
      }),
    );
    expect(error.code, 'PERMISSION_DENIED');
    expect(error.message, 'Cross-establishment payment review is forbidden.');
    expect(error.details, {'reason': 'scope'});
  });

  test('an unreadable body falls back to the HTTP status', () {
    final error = parseCallableError(502, '<html>Bad gateway</html>');
    expect(error.code, 'http-502');
    expect(error.message, 'Erreur HTTP 502');
  });

  test(
    'the client surfaces the server message instead of a generic one',
    () async {
      final client = ControlPlaneClient(
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'error': {
                'status': 'FAILED_PRECONDITION',
                'message':
                    'A reviewed payment request cannot receive a different decision.',
              },
            }),
            400,
          ),
        ),
        sessionProvider: () => AuthSession(
          uid: 'super-1',
          email: 'root@example.com',
          displayName: 'Root',
          role: 'superAdmin',
          idToken: 'token',
          refreshToken: 'refresh',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      await expectLater(
        client.call<Object?>(functionName: 'reviewMobileMoneyPayment'),
        throwsA(
          isA<ControlPlaneException>()
              .having((error) => error.code, 'code', 'FAILED_PRECONDITION')
              .having(
                (error) => error.message,
                'message',
                contains('cannot receive a different decision'),
              ),
        ),
      );
    },
  );
}
