import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/mock/json_loader.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Mock auth backed by `assets/mock/users.json` plus users registered on this
/// device (kept in shared preferences). Passwords are stored in plain text:
/// this is development-only mock data, never use it with real credentials.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._loader);

  static const sessionKey = 'session_user_id';
  static const registeredUsersKey = 'registered_users';

  final JsonLoader _loader;
  List<UserRecord>? _users;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<UserRecord>> users() async {
    if (_users != null) return _users!;
    final seeded = (await _loader.loadList(
      'users.json',
    )).map(UserRecord.fromJson);
    final stored = (await _prefs).getString(registeredUsersKey);
    final registered = stored == null
        ? const <UserRecord>[]
        : (jsonDecode(stored) as List).cast<Map<String, dynamic>>().map(
            UserRecord.fromJson,
          );
    return _users = [...seeded, ...registered];
  }

  Future<UserRecord?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    for (final u in await users()) {
      if (u.user.email.toLowerCase() == normalized) return u;
    }
    return null;
  }

  Future<void> startSession(AppUser user) async =>
      (await _prefs).setString(sessionKey, user.id);

  @override
  Future<AppUser?> currentUser() async {
    final id = (await _prefs).getString(sessionKey);
    if (id == null) return null;
    for (final u in await users()) {
      if (u.user.id == id) return u.user;
    }
    return null;
  }

  @override
  Future<AppUser> register(RegisterRequest request) async {
    if (await findByEmail(request.email) != null) {
      throw const AuthException('An account with this email already exists.');
    }
    final record = UserRecord(
      AppUser(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        name: request.name.trim(),
        email: request.email.trim().toLowerCase(),
        role: request.role,
        stateId: request.stateId,
        courseId: request.courseId,
        aiRank: request.aiRank,
      ),
      request.password,
    );
    (await users()).add(record);
    await _persistRegistered();
    return record.user;
  }

  /// Saves users that are not part of the seeded `users.json`.
  Future<void> _persistRegistered() async {
    final seededIds = (await _loader.loadList(
      'users.json',
    )).map((u) => u['id']).toSet();
    final registered = (await users())
        .where((u) => !seededIds.contains(u.user.id))
        .map((u) => u.toJson())
        .toList();
    await (await _prefs).setString(registeredUsersKey, jsonEncode(registered));
  }

  @override
  Future<void> logout() async => (await _prefs).remove(sessionKey);
}

class UserRecord {
  UserRecord(this.user, this.password);

  factory UserRecord.fromJson(Map<String, dynamic> json) =>
      UserRecord(AppUser.fromJson(json), json['password'] as String);

  AppUser user;
  String password;

  Map<String, dynamic> toJson() => {...user.toJson(), 'password': password};
}
