import 'app_user.dart';

/// Authentication backend. Methods throw [AuthException] with a user-facing
/// message on failure.
abstract class AuthRepository {
  /// The user restored from the persisted session, if any.
  Future<AppUser?> currentUser();

  /// Creates an account. Does not sign the user in.
  Future<AppUser> register(RegisterRequest request);

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
