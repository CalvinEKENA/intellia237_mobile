import '../domain/app_role.dart';

enum AuthStatus {
  bootstrapping,
  unauthenticated,
  discovery,
  needsOnboarding,
  authenticated,
  retryableProfileFailure,
  legacyProfileRecovery,
}

/// Phase de session, lue par le routeur et les tests : une seule lecture de
/// l'état, dérivée de [AuthState], jamais stockée à part.
enum AuthSessionPhase {
  /// Aucune session Firebase.
  unauthenticated,

  /// Démarrage ou entrée en cours : l'identité n'est pas encore résolue.
  authenticating,

  /// Identité prouvée, aucun profil : décision d'entrée à prendre.
  authenticatedNoProfile,

  /// Identité prouvée, aucun profil, découverte choisie : aucune donnée
  /// privée, aucun appel IA.
  discovery,

  /// Profil complet, un seul espace.
  oneRole,

  /// Profil complet, plusieurs espaces autorisés par le serveur.
  multiRole,

  /// Personnel en attente de validation par son établissement.
  pendingStaff,

  /// Compte suspendu ou supprimé : la session a été refermée.
  suspended,

  /// Profil illisible pour l'instant, ou rôle historique à réparer.
  error,
}

class AuthState {
  const AuthState._({
    required this.status,
    this.role,
    this.availableRoles = const [],
    this.userId,
    this.email,
    this.firstName,
    this.isLoading = false,
    this.error,
    this.profileCompleted = true,
    this.isSuperAdmin = false,
    this.establishmentId,
    this.spaceChoicePending = false,
    this.accountStatus,
    this.suspended = false,
  });

  const AuthState.bootstrapping() : this._(status: AuthStatus.bootstrapping);

  const AuthState.unauthenticated({String? error, bool suspended = false})
    : this._(
        status: AuthStatus.unauthenticated,
        error: error,
        profileCompleted: false,
        suspended: suspended,
      );

  const AuthState.discovery({
    required String userId,
    String? email,
    String? firstName,
  }) : this._(
         status: AuthStatus.discovery,
         userId: userId,
         email: email,
         firstName: firstName,
         profileCompleted: false,
       );

  const AuthState.authenticated({
    required AppRole role,
    List<AppRole> availableRoles = const [],
    required String userId,
    String? email,
    String? firstName,
    bool profileCompleted = true,
    bool isSuperAdmin = false,
    String? establishmentId,
    bool spaceChoicePending = false,
    String? accountStatus,
  }) : this._(
         status: AuthStatus.authenticated,
         role: role,
         availableRoles: availableRoles,
         userId: userId,
         email: email,
         firstName: firstName,
         profileCompleted: profileCompleted,
         isSuperAdmin: isSuperAdmin,
         establishmentId: establishmentId,
         spaceChoicePending: spaceChoicePending,
         accountStatus: accountStatus,
       );

  const AuthState.needsOnboarding({
    required String userId,
    String? email,
    String? firstName,
    AppRole? recoveredRole,
    String? accountStatus,
  }) : this._(
         status: AuthStatus.needsOnboarding,
         userId: userId,
         email: email,
         firstName: firstName,
         role: recoveredRole,
         profileCompleted: false,
         accountStatus: accountStatus,
       );

  const AuthState.retryableProfileFailure({
    String? userId,
    String? email,
    String? firstName,
    AppRole? cachedRole,
    bool cachedProfileCompleted = false,
    bool isSuperAdmin = false,
    String? establishmentId,
    String? error,
  }) : this._(
         status: AuthStatus.retryableProfileFailure,
         userId: userId,
         email: email,
         firstName: firstName,
         role: cachedRole,
         profileCompleted: cachedProfileCompleted,
         isSuperAdmin: isSuperAdmin,
         establishmentId: establishmentId,
         error: error,
       );

  const AuthState.legacyProfileRecovery({
    required String userId,
    String? email,
    String? firstName,
    AppRole? recoveredRole,
    bool profileCompleted = false,
    bool isSuperAdmin = false,
    String? establishmentId,
    String? error,
  }) : this._(
         status: AuthStatus.legacyProfileRecovery,
         userId: userId,
         email: email,
         firstName: firstName,
         role: recoveredRole,
         profileCompleted: profileCompleted,
         isSuperAdmin: isSuperAdmin,
         establishmentId: establishmentId,
         error: error,
       );

  final AuthStatus status;
  final AppRole? role;
  final List<AppRole> availableRoles;

  /// Administration sans rattachement : sa portée couvre tous les
  /// établissements et tous les niveaux.
  final bool isSuperAdmin;

  /// L'école du compte, quand il en a une : elle borne ce que le personnel
  /// d'un établissement peut lire, rédiger et administrer.
  final String? establishmentId;
  final String? userId;
  final String? email;
  final String? firstName;
  final bool profileCompleted;
  final bool isLoading;
  final String? error;

  /// Compte à plusieurs espaces sans espace retenu sur cet appareil : le
  /// sélecteur s'affiche une fois, avant tout accueil.
  final bool spaceChoicePending;

  /// Statut serveur du compte, quand il est connu.
  final String? accountStatus;

  /// La dernière session a été refermée parce que le compte est suspendu.
  final bool suspended;

  bool get hasFirebaseSession =>
      status != AuthStatus.bootstrapping &&
      status != AuthStatus.unauthenticated;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated ||
      ((status == AuthStatus.retryableProfileFailure ||
              status == AuthStatus.legacyProfileRecovery) &&
          role != null &&
          profileCompleted);

  List<AppRole> get resolvedRoles => availableRoles.isNotEmpty
      ? availableRoles
      : (role != null ? [role!] : const []);

  bool get isMultiRole => resolvedRoles.length > 1;

  bool get isPendingStaff =>
      accountStatus == 'pending_validation' &&
      (role == AppRole.teacher || role == AppRole.admin);

  AuthSessionPhase get sessionPhase {
    if (isLoading && !hasFirebaseSession) {
      return AuthSessionPhase.authenticating;
    }
    return switch (status) {
      AuthStatus.bootstrapping => AuthSessionPhase.authenticating,
      AuthStatus.unauthenticated =>
        suspended
            ? AuthSessionPhase.suspended
            : AuthSessionPhase.unauthenticated,
      AuthStatus.discovery => AuthSessionPhase.discovery,
      AuthStatus.needsOnboarding =>
        isPendingStaff
            ? AuthSessionPhase.pendingStaff
            : AuthSessionPhase.authenticatedNoProfile,
      AuthStatus.authenticated =>
        isPendingStaff
            ? AuthSessionPhase.pendingStaff
            : isMultiRole
            ? AuthSessionPhase.multiRole
            : AuthSessionPhase.oneRole,
      AuthStatus.retryableProfileFailure ||
      AuthStatus.legacyProfileRecovery => AuthSessionPhase.error,
    };
  }

  AuthState copyWith({
    AuthStatus? status,
    AppRole? role,
    List<AppRole>? availableRoles,
    String? userId,
    String? email,
    String? firstName,
    bool? isLoading,
    String? error,
    bool? profileCompleted,
    bool? isSuperAdmin,
    String? establishmentId,
    bool? spaceChoicePending,
  }) {
    return AuthState._(
      status: status ?? this.status,
      role: role ?? this.role,
      availableRoles: availableRoles ?? this.availableRoles,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      establishmentId: establishmentId ?? this.establishmentId,
      spaceChoicePending: spaceChoicePending ?? this.spaceChoicePending,
      accountStatus: accountStatus,
      suspended: suspended,
    );
  }
}
