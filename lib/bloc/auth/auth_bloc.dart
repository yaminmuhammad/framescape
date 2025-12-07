import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for handling authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(const AuthState.initial()) {
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthSignOut>(_onSignOut);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen((user) {
      add(AuthStateChanged(user?.uid));
    });
  }

  Future<void> _onSignInAnonymously(
    AuthSignInAnonymously event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authService.signInAnonymously();
      // State will be updated via AuthStateChanged listener
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    emit(const AuthState.unauthenticated());
  }

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.userId != null) {
      emit(AuthState.authenticated(event.userId!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
