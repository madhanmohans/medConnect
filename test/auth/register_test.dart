import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_connect/core/mock/json_loader.dart';
import 'package:med_connect/features/auth/data/mock_auth_repository.dart';
import 'package:med_connect/features/auth/domain/app_user.dart';
import 'package:med_connect/features/auth/domain/auth_repository.dart';
import 'package:med_connect/features/auth/presentation/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

RegisterRequest request(String email) => RegisterRequest(
  name: 'New Student',
  email: email,
  password: 'secret123',
  role: UserRole.resident,
  stateId: 'kl',
  courseId: 'ped',
  aiRank: 4200,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MockAuthRepository.register', () {
    test('creates a user that survives a new repository instance', () async {
      final user = await MockAuthRepository(
        JsonLoader(),
      ).register(request(' New@Example.com '));
      expect(user.email, 'new@example.com');
      expect(user.role, UserRole.resident);

      final fresh = MockAuthRepository(JsonLoader());
      final found = await fresh.findByEmail('new@example.com');
      expect(found?.user, user);
      expect(found?.password, 'secret123');
    });

    test('rejects an email that already exists, case-insensitively', () async {
      final repo = MockAuthRepository(JsonLoader());
      expect(
        () => repo.register(request('STUDENT@medconnect.dev')),
        throwsA(isA<AuthException>()),
      );
    });

    test('does not start a session', () async {
      final repo = MockAuthRepository(JsonLoader());
      await repo.register(request('x@example.com'));
      expect(await repo.currentUser(), isNull);
    });
  });

  testWidgets('register form validates required fields and password match', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: lookupOverrides(),
        child: const MaterialApp(home: RegisterPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Resident'), findsOneWidget);

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Select your state'), findsOneWidget);
    expect(find.text('Select a department'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'password999',
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
