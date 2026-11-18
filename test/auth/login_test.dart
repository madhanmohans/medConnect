import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_connect/core/mock/json_loader.dart';
import 'package:med_connect/features/auth/auth_providers.dart';
import 'package:med_connect/features/auth/data/mock_auth_repository.dart';
import 'package:med_connect/features/auth/domain/app_user.dart';
import 'package:med_connect/features/auth/presentation/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const email = 'student@medconnect.dev';
const password = 'password123';
const otp = '123456';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MockAuthRepository', () {
    late MockAuthRepository repo;
    setUp(() => repo = MockAuthRepository(JsonLoader()));

    test(
      'password login starts a session that a new instance restores',
      () async {
        final user = await repo.login(' Student@MedConnect.dev ', password);
        expect(user.role, UserRole.student);
        expect(await MockAuthRepository(JsonLoader()).currentUser(), user);
        await repo.logout();
        expect(await repo.currentUser(), isNull);
      },
    );

    test('wrong password or unknown email is rejected', () async {
      expect(() => repo.login(email, 'nope'), throwsA(isA<AuthException>()));
      expect(
        () => repo.login('ghost@x.dev', password),
        throwsA(isA<AuthException>()),
      );
    });

    test('OTP login requires a sent, matching code and consumes it', () async {
      expect(
        () => repo.loginWithOtp(email, otp),
        throwsA(isA<AuthException>()),
      );
      expect(() => repo.sendOtp('ghost@x.dev'), throwsA(isA<AuthException>()));
      await repo.sendOtp(email);
      expect(
        () => repo.loginWithOtp(email, '000000'),
        throwsA(isA<AuthException>()),
      );
      final user = await repo.loginWithOtp(email, otp);
      expect(user.email, email);
      expect(await repo.currentUser(), user);
      expect(
        () => repo.loginWithOtp(email, otp),
        throwsA(isA<AuthException>()),
      );
    });

    test(
      'forgot password: verify keeps the code, reset changes the password',
      () async {
        await repo.sendOtp(email);
        await repo.verifyOtp(email, otp);
        await repo.resetPassword(email, otp, 'brandNew99');
        expect(
          () => repo.login(email, password),
          throwsA(isA<AuthException>()),
        );

        // Survives reload: seeded user's new password is persisted.
        final fresh = MockAuthRepository(JsonLoader());
        expect((await fresh.login(email, 'brandNew99')).email, email);
        expect(
          () => fresh.resetPassword(email, otp, 'again1234'),
          throwsA(isA<AuthException>()),
        );
      },
    );
  });

  test('AuthController reflects login and logout', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(authControllerProvider.future), isNull);
    await container
        .read(authControllerProvider.notifier)
        .login(email, password);
    expect(container.read(authControllerProvider).value?.email, email);
    await container.read(authControllerProvider.notifier).logout();
    expect(container.read(authControllerProvider).value, isNull);
  });

  testWidgets('login page validates and switches to OTP mode', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Email OTP'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Password'), findsNothing);
    expect(find.text('Send code'), findsOneWidget);
  });
}
