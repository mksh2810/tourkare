import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';

class AuthResult {
  final bool success;
  final String? message;

  const AuthResult({required this.success, this.message});
}

class AuthService extends ChangeNotifier {
  StreamSubscription<User?>? _authSubscription;
  AuthService._() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
        _token = null;
        _isLoggedIn = false;
        notifyListeners();
        return;
      }

      try {
        await _refreshUserAndToken();
      } catch (e) {
        _currentUser = null;
        _token = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    });
  }


  static final AuthService instance = AuthService._();

  // Firebase authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user data
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  // Firebase ID token for future FastAPI requests
  String? _token;

  String? get token => _token;

  // ============================================================
  // HELPER: UPDATE USER DATA AND TOKEN
  // ============================================================

  Future<void> _refreshUserAndToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;

    if (user == null) {
      _currentUser = null;
      _token = null;
      _isLoggedIn = false;

      notifyListeners();
      return;
    }

    await user.reload();

    final updatedUser = _auth.currentUser;

    if (updatedUser == null) {
      _currentUser = null;
      _token = null;
      _isLoggedIn = false;

      notifyListeners();
      return;
    }

    _currentUser = {
      'uid': updatedUser.uid,
      'name': updatedUser.displayName ?? '',
      'email': updatedUser.email ?? '',
      'photoUrl': updatedUser.photoURL,
    };

    _token = await updatedUser.getIdToken(forceRefresh);

    _isLoggedIn = true;

    notifyListeners();
  }

  // ============================================================
  // HELPER: AUTHENTICATION ERROR MESSAGES
  // ============================================================

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Password should be at least 6 characters.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';

      case 'requires-recent-login':
        return 'Please login again before performing this action.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using another sign-in method.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ============================================================
  // LOGIN WITH EMAIL AND PASSWORD
  // ============================================================

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        return const AuthResult(success: false, message: 'Login failed.');
      }

      await _refreshUserAndToken();

      return const AuthResult(success: true, message: 'Login successful.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getAuthErrorMessage(e.code));
    } catch (e) {
      return const AuthResult(
        success: false,
        message: 'Unable to login. Please try again.',
      );
    }
  }

  // ============================================================
  // SIGNUP WITH EMAIL AND PASSWORD
  // ============================================================

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final trimmedName = name.trim();

      if (trimmedName.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Name cannot be empty.',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        return const AuthResult(
          success: false,
          message: 'Account creation failed.',
        );
      }

      // Save display name in Firebase
      await user.updateDisplayName(trimmedName);

      await _refreshUserAndToken(forceRefresh: true);

      return const AuthResult(
        success: true,
        message: 'Account created successfully.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getAuthErrorMessage(e.code));
    } catch (e) {
      return const AuthResult(
        success: false,
        message: 'Unable to create account. Please try again.',
      );
    }
  }

  // ============================================================
  // SIGNUP WITH GOOGLE
  // ============================================================

  Future<AuthResult> signupWithGoogle() async {
    try {
      final userCredential = await _auth.signInWithPopup(GoogleAuthProvider());

      if (userCredential.user == null) {
        return const AuthResult(
          success: false,
          message: 'Google sign-up failed.',
        );
      }

      await _refreshUserAndToken();

      return const AuthResult(
        success: true,
        message: 'Google sign-up successful.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getAuthErrorMessage(e.code));
    } catch (e) {
      return const AuthResult(
        success: false,
        message: 'Unable to sign in with Google.',
      );
    }
  }

  // ============================================================
  // LOGIN WITH GOOGLE
  // ============================================================

  Future<AuthResult> loginWithGoogle() async {
    try {
      final userCredential = await _auth.signInWithPopup(GoogleAuthProvider());

      if (userCredential.user == null) {
        return const AuthResult(
          success: false,
          message: 'Google login failed.',
        );
      }

      await _refreshUserAndToken();

      return const AuthResult(
        success: true,
        message: 'Google login successful.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getAuthErrorMessage(e.code));
    } catch (e) {
      return const AuthResult(
        success: false,
        message: 'Unable to sign in with Google.',
      );
    }
  }

  // ============================================================
  // CHECK / RESTORE SESSION
  // ============================================================

  Future<void> checkSession() async {
    try {
      await _refreshUserAndToken();
    } catch (e) {
      _currentUser = null;
      _token = null;
      _isLoggedIn = false;

      notifyListeners();
    }
  }

  // ============================================================
  // GET FRESH FIREBASE ID TOKEN
  // ============================================================

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        _token = null;
        return null;
      }

      _token = await user.getIdToken(forceRefresh);

      return _token;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<AuthResult> updateProfile({required String name}) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return const AuthResult(success: false, message: 'Please login first.');
      }

      final trimmedName = name.trim();

      if (trimmedName.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Name cannot be empty.',
        );
      }

      await user.updateDisplayName(trimmedName);

      await _refreshUserAndToken(forceRefresh: true);

      return const AuthResult(
        success: true,
        message: 'Profile updated successfully.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getAuthErrorMessage(e.code));
    } catch (e) {
      return const AuthResult(
        success: false,
        message: 'Unable to update profile.',
      );
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null || user.email == null) {
        return const AuthResult(success: false, message: 'Please login first.');
      }

      // Check whether this user has an email/password credential.
      final hasPasswordProvider = user.providerData.any(
        (provider) => provider.providerId == 'password',
      );

      if (!hasPasswordProvider) {
        return const AuthResult(
          success: false,
          message: 'This account does not have an email/password login.',
        );
      }

      if (newPassword.length < 6) {
        return const AuthResult(
          success: false,
          message: 'New password must be at least 6 characters.',
        );
      }

      if (currentPassword == newPassword) {
        return const AuthResult(
          success: false,
          message: 'New password must be different from the current password.',
        );
      }

      // Reauthenticate before changing password.
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      // Refresh token after sensitive account change.
      await _refreshUserAndToken(forceRefresh: true);

      return const AuthResult(
        success: true,
        message: 'Password changed successfully.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getAuthErrorMessage(e.code));
    } catch (e) {
      return const AuthResult(
        success: false,
        message: 'Unable to change password.',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } finally {
      _currentUser = null;
      _token = null;
      _isLoggedIn = false;

      notifyListeners();
    }
  }
}
