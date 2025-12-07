import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling Firebase Authentication.
/// Uses Anonymous Authentication as per implementation plan.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// User ID or null if not authenticated
  String? get uid => _auth.currentUser?.uid;

  /// Sign in anonymously
  /// Returns the User if successful, throws on error
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Authentication failed');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// Custom exception for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
