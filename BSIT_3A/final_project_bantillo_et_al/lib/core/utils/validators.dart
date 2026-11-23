// Shared form validators. Each returns null when valid or an error message
// when invalid, so they plug straight into TextFormField.validator.
//
// Example:
//   validator: Validators.combine([
//     (v) => Validators.required(v, fieldName: 'Waist'),
//     (v) => Validators.numberRange(v, min: 15, max: 70, fieldName: 'Waist'),
//   ]),
//
// OWNER: team lead. Change only via a reviewed PR.

/// Reusable validation functions.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Philippine mobile: 09XXXXXXXXX or +639XXXXXXXXX.
  static final RegExp _phPhonePattern = RegExp(r'^(09|\+639)\d{9}$');

  /// Fails when the value is null or only whitespace.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required.';
    return null;
  }

  /// Required + basic email format.
  static String? email(String? value) {
    final missing = required(value, fieldName: 'Email');
    if (missing != null) return missing;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Philippine mobile number. Spaces and dashes are ignored.
  /// When [isRequired] is false, an empty value is accepted.
  static String? phone(String? value, {bool isRequired = true}) {
    final cleaned = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.isEmpty) {
      return isRequired ? 'Mobile number is required.' : null;
    }
    if (!_phPhonePattern.hasMatch(cleaned)) {
      return 'Use 09XXXXXXXXX or +639XXXXXXXXX.';
    }
    return null;
  }

  /// A number between [min] and [max] inclusive (e.g. measurements in
  /// inches, prices in pesos).
  static String? numberRange(
    String? value, {
    required num min,
    required num max,
    String fieldName = 'Value',
    bool isRequired = true,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return isRequired ? '$fieldName is required.' : null;
    final number = num.tryParse(text);
    if (number == null) return '$fieldName must be a number.';
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max.';
    }
    return null;
  }

  /// Password with a minimum length.
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  /// Runs [validators] in order and returns the first error.
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validate in validators) {
        final error = validate(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
