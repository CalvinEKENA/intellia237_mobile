import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/auth_session.dart';

class FirebaseAuthRestService {
  FirebaseAuthRestService({
    http.Client? httpClient,
    this.apiKey = 'AIzaSyBJwoCiblcaVRCbo66QMi7om02PPniP0SU',
    this.projectId = 'edunova-aabd1',
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String apiKey;
  final String projectId;

  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );
    final response = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw Exception(error);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final uid = data['localId'] as String;
    final idToken = data['idToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final expiresIn =
        int.tryParse(data['expiresIn'] as String? ?? '3600') ?? 3600;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));

    // Fetch authoritative user profile to verify administrative role
    final profile = await fetchUserProfile(uid, idToken);
    final role = profile['role'] as String? ?? '';
    final accountStatus = profile['accountStatus'] as String? ?? 'active';

    if (accountStatus == 'suspended' || accountStatus == 'deleted') {
      throw Exception('Compte désactivé ou suspendu.');
    }

    if (!['superAdmin', 'super_admin', 'admin'].contains(role)) {
      throw Exception('Accès refusé : rôle d\'administrateur requis.');
    }

    return AuthSession(
      uid: uid,
      email: data['email'] as String? ?? email,
      displayName: '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
          .trim(),
      role: role,
      establishmentId: profile['establishmentId'] as String?,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Future<AuthSession> refreshSession(AuthSession current) async {
    final uri = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$apiKey',
    );
    final response = await _http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': current.refreshToken,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Session expirée, veuillez vous reconnecter.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newIdToken = data['id_token'] as String;
    final newRefreshToken = data['refresh_token'] as String;
    final expiresIn =
        int.tryParse(data['expires_in'] as String? ?? '3600') ?? 3600;

    return current.copyWith(
      idToken: newIdToken,
      refreshToken: newRefreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn - 60)),
    );
  }

  Future<Map<String, dynamic>> fetchUserProfile(
    String uid,
    String idToken,
  ) async {
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );
    final response = await _http.get(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      return {};
    }

    final doc = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    return {
      'role': fields['role']?['stringValue'],
      'establishmentId': fields['establishmentId']?['stringValue'],
      'accountStatus': fields['accountStatus']?['stringValue'],
      'firstName': fields['firstName']?['stringValue'],
      'lastName': fields['lastName']?['stringValue'],
    };
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg =
          json['error']?['message'] as String? ?? 'Authentification échouée.';
      if (msg.contains('EMAIL_NOT_FOUND') || msg.contains('INVALID_PASSWORD')) {
        return 'Identifiant ou mot de passe incorrect.';
      }
      if (msg.contains('USER_DISABLED')) {
        return 'Ce compte utilisateur a été désactivé.';
      }
      return msg;
    } catch (_) {
      return 'Erreur de connexion.';
    }
  }
}
