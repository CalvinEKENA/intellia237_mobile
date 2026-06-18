import '../app_role.dart';

/// Données utilisateur récupérées depuis Firestore après authentification
class AuthUserData {
  const AuthUserData({
    required this.uid,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.profileCompleted,
  });

  final String uid;
  final String email;
  final AppRole role;
  final String firstName;
  final String lastName;
  final bool profileCompleted;
}

/// Interface du repository d'authentification
abstract class AuthRepository {
  /// Connexion email/mot de passe — retourne les données utilisateur Firestore
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  });

  /// Inscription — crée le compte Firebase Auth + le profil Firestore
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  });

  /// Envoie un email de réinitialisation du mot de passe
  Future<void> sendPasswordResetEmail(String email);

  /// Vérifie s'il y a un utilisateur connecté et retourne ses données
  Future<AuthUserData?> getCurrentUser();

  /// Déconnexion
  Future<void> signOut();
}
