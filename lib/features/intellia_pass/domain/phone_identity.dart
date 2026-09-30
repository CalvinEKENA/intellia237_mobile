import '../../auth/domain/cameroon_phone_number.dart' as auth;

/// Numéro du parent pour l'OTP : toujours le normaliseur unique de
/// l'authentification (mobile camerounais, E.164), jamais un second.
class CameroonPhoneNumber {
  const CameroonPhoneNumber._(this.e164);

  final String e164;

  static CameroonPhoneNumber? tryParse(String input) {
    try {
      return CameroonPhoneNumber._(auth.CameroonPhoneNumber.normalize(input));
    } on auth.PhoneNumberFormatException {
      return null;
    }
  }
}

class ParentContactIdentity {
  const ParentContactIdentity({required this.phone, this.email});

  final CameroonPhoneNumber phone;
  final String? email;

  bool get hasOptionalRecoveryEmail => email?.trim().isNotEmpty ?? false;
}
