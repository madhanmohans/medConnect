import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../auth_providers.dart';
import '../domain/app_user.dart';
import 'widgets/otp_section.dart';

enum _Step { email, otp, newPassword }

/// Email → one-time code → new password.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _Step _step = _Step.email;
  String _otp = '';
  bool _busy = false;
  String? _error;

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _sendCode() {
    if (!_formKey.currentState!.validate()) return;
    _run(() async {
      await _auth.sendOtp(_email.text.trim());
      setState(() => _step = _Step.otp);
    });
  }

  void _savePassword() {
    if (!_formKey.currentState!.validate()) return;
    _run(() async {
      await _auth.resetPassword(_email.text.trim(), _otp, _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please log in.')),
      );
      context.go(Routes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = _email.text.trim();
    final (title, body) = switch (_step) {
      _Step.email => ('Reset your password', _emailStep()),
      _Step.otp => (
        'Verify it\'s you',
        OtpSection(
          email: email,
          verifyLabel: 'Continue',
          onVerify: (code) async {
            await _auth.verifyOtp(email, code);
            setState(() {
              _otp = code;
              _step = _Step.newPassword;
            });
          },
          onResend: () => _auth.sendOtp(email),
        ),
      ),
      _Step.newPassword => ('Choose a new password', _passwordStep()),
    };

    return AuthLayout(
      title: title,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            body,
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(Routes.login),
              child: const Text('Back to log in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('We\'ll email you a one-time code.'),
      const SizedBox(height: 16),
      TextFormField(
        controller: _email,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
        validator: Validators.email,
        onFieldSubmitted: (_) => _sendCode(),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _sendCode,
        child: const Text('Send code'),
      ),
    ],
  );

  Widget _passwordStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'New password',
          helperText: 'At least 8 characters',
        ),
        validator: Validators.password,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _confirm,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Confirm new password'),
        validator: Validators.confirm(() => _password.text),
        onFieldSubmitted: (_) => _savePassword(),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _savePassword,
        child: const Text('Update password'),
      ),
    ],
  );
}
