class CameroonPhoneNumber {
  const CameroonPhoneNumber._(this.e164);

  final String e164;

  static CameroonPhoneNumber? tryParse(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('00237')) digits = digits.substring(2);
    if (digits.startsWith('237')) digits = digits.substring(3);
    if (!RegExp(r'^[26][0-9]{8}$').hasMatch(digits)) return null;
    return CameroonPhoneNumber._('+237$digits');
  }
}

class ParentContactIdentity {
  const ParentContactIdentity({required this.phone, this.email});

  final CameroonPhoneNumber phone;
  final String? email;

  bool get hasOptionalRecoveryEmail => email?.trim().isNotEmpty ?? false;
}
