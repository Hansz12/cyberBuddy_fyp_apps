import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updateEmail(String value) {
    emit(state.copyWith(email: value, clearError: true));
  }

  void updatePassword(String value) {
    emit(state.copyWith(password: value, clearError: true));
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect. If you registered with Google, tap Forgot password first to set a password for manual login.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'email-already-in-use':
        return 'This email already exists. Please sign in or reset your password.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<bool> signIn() async {
    final email = state.email.trim();
    final password = state.password.trim();

    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter email and password.'));
      return false;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      emit(state.copyWith(isLoading: false));
      return true;
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: _friendlyAuthError(e)),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> signUp() async {
    final email = state.email.trim();
    final password = state.password.trim();

    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter email and password.'));
      return false;
    }

    if (password.length < 6) {
      emit(
        state.copyWith(errorMessage: 'Password must be at least 6 characters.'),
      );
      return false;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      emit(state.copyWith(isLoading: false));
      return true;
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: _friendlyAuthError(e)),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Registration failed. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> resetPassword() async {
    final email = state.email.trim();

    if (email.isEmpty) {
      emit(
        state.copyWith(errorMessage: 'Please enter your email address first.'),
      );
      return false;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _auth.sendPasswordResetEmail(email: email);

      emit(
        state.copyWith(
          isLoading: false,
          errorMessage:
              'Password setup link sent. Check your email, set a password, then you can login manually or with Google.',
        ),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: _friendlyAuthError(e)),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to send password reset email.',
        ),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '950456615757-agno7h5fr76avo984pq3ndc7b8df81jc.apps.googleusercontent.com',
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      emit(state.copyWith(isLoading: false));
      return true;
    } on GoogleSignInException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.description ?? 'Google Sign-In cancelled.',
        ),
      );
      return false;
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: _friendlyAuthError(e)),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Google Sign-In failed. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await _auth.signOut();
  }
}
