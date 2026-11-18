import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../institutions/institution_providers.dart';
import '../auth_providers.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _rank = TextEditingController();
  UserRole _role = UserRole.student;
  String? _stateId;
  String? _courseId;
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _rank]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            RegisterRequest(
              name: _name.text,
              email: _email.text,
              password: _password.text,
              role: _role,
              stateId: _stateId!,
              courseId: _courseId!,
              aiRank: int.tryParse(_rank.text.trim()),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please log in.')),
      );
      context.go(Routes.login);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final states = ref.watch(statesProvider).value ?? const [];
    final courses = ref.watch(coursesProvider).value ?? const [];

    return AuthLayout(
      title: 'Create your account',
      subtitle: 'We use your state and department to suggest institutions.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('I am a', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<UserRole>(
              segments: [
                for (final r in UserRole.values)
                  ButtonSegment(
                    value: r,
                    label: Text(r.label),
                    icon: Icon(
                      r == UserRole.student
                          ? Icons.school_outlined
                          : Icons.medical_services_outlined,
                    ),
                  ),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              validator: Validators.confirm(() => _password.text),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _stateId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'State'),
              items: [
                for (final s in states)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _stateId = v),
              validator: (v) => v == null ? 'Select your state' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Preferred department',
              ),
              items: [
                for (final c in courses)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${c.name} (${c.degree})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _courseId = v),
              validator: (v) => v == null ? 'Select a department' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rank,
              decoration: const InputDecoration(
                labelText: 'All-India rank (optional)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.optionalRank,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(Routes.login),
              child: const Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
