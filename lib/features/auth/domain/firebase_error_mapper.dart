abstract final class FirebaseErrorMapper {
  static String normalizeCode(String? code, [String? technicalMessage]) {
    final source = '${code ?? ''} ${technicalMessage ?? ''}'.toLowerCase();
    if (source.contains('configuration_not_found') ||
        source.contains('configuration-not-found')) {
      return 'configuration-not-found';
    }
    return (code ?? 'unknown-error').toLowerCase().replaceAll('_', '-');
  }

  static String authMessage({String? code, String? technicalMessage}) {
    return switch (normalizeCode(code, technicalMessage)) {
      'email-already-in-use' =>
        'Cette adresse e-mail est déjà associée à un compte.',
      'invalid-email' => 'Vérifie l’adresse e-mail saisie.',
      'weak-password' => 'Choisis un mot de passe plus sécurisé.',
      'network-request-failed' || 'network-error' =>
        'La connexion semble interrompue. Vérifie Internet puis réessaie.',
      'configuration-not-found' =>
        'Le service d’inscription est momentanément indisponible. '
            'Réessaie dans quelques instants.',
      'too-many-requests' =>
        'Trop de tentatives ont été effectuées. Patiente quelques minutes.',
      'quota-exceeded' =>
        'Le service est momentanément saturé. Réessaie un peu plus tard.',
      'operation-not-allowed' =>
        'Ce mode de connexion n’est pas encore disponible.',
      'user-disabled' =>
        'Ce compte est désactivé. Contacte l’assistance Intellia 237.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Adresse e-mail ou mot de passe incorrect.',
      'timeout' || 'deadline-exceeded' =>
        'Le service met trop de temps à répondre. Réessaie.',
      _ => 'Une erreur empêche l’authentification. Réessaie dans un instant.',
    };
  }

  static String serviceMessage({String? code, String? technicalMessage}) {
    return switch (normalizeCode(code, technicalMessage)) {
      'permission-denied' =>
        'Le profil n’a pas pu être enregistré. Vérifie les autorisations.',
      'unavailable' =>
        'Le service est temporairement indisponible. Réessaie dans un instant.',
      'deadline-exceeded' ||
      'timeout' => 'Le service met trop de temps à répondre. Réessaie.',
      'already-exists' => 'Un profil existe déjà pour ce compte.',
      'invalid-argument' =>
        'Certaines informations sont invalides. Vérifie le formulaire.',
      'unauthenticated' => 'Ta session a expiré. Reconnecte-toi puis réessaie.',
      _ =>
        'Le profil n’a pas pu être finalisé. Tes informations restent '
            'disponibles pour réessayer.',
    };
  }

  /// Identifiant diagnostic stable, affiché discrètement en staging et
  /// copiable par le testeur (ex. « AUTH-CONFIG-001 » quand Firebase
  /// Authentication ou Email/Mot de passe n'est pas activé côté console).
  ///
  /// N'expose jamais d'information sensible : c'est un code de catégorie.
  static String diagnosticId(String? code, [String? technicalMessage]) {
    return switch (normalizeCode(code, technicalMessage)) {
      'configuration-not-found' || 'operation-not-allowed' => 'AUTH-CONFIG-001',
      'network-request-failed' || 'network-error' => 'AUTH-NET-002',
      'too-many-requests' || 'quota-exceeded' => 'AUTH-RATE-003',
      'email-already-in-use' => 'AUTH-EMAIL-004',
      'weak-password' => 'AUTH-PWD-005',
      'invalid-email' => 'AUTH-EMAIL-006',
      'user-disabled' => 'AUTH-USER-007',
      'permission-denied' => 'DATA-PERM-101',
      'unavailable' || 'deadline-exceeded' || 'timeout' => 'SVC-UNAVAIL-102',
      'invalid-argument' => 'DATA-ARG-103',
      'unauthenticated' => 'DATA-AUTH-104',
      'missing-user' => 'AUTH-USER-105',
      _ => 'APP-UNKNOWN-000',
    };
  }

  static bool canRetry(String? code, [String? technicalMessage]) {
    return switch (normalizeCode(code, technicalMessage)) {
      'network-request-failed' ||
      'network-error' ||
      'configuration-not-found' ||
      'unavailable' ||
      'deadline-exceeded' ||
      'timeout' ||
      'quota-exceeded' => true,
      _ => false,
    };
  }
}
