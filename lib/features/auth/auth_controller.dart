import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/services/firebase_service.dart';

enum AuthMode { signIn, signUp }

class AuthState {
  final bool isLoading;
  final bool isGoogleLoading;
  final String? errorMessage;
  final AuthMode mode;

  const AuthState({
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.errorMessage,
    this.mode = AuthMode.signUp,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isGoogleLoading,
    String? errorMessage,
    bool clearError = false,
    AuthMode? mode,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mode: mode ?? this.mode,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  final _googleSignIn = GoogleSignIn();

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == AuthMode.signUp ? AuthMode.signIn : AuthMode.signUp,
      clearError: true,
    );
  }

  Future<User?> signInWithGoogle() async {
    state = state.copyWith(isGoogleLoading: true, clearError: true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isGoogleLoading: false);
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseService.auth.signInWithCredential(credential);
      state = state.copyWith(isGoogleLoading: false);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isGoogleLoading: false,
        errorMessage: _mapFirebaseError(e.code),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isGoogleLoading: false,
        errorMessage: 'Google Sign-In failed. Please try again.',
      );
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code),
      );
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential =
          await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code),
      );
      return null;
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
