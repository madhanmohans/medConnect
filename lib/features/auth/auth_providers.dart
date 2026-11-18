import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mock/json_loader.dart';
import 'data/mock_auth_repository.dart';
import 'domain/app_user.dart';
import 'domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(jsonLoaderProvider)),
);

/// The signed-in user (null when signed out). Restores the session on start.
final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AppUser?> build() => ref.watch(authRepositoryProvider).currentUser();

  /// Creates an account; the user still has to log in afterwards.
  Future<AppUser> register(RegisterRequest request) => _repo.register(request);

  Future<void> login(String email, String password) async {
    state = AsyncData(await _repo.login(email, password));
  }

  Future<void> sendOtp(String email) => _repo.sendOtp(email);

  Future<void> verifyOtp(String email, String otp) =>
      _repo.verifyOtp(email, otp);

  Future<void> loginWithOtp(String email, String otp) async {
    state = AsyncData(await _repo.loginWithOtp(email, otp));
  }

  Future<void> resetPassword(String email, String otp, String newPassword) =>
      _repo.resetPassword(email, otp, newPassword);

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}
