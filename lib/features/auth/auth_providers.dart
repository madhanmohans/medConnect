import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../institutions/institution_providers.dart';
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

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}
