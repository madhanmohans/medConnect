import 'app_user.dart';

/// Authentication backend. Methods throw [AuthException] with a user-facing
/// message on failure.
abstract class AuthRepository {
  /// The user restored from the persisted session, if any.
  Future<AppUser?> currentUser();

  Future<void> logout();
}
