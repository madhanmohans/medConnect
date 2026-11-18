import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/app_user.dart';

/// 6-digit code entry with verify button and a resend countdown.
/// [onVerify] and [onResend] may throw [AuthException]; the message is shown.
class OtpSection extends StatefulWidget {
  const OtpSection({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
    this.verifyLabel = 'Verify',
    this.resendAfter = const Duration(seconds: 30),
  });

  final String email;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;
  final String verifyLabel;
  final Duration resendAfter;

  @override
  State<OtpSection> createState() => _OtpSectionState();
}

class _OtpSectionState extends State<OtpSection> {
  final _code = TextEditingController();
  Timer? _timer;
  late int _secondsLeft;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = widget.resendAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
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

  void _verify() {
    if (_code.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    _run(() => widget.onVerify(_code.text));
  }

  void _resend() => _run(() async {
    await widget.onResend();
    _code.clear();
    _startCountdown();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A new code was sent.')));
    }
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: 'Enter the 6-digit code sent to ',
            children: [
              TextSpan(
                text: widget.email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 4),
          Text(
            'Mock mode: the code is 123456 (assets/mock/otp.json).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: InputDecoration(
            labelText: 'One-time code',
            counterText: '',
            errorText: _error,
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _verify,
          child: Text(widget.verifyLabel),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy || _secondsLeft > 0 ? null : _resend,
          child: Text(
            _secondsLeft > 0
                ? 'Resend code in ${_secondsLeft}s'
                : 'Resend code',
          ),
        ),
      ],
    );
  }
}
