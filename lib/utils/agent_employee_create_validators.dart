/// Validation helpers for Agent Employee Create (and similar forms).
class AgentEmployeeCreateValidators {
  AgentEmployeeCreateValidators._();

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validateFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter full name';
    }
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  static String? validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter email';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
