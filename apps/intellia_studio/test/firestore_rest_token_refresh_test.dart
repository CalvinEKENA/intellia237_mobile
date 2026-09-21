import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intellia_studio/core/api/firestore_rest_client.dart';
import 'package:intellia_studio/features/auth/domain/auth_session.dart';

class MockHttpClient extends http.BaseClient {
  MockHttpClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

AuthSession _createSession({
  String idToken = 'initial_token_123',
  String refreshToken = 'refresh_token_abc',
}) {
  return AuthSession(
    uid: 'user_test_01',
    email: 'admin@minesec.cm',
    displayName: 'Admin Test',
    role: 'superAdmin',
    idToken: idToken,
    refreshToken: refreshToken,
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
}

void main() {
  group('FirestoreRestClient Token Refresh and Resilience', () {
    test('Normal authenticated request passes without triggering refresh', () async {
      var currentSession = _createSession();
      int refreshCalls = 0;
      int expiredCalls = 0;

      final client = FirestoreRestClient(
        httpClient: MockHttpClient((req) async {
          expect(req.headers['authorization'], 'Bearer initial_token_123');
          return http.Response(
            jsonEncode({'documents': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        sessionProvider: () => currentSession,
        tokenRefresher: () async {
          refreshCalls++;
          return currentSession;
        },
        onSessionExpired: () async {
          expiredCalls++;
        },
      );

      final docs = await client.listDocuments('establishments');
      expect(docs, isEmpty);
      expect(refreshCalls, 0, reason: 'No refresh call should be made on 200 OK');
      expect(expiredCalls, 0);
    });

    test('401 response triggers single refresh call and retries original request successfully', () async {
      var currentSession = _createSession(idToken: 'expired_token');
      int refreshCalls = 0;
      int expiredCalls = 0;
      int requestCount = 0;

      final client = FirestoreRestClient(
        httpClient: MockHttpClient((req) async {
          requestCount++;
          if (req.headers['authorization'] == 'Bearer expired_token') {
            return http.Response(
              jsonEncode({'error': {'code': 401, 'message': 'Request had invalid authentication credentials.'}}),
              401,
            );
          } else if (req.headers['authorization'] == 'Bearer fresh_token_999') {
            return http.Response(
              jsonEncode({
                'documents': [
                  {
                    'name': 'projects/p/databases/(default)/documents/establishments/est_1',
                    'fields': {'name': {'stringValue': 'Lycée Général Leclerc'}},
                  }
                ]
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Unexpected', 500);
        }),
        sessionProvider: () => currentSession,
        tokenRefresher: () async {
          refreshCalls++;
          currentSession = currentSession.copyWith(idToken: 'fresh_token_999');
          return currentSession;
        },
        onSessionExpired: () async {
          expiredCalls++;
        },
      );

      final docs = await client.listDocuments('establishments');
      expect(docs.length, 1);
      expect(docs.first.id, 'est_1');
      expect(refreshCalls, 1, reason: 'Refresh must be called exactly once');
      expect(requestCount, 2, reason: 'Request should be retried once');
      expect(expiredCalls, 0);
    });

    test('Concurrent 401 responses share single in-flight refresh (no refresh storm)', () async {
      var currentSession = _createSession(idToken: 'expired_storm_token');
      int refreshCalls = 0;
      final refreshCompleter = Completer<AuthSession>();

      final client = FirestoreRestClient(
        httpClient: MockHttpClient((req) async {
          if (req.headers['authorization'] == 'Bearer expired_storm_token') {
            return http.Response('{"error":"UNAUTHENTICATED"}', 401);
          } else if (req.headers['authorization'] == 'Bearer consolidated_fresh_token') {
            return http.Response(
              jsonEncode({'documents': []}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Error', 500);
        }),
        sessionProvider: () => currentSession,
        tokenRefresher: () {
          refreshCalls++;
          return refreshCompleter.future;
        },
      );

      // Launch 3 requests concurrently
      final future1 = client.listDocuments('establishments');
      final future2 = client.listDocuments('classes');
      final future3 = client.listDocuments('users');

      // Allow event loop to run so all 3 hit 401
      await Future.delayed(const Duration(milliseconds: 20));

      expect(refreshCalls, 1, reason: 'Refresh should only be called ONCE for concurrent 401s');

      // Complete the single refresh
      currentSession = currentSession.copyWith(idToken: 'consolidated_fresh_token');
      refreshCompleter.complete(currentSession);

      final results = await Future.wait([future1, future2, future3]);
      expect(results.length, 3);
      expect(refreshCalls, 1, reason: 'Still exactly 1 refresh call performed');
    });

    test('Second 401 after refresh triggers session expiration', () async {
      var currentSession = _createSession(idToken: 'expired_token');
      int refreshCalls = 0;
      int expiredCalls = 0;

      final client = FirestoreRestClient(
        httpClient: MockHttpClient((req) async {
          // Both initial and refreshed tokens return 401
          return http.Response('{"error":"UNAUTHENTICATED"}', 401);
        }),
        sessionProvider: () => currentSession,
        tokenRefresher: () async {
          refreshCalls++;
          currentSession = currentSession.copyWith(idToken: 'refreshed_but_still_invalid');
          return currentSession;
        },
        onSessionExpired: () async {
          expiredCalls++;
        },
      );

      bool didThrow = false;
      try {
        await client.listDocuments('establishments');
      } catch (e) {
        didThrow = true;
      }

      expect(didThrow, isTrue, reason: 'Must throw on 401 after refresh');
      expect(refreshCalls, 1);
      expect(expiredCalls, 1, reason: 'Persistent 401 must trigger session expiration');
    });

    test('Refresh failure surfaces error and triggers session expiration', () async {
      var currentSession = _createSession(idToken: 'expired_token');
      int expiredCalls = 0;

      final client = FirestoreRestClient(
        httpClient: MockHttpClient((req) async {
          return http.Response('{"error":"UNAUTHENTICATED"}', 401);
        }),
        sessionProvider: () => currentSession,
        tokenRefresher: () async {
          // Token refresher fails (e.g. refresh token revoked or user disabled)
          return null;
        },
        onSessionExpired: () async {
          expiredCalls++;
        },
      );

      bool didThrow = false;
      try {
        await client.listDocuments('establishments');
      } catch (e) {
        didThrow = true;
      }

      expect(didThrow, isTrue, reason: 'Must throw on failed refresh');
      expect(expiredCalls, 1, reason: 'Null refreshed session must trigger expiration');
    });
  });
}
