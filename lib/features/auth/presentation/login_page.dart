import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../auth_providers.dart';
import '../domain/app_user.dart';

enum _LoginMode { password, otp }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _LoginMode _mode = _LoginMode.password;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider.notifier);
    final email = _email.text.trim();
    try {
      if (_mode == _LoginMode.password) {
        // On success the router redirects to the dashboard.
        await auth.login(email, _password.text);
      } else {
        await auth.sendOtp(email);
        if (mounted) {
          context.push(
            Uri(path: Routes.otp, queryParameters: {'email': email}).toString(),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPassword = _mode == _LoginMode.password;
    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Log in to find institutions that match your rank.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_LoginMode>(
                segments: const [
                  ButtonSegment(
                    value: _LoginMode.password,
                    label: Text('Password'),
                    icon: Icon(Icons.lock_outline),
                  ),
                  ButtonSegment(
                    value: _LoginMode.otp,
                    label: Text('Email OTP'),
                    icon: Icon(Icons.mark_email_read_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() {
                  _mode = s.first;
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: isPassword
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: Validators.email,
                onFieldSubmitted: isPassword ? null : (_) => _submit(),
              ),
              if (isPassword) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => Validators.required(v, 'Password'),
                  onFieldSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(
                      Uri(
                        path: Routes.forgotPassword,
                        queryParameters: {
                          if (_email.text.trim().isNotEmpty)
                            'email': _email.text.trim(),
                        },
                      ).toString(),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),
              ] else
                const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isPassword ? 'Log in' : 'Send code'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(Routes.register),
                child: const Text("New here? Create an account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
