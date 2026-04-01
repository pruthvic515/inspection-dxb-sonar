/// Shared UAE Emirates ID validation: `784-YYYY-XXXXXXX-X`.
class EmiratesIdValidation {
  EmiratesIdValidation._();

  static final RegExp formattedPattern = RegExp(r'^784-\d{4}-\d{7}-\d{1}$');

  /// Whether [displayedText] matches the official formatted Emirates ID pattern.
  static bool isValid(String displayedText) {
    final trimmed = displayedText.trim();
    if (formattedPattern.hasMatch(trimmed)) {
      return true;
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 15 || !digits.startsWith('784')) {
      return false;
    }
    final formatted =
        '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 14)}-${digits.substring(14, 15)}';
    return formattedPattern.hasMatch(formatted);
  }

  /// Formats 15 digits into `784-YYYY-XXXXXXX-X`.
  static String formatFromDigits(String raw) {
    // ignore: deprecated_member_use
    final id = raw.replaceAll(RegExp(r'\D'), '');
    if (id.length != 15) {
      throw const FormatException(
        'Invalid Emirates ID length. It should be 15 digits.',
      );
    }
    return '${id.substring(0, 3)}-${id.substring(3, 7)}-${id.substring(7, 14)}-${id.substring(14, 15)}';
  }
}
