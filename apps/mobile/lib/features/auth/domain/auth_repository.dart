/// Mây Family Finance — AuthRepository (auth domain layer)
///
/// Abstracts Firebase Auth operations behind a simple interface.
/// All UI code depends on this abstraction, not on firebase_auth directly.

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/services.dart';

// -- Public types --

/// Supported authentication providers.
enum AuthProvider { google, apple, phone }

/// Result of a successful sign-in operation.
class AuthResult {
  /// User UID from the identity provider.
  final String uid;

  /// Display name (if available from the provider).
  final String? displayName;

  /// Email address (if available and verified from the provider).
  final String? email;

  const AuthResult(this.uid, this.displayName, this.email);
}

/// Error type for auth operations.
enum AuthErrorType {
  network,
  cancelled,
  invalidCredentials,
  tooManyAttempts,
  unknown,
}

/// Sanitized error message returned to UI (never exposes raw codes).
class AuthError implements Exception {
  final AuthErrorType type;
  final String userMessage;
  final String? code;

  const AuthError({
    required this.type,
    required this.userMessage,
    this.code,
  });

  @override
  String toString() => 'AuthError($type, code: $code)';
}

// -- Repository interface --

class AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  /// Sign in with Google provider.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final userCredential = await _auth.signInWithProvider(
        fb.GoogleAuthProvider(),
      );
      if (userCredential.user == null) {
        throw const AuthError(
          type: AuthErrorType.unknown,
          userMessage: 'Xác thực không thành công. Vui lòng thử lại.',
        );
      }
      return AuthResult(
        userCredential.user!.uid,
        userCredential.user!.displayName,
        userCredential.user!.email,
      );
    } on PlatformException catch (e) {
      throw _sanitizeError(e);
    } on AuthError {
      rethrow;
    } catch (_) {
      throw const AuthError(
        type: AuthErrorType.unknown,
        userMessage: 'Đã xảy ra lỗi không mong đợi.',
      );
    }
  }

  /// Sign in with Apple provider (iOS only).
  Future<AuthResult?> signInWithApple() async {
    try {
      final appleProvider = fb.AppleAuthProvider();
      final userCredential = await _auth.signInWithProvider(appleProvider);
      if (userCredential.user == null) {
        throw const AuthError(
          type: AuthErrorType.unknown,
          userMessage: 'Xác thực không thành công. Vui lòng thử lại.',
        );
      }
      return AuthResult(
        userCredential.user!.uid,
        userCredential.user!.displayName,
        userCredential.user!.email,
      );
    } on PlatformException catch (e) {
      final authError = _sanitizeError(e);
      if (e.code == 'sign_in_cancelled') return null;
      throw authError;
    } on AuthError {
      rethrow;
    } catch (_) {
      throw const AuthError(
        type: AuthErrorType.unknown,
        userMessage: 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async => await _auth.signOut();

  /// Stream that emits true when authenticated, false when signed out.
  Stream<bool> get authStateChanges => _auth.authStateChanges().map(
        (user) => user != null,
      );

  /// Returns the currently signed-in user, or null if not authenticated.
  fb.User? get currentUser => _auth.currentUser;

  // -- Internal helpers --

  AuthError _sanitizeError(PlatformException e) {
    final code = e.code;
    switch (code) {
      case 'sign-in-cancelled':
      case 'account-not-found':
        return AuthError(
          type: AuthErrorType.cancelled,
          userMessage: 'Bạn đã hủy đăng nhập.',
          code: code,
        );
      case 'invalid-email':
      case 'user-not-found':
        return AuthError(
          type: AuthErrorType.invalidCredentials,
          userMessage: 'Email không hợp lệ.',
          code: code,
        );
      case 'wrong-password':
      case 'invalid-credential':
        return AuthError(
          type: AuthErrorType.invalidCredentials,
          userMessage: 'Thông tin đăng nhập không đúng.',
          code: code,
        );
      case 'too-many-requests':
      case 'operation-not-allowed':
        return AuthError(
          type: AuthErrorType.tooManyAttempts,
          userMessage: 'Quá nhiều thử nghiệm. Vui lòng thử lại sau.',
          code: code,
        );
      case 'network-request-failed':
        return AuthError(
          type: AuthErrorType.network,
          userMessage: 'Kết nối mạng không khả dụng.',
          code: code,
        );
      default:
        return AuthError(
          type: AuthErrorType.unknown,
          userMessage: 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
          code: code,
        );
    }
  }
}
