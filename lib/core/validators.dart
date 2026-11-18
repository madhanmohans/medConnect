abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return v.length < 8 ? 'Use at least 8 characters' : null;
  }

  static String? Function(String?) confirm(String Function() original) =>
      (v) => v != original() ? 'Passwords do not match' : null;

  /// Optional positive integer (e.g. AI rank).
  static String? optionalRank(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    return (n == null || n < 1) ? 'Enter a valid rank' : null;
  }

  static String? rank(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Rank is required' : optionalRank(v);
}
