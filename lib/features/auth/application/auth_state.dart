import '../domain/app_role.dart';

enum AuthStatus { bootstrapping, unauthenticated, authenticated }

class AuthState {
  const AuthState._({
    required this.status,
    this.role,
    this.userId,
    this.email,
    this.firstName,
    this.isLoading = false,
    this.error,
  });

  const AuthState.bootstrapping() : this._(status: AuthStatus.bootstrapping);

  const AuthState.unauthenticated({String? error})
    : this._(status: AuthStatus.unauthenticated, error: error);

  const AuthState.authenticated({
    required AppRole role,
    required String userId,
    String? email,
    String? firstName,
  }) : this._(
         status: AuthStatus.authenticated,
         role: role,
         userId: userId,
         email: email,
         firstName: firstName,
       );

  final AuthStatus status;
  final AppRole? role;
  final String? userId;
  final String? email;
  final String? firstName;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AppRole? role,
    String? userId,
    String? email,
    String? firstName,
    bool? isLoading,
    String? error,
  }) {
    return AuthState._(
      status: status ?? this.status,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
