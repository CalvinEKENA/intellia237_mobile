abstract final class AuthInputValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$',
  );

  static String? displayName(String value, {required String label}) {
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '$label doit contenir au moins 2 caracteres.';
    }
    if (trimmed.length > 60) {
      return '$label ne doit pas depasser 60 caracteres.';
    }
    return null;
  }

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Adresse email requise.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Adresse email invalide.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caracteres.';
    }
    if (value.length > 256) {
      return 'Le mot de passe ne doit pas depasser 256 caracteres.';
    }
    return null;
  }

  static String? confirmPassword({
    required String password,
    required String confirmation,
  }) {
    if (confirmation != password) {
      return 'La confirmation du mot de passe est invalide.';
    }
    return null;
  }
}
