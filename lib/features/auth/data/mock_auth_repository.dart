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

  static const otpValidity = Duration(minutes: 10);

  final JsonLoader _loader;
  List<UserRecord>? _users;

  /// Pending one-time codes by email, with their expiry.
  final _otps = <String, ({String code, DateTime expiresAt})>{};

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<UserRecord>> users() async {
    if (_users != null) return _users!;
    final seeded = (await _loader.loadList(
      'users.json',
    )).map(UserRecord.fromJson);
    final stored = (await _prefs).getString(registeredUsersKey);
    final registered = stored == null
        ? const <UserRecord>[]
        : (jsonDecode(stored) as List)
              .cast<Map<String, dynamic>>()
              .map(UserRecord.fromJson)
              .toList();
    final storedIds = registered.map((u) => u.user.id).toSet();
    return _users = [
      ...seeded.where((u) => !storedIds.contains(u.user.id)),
      ...registered,
    ];
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

  /// Saves users that differ from the seeded `users.json` (newly registered
  /// users, and seeded users whose password was reset).
  Future<void> _persistRegistered() async {
    final seeded = {
      for (final u in await _loader.loadList('users.json'))
        u['id']: u['password'],
    };
    final registered = (await users())
        .where(
          (u) =>
              !seeded.containsKey(u.user.id) || seeded[u.user.id] != u.password,
        )
        .map((u) => u.toJson())
        .toList();
    await (await _prefs).setString(registeredUsersKey, jsonEncode(registered));
  }

  @override
  Future<AppUser> login(String email, String password) async {
    final record = await findByEmail(email);
    if (record == null || record.password != password) {
      throw const AuthException('Incorrect email or password.');
    }
    await startSession(record.user);
    return record.user;
  }

  @override
  Future<void> sendOtp(String email) async {
    final record = await findByEmail(email);
    if (record == null) {
      throw const AuthException('No account found for this email.');
    }
    // A real backend would email a random code; the mock uses otp.json.
    final code = (await _loader.loadMap('otp.json'))['mockOtp'] as String;
    _otps[record.user.email] = (
      code: code,
      expiresAt: DateTime.now().add(otpValidity),
    );
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    await _checkOtp(email, otp);
  }

  @override
  Future<AppUser> loginWithOtp(String email, String otp) async {
    final record = await _checkOtp(email, otp);
    _otps.remove(record.user.email);
    await startSession(record.user);
    return record.user;
  }

  @override
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final record = await _checkOtp(email, otp);
    _otps.remove(record.user.email);
    record.password = newPassword;
    await _persistRegistered();
  }

  Future<UserRecord> _checkOtp(String email, String otp) async {
    final record = await findByEmail(email);
    final pending = record == null ? null : _otps[record.user.email];
    if (record == null || pending == null) {
      throw const AuthException('Request a new code first.');
    }
    if (DateTime.now().isAfter(pending.expiresAt)) {
      _otps.remove(record.user.email);
      throw const AuthException('This code has expired. Request a new one.');
    }
    if (pending.code != otp.trim()) {
      throw const AuthException('Incorrect code.');
    }
    return record;
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
