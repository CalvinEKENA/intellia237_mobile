class CameroonPhoneNumber {
  const CameroonPhoneNumber._();

  static const countryCode = '+237';

  /// Normalizes the usual local and international Cameroon forms to E.164.
  ///
  /// Accepted examples: `6 99 12 34 56`, `237699123456`,
  /// `00237 699 12 34 56` and `+237699123456`.
  static String normalize(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('237')) digits = digits.substring(3);

    if (!RegExp(r'^6\d{8}$').hasMatch(digits)) {
      throw const PhoneNumberFormatException();
    }
    return '$countryCode$digits';
  }

  static String localDigits(String raw) {
    try {
      return normalize(raw).substring(countryCode.length);
    } on PhoneNumberFormatException {
      return raw.replaceAll(RegExp(r'\D'), '');
    }
  }
}

class PhoneNumberFormatException implements FormatException {
  const PhoneNumberFormatException();

  @override
  String get message => 'invalid-cameroon-phone';

  @override
  int? get offset => null;

  @override
  dynamic get source => null;

  @override
  String toString() => message;
}
