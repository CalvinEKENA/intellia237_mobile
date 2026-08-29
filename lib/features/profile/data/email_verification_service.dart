import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationStatus {
  const EmailVerificationStatus({
    required this.email,
    required this.isVerified,
  });

  final String email;
  final bool isVerified;
}

class EmailVerificationService {
  EmailVerificationService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<EmailVerificationStatus> status() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmailVerificationException('Connecte-toi pour continuer.');
    }
    await user.reload();
    final refreshed = _auth.currentUser ?? user;
    return EmailVerificationStatus(
      email: refreshed.email ?? '',
      isVerified: refreshed.emailVerified,
    );
  }

  Future<void> send() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmailVerificationException('Connecte-toi pour continuer.');
    }
    if (user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw EmailVerificationException(switch (error.code) {
        'too-many-requests' =>
          'Trop de demandes ont été envoyées. Réessaie plus tard.',
        'network-request-failed' =>
          'La connexion est indisponible. Réessaie une fois en ligne.',
        _ => 'L’e-mail de vérification n’a pas pu être envoyé.',
      });
    }
  }
}

class EmailVerificationException implements Exception {
  const EmailVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
