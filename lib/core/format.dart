import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _count = NumberFormat.decimalPattern('en_IN');

String formatInr(int amount) => _inr.format(amount);

String formatCount(int n) => _count.format(n);

/// "₹48,600" or "₹3,50,000 – ₹10,50,000".
String formatInrRange(int min, int max) =>
    min == max ? formatInr(min) : '${formatInr(min)} – ${formatInr(max)}';
