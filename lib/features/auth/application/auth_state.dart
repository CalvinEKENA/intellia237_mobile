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
  });

  const AuthState.bootstrapping() : this._(status: AuthStatus.bootstrapping);

  const AuthState.unauthenticated({String? error})
    : this._(
        status: AuthStatus.unauthenticated,
        error: error,
        profileCompleted: false,
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
       );

  const AuthState.needsOnboarding({
    required String userId,
    String? email,
    String? firstName,
    AppRole? recoveredRole,
  }) : this._(
         status: AuthStatus.needsOnboarding,
         userId: userId,
         email: email,
         firstName: firstName,
         role: recoveredRole,
         profileCompleted: false,
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
    );
  }
}
