import 'app_user.dart';

/// Authentication backend. Methods throw [AuthException] with a user-facing
/// message on failure.
abstract class AuthRepository {
  /// The user restored from the persisted session, if any.
  Future<AppUser?> currentUser();

  /// Creates an account. Does not sign the user in.
  Future<AppUser> register(RegisterRequest request);

  /// Email + password sign-in. Starts a session.
  Future<AppUser> login(String email, String password);

  /// Sends a one-time code to the account's email.
  Future<void> sendOtp(String email);

  /// Checks a code without consuming it (used before choosing a new password).
  Future<void> verifyOtp(String email, String otp);

  /// Signs in with a one-time code. Starts a session.
  Future<AppUser> loginWithOtp(String email, String otp);

  /// Sets a new password after verifying the one-time code.
  Future<void> resetPassword(String email, String otp, String newPassword);

  Future<void> logout();
}

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.stateId,
    required this.courseId,
    this.aiRank,
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String stateId;
  final String courseId;
  final int? aiRank;
}
