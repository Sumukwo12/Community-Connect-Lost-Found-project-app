/// Form validation utilities for Community Connect
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'This field']) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters.';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String fieldName = 'This field']) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must not exceed $max characters.';
    }
    return null;
  }

  static String? date(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required.';
    }
    try {
      final date = DateTime.parse(value.trim());
      if (date.isAfter(DateTime.now())) {
        return 'Date cannot be in the future.';
      }
    } catch (_) {
      return 'Please enter a valid date.';
    }
    return null;
  }

  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final v in validators) {
      final result = v(value);
      if (result != null) return result;
    }
    return null;
  }
}
