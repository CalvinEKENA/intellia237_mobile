import 'auth_state.dart';

String requireAuthenticatedUserId(AuthState auth) {
  final userId = auth.userId;
  if (auth.status != AuthStatus.authenticated ||
      userId == null ||
      userId.trim().isEmpty) {
    throw StateError('Utilisateur Firebase authentifie introuvable.');
  }
  return userId;
}
