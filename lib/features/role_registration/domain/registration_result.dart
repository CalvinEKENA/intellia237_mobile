class RoleRegistrationResult {
  const RoleRegistrationResult({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.accountStatus,
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;

  /// Statut renvoyé par le serveur pour les rôles privilégiés.
  ///
  /// `submitStaffRegistration` crée la demande avec `pending_validation` :
  /// l'inscription a bien abouti, mais le compte attend une validation. Ce
  /// champ était ignoré, si bien qu'une demande enregistrée ne pouvait pas
  /// être distinguée d'un compte immédiatement actif.
  final String? accountStatus;

  /// Vrai quand le compte existe mais attend une validation humaine.
  bool get awaitsValidation => accountStatus == 'pending_validation';
}
