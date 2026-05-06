import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _serverClientId =
      '950456615757-agno7h5fr76avo984pq3ndc7b8df81jc.apps.googleusercontent.com';

  bool _googleInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;

    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);

    _googleInitialized = true;
  }

  void updateEmail(String value) {
    emit(state.copyWith(email: value, clearError: true));
  }

  void updatePassword(String value) {
    emit(state.copyWith(password: value, clearError: true));
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
        state.copyWith(
          isLoading: false,
          errorMessage: e.message ?? 'Login failed.',
        ),
      );
      return false;
    } catch (e) {
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
        state.copyWith(
          isLoading: false,
          errorMessage: e.message ?? 'Registration failed.',
        ),
      );
      return false;
    } catch (e) {
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
      emit(state.copyWith(errorMessage: 'Please enter your email address.'));
      return false;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _auth.sendPasswordResetEmail(email: email);

      emit(state.copyWith(isLoading: false));
      return true;
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.message ?? 'Reset password failed.',
        ),
      );
      return false;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Reset password failed. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _initializeGoogleSignIn();

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
        state.copyWith(
          isLoading: false,
          errorMessage: e.message ?? 'Google Sign-In failed.',
        ),
      );
      return false;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Google Sign-In failed: $e',
        ),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _initializeGoogleSignIn();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await _auth.signOut();
  }
}
