import 'package:equatable/equatable.dart';

enum UserRole {
  student('Student'),
  resident('Resident');

  const UserRole(this.label);
  final String label;

  static UserRole fromName(String name) =>
      values.firstWhere((r) => r.name == name, orElse: () => student);
}

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.stateId,
    required this.courseId,
    this.aiRank,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.fromName(json['role'] as String),
    stateId: json['stateId'] as String,
    courseId: json['courseId'] as String,
    aiRank: json['aiRank'] as int?,
  );

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Home state, used to personalise the dashboard.
  final String stateId;

  /// Preferred department/course, used to personalise the dashboard.
  final String courseId;

  /// The student's All-India rank, if known.
  final int? aiRank;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'stateId': stateId,
    'courseId': courseId,
    'aiRank': aiRank,
  };

  @override
  List<Object?> get props => [id, name, email, role, stateId, courseId, aiRank];
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
