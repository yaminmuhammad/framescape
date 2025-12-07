part of 'auth_bloc.dart';

/// Possible auth states
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state class
class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.errorMessage,
  });

  /// Initial state
  const AuthState.initial() : this(status: AuthStatus.initial);

  /// Loading state
  const AuthState.loading() : this(status: AuthStatus.loading);

  /// Authenticated state with user ID
  AuthState.authenticated(String userId)
    : this(status: AuthStatus.authenticated, userId: userId);

  /// Unauthenticated state
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  /// Error state with message
  AuthState.error(String message)
    : this(status: AuthStatus.error, errorMessage: message);

  /// Helper getters
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}
