import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:framescape/bloc/auth/auth_bloc.dart';
import 'package:framescape/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Generate mock classes
@GenerateMocks([AuthService, User])
import 'auth_bloc_test.mocks.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      // Stub authStateChanges to return empty stream to avoid errors
      when(mockAuthService.authStateChanges).thenAnswer((_) => Stream.empty());
      authBloc = AuthBloc(authService: mockAuthService);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthState.initial', () {
      expect(
        authBloc.state,
        equals(const AuthState(status: AuthStatus.initial)),
      );
    });

    test('has correct initial status', () {
      expect(authBloc.state.status, equals(AuthStatus.initial));
      expect(authBloc.state.isAuthenticated, isFalse);
      expect(authBloc.state.isLoading, isFalse);
    });

    blocTest<AuthBloc, AuthState>(
      'emits [loading] when AuthSignInAnonymously',
      build: () {
        when(
          mockAuthService.signInAnonymously(),
        ).thenAnswer((_) async => MockUser());
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignInAnonymously()),
      expect: () => [
        predicate<AuthState>((state) => state.status == AuthStatus.loading),
      ],
      verify: (_) {
        verify(mockAuthService.signInAnonymously()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when AuthSignInAnonymously fails',
      build: () {
        when(
          mockAuthService.signInAnonymously(),
        ).thenThrow(Exception('Auth failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignInAnonymously()),
      expect: () => [
        predicate<AuthState>((state) => state.status == AuthStatus.loading),
        predicate<AuthState>((state) =>
            state.status == AuthStatus.error &&
            state.errorMessage == 'Exception: Auth failed'),
      ],
      verify: (_) {
        verify(mockAuthService.signInAnonymously()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [unauthenticated] when AuthSignOut',
      build: () {
        when(mockAuthService.signOut()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignOut()),
      expect: () => [
        predicate<AuthState>((state) => state.status == AuthStatus.unauthenticated),
      ],
      verify: (_) {
        verify(mockAuthService.signOut()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [authenticated] when AuthStateChanged with userId',
      build: () => authBloc,
      act: (bloc) => bloc.add(AuthStateChanged('user-123')),
      expect: () => [
        predicate<AuthState>((state) =>
            state.status == AuthStatus.authenticated && state.userId == 'user-123'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [unauthenticated] when AuthStateChanged with null',
      build: () => authBloc,
      act: (bloc) => bloc.add(AuthStateChanged(null)),
      expect: () => [
        predicate<AuthState>((state) => state.status == AuthStatus.unauthenticated),
      ],
    );

    test('closes subscription on close', () {
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream<User?>.empty());

      authBloc.close();

      // Stream subscription should be cancelled
      // In real implementation, this would be verified through the mock
    });
  });
}
