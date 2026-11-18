import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../auth_providers.dart';
import 'widgets/otp_section.dart';

/// Second step of "Log in with email OTP".
class OtpPage extends ConsumerWidget {
  const OtpPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authControllerProvider.notifier);
    return AuthLayout(
      title: 'Check your email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OtpSection(
            email: email,
            verifyLabel: 'Log in',
            // On success the router redirects to the dashboard.
            onVerify: (code) => auth.loginWithOtp(email, code),
            onResend: () => auth.sendOtp(email),
          ),
          TextButton(
            onPressed: () => context.go(Routes.login),
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
