import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_session.dart';
import '../domain/rbac_capabilities.dart';
import '../data/windows_credential_store.dart';
import '../data/firebase_auth_rest_service.dart';

final credentialStoreProvider = Provider<CredentialStore>((ref) {
  return WindowsSecureCredentialStore();
});

final authRestServiceProvider = Provider<FirebaseAuthRestService>((ref) {
  return FirebaseAuthRestService();
});

final authSessionProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthSession?>>((ref) {
      final store = ref.watch(credentialStoreProvider);
      final rest = ref.watch(authRestServiceProvider);
      return AuthNotifier(store, rest);
    });

final rbacCapabilitiesProvider = Provider<RbacCapabilities>((ref) {
  final session = ref.watch(authSessionProvider).asData?.value;
  return RbacCapabilities.fromSession(session);
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthNotifier(this._store, this._rest) : super(const AsyncValue.loading()) {
    init();
  }

  final CredentialStore _store;
  final FirebaseAuthRestService _rest;

  Future<void> init() async {
    try {
      final session = await _store.readSession();
      if (session == null) {
        state = const AsyncValue.data(null);
        return;
      }

      if (session.isExpired) {
        try {
          final refreshed = await _rest.refreshSession(session);
          await _store.saveSession(refreshed);
          state = AsyncValue.data(refreshed);
        } catch (_) {
          await _store.clearSession();
          state = const AsyncValue.data(null);
        }
      } else {
        state = AsyncValue.data(session);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final session = await _rest.signInWithPassword(
        email: email,
        password: password,
      );
      await _store.saveSession(session);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<AuthSession?> refreshSession() async {
    final current = state.asData?.value;
    if (current == null || current.refreshToken.isEmpty) {
      await signOut();
      return null;
    }
    try {
      final refreshed = await _rest.refreshSession(current);
      final profile = await _rest.fetchUserProfile(refreshed.uid, refreshed.idToken);
      final accountStatus = profile['accountStatus'] as String? ?? 'active';
      if (accountStatus == 'suspended' || accountStatus == 'deleted') {
        await signOut();
        return null;
      }
      await _store.saveSession(refreshed);
      state = AsyncValue.data(refreshed);
      return refreshed;
    } catch (_) {
      await signOut();
      return null;
    }
  }

  Future<void> signOut() async {
    await _store.clearSession();
    state = const AsyncValue.data(null);
  }
}

