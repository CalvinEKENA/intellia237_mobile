import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_session.dart';

abstract class CredentialStore {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> readSession();
  Future<void> clearSession();
}

class WindowsSecureCredentialStore implements CredentialStore {
  WindowsSecureCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            wOptions: WindowsOptions(useBackwardCompatibility: false),
          );

  final FlutterSecureStorage _storage;
  static const _sessionKey = 'intellia_studio_session_v1';

  @override
  Future<void> saveSession(AuthSession session) async {
    final raw = jsonEncode(session.toJson());
    await _storage.write(key: _sessionKey, value: raw);
  }

  @override
  Future<AuthSession?> readSession() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession.fromJson(map);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
