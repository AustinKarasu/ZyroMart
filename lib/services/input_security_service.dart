class InputSecurityService {
  static const int nameMaxLength = 60;
  static const int emailMaxLength = 120;
  static const int phoneMaxLength = 20;
  static const int addressMaxLength = 240;
  static const int notesMaxLength = 280;
  static const int couponMaxLength = 32;

  static String sanitizePlainText(
    String input, {
    required int maxLength,
    bool allowNewLines = false,
  }) {
    final normalized = allowNewLines
        ? input.replaceAll('\r', '\n')
        : input.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    final cleaned = normalized
        .replaceAll(RegExp(r'[<>`$\\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    return cleaned.substring(0, maxLength).trim();
  }

  static String sanitizeEmail(String input) {
    return input.trim().toLowerCase();
  }

  static bool isValidEmail(String input) {
    final email = sanitizeEmail(input);
    if (email.isEmpty || email.length > emailMaxLength) return false;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  static String? sanitizePhone(String input) {
    final trimmed = input.trim().replaceAll(' ', '');
    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.length < 10 || cleaned.length > phoneMaxLength) {
      return null;
    }
    return cleaned;
  }

  static bool isSafeCode(String input, {int maxLength = 8}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(trimmed);
  }

  static bool isStrongPassword(String input) {
    if (input.length < 8 || input.length > 64) return false;
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,64}$').hasMatch(input);
  }
}
