/// Client-side university-domain check.
///
/// NOTE: this is a UX convenience, NOT a security boundary. Anyone can call
/// the Firebase Auth REST API directly with any email and skip this check
/// entirely. See README ("Why the domain check is not security").
class EmailDomainValidator {
  EmailDomainValidator._();

  /// Accepts `@iba.edu.pk` and any subdomain such as `@khi.iba.edu.pk`.
  static const String allowedDomain = 'iba.edu.pk';

  static final RegExp _basicEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isAllowed(String email) {
    final e = email.trim().toLowerCase();
    if (!_basicEmail.hasMatch(e)) return false;
    final domain = e.split('@').last;
    return domain == allowedDomain || domain.endsWith('.$allowedDomain');
  }

  /// Returns an error message for a form field, or null when valid.
  static String? validate(String? email) {
    if (email == null || email.trim().isEmpty) return 'Email is required';
    if (!_basicEmail.hasMatch(email.trim())) return 'Enter a valid email';
    if (!isAllowed(email)) return 'Only @$allowedDomain emails are allowed';
    return null;
  }
}
