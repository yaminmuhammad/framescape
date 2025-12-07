part of 'auth_bloc.dart';

/// Base class for all auth events
abstract class AuthEvent {}

/// Event to start anonymous sign in
class AuthSignInAnonymously extends AuthEvent {}

/// Event to sign out
class AuthSignOut extends AuthEvent {}

/// Event when auth state changes externally
class AuthStateChanged extends AuthEvent {
  final String? userId;
  AuthStateChanged(this.userId);
}
