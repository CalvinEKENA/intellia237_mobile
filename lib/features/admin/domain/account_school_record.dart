import 'admin_models.dart';
import '../../auth/domain/cameroon_phone_number.dart';

/// Un compte retrouvé par l'administration générale pour lui donner, ou lui
/// corriger, son école.
///
/// L'école déclarée à l'inscription reste une indication : c'est la famille qui
/// l'a saisie, parfois par erreur. Seule [establishmentId] fait autorité.
class AccountSchoolRecord {
  const AccountSchoolRecord({
    required this.id,
    required this.fullName,
    required this.role,
    this.email = '',
    this.phone = '',
    this.establishmentId,
    this.establishmentName = '',
    this.declaredSchoolName = '',
    this.declaredSchoolCity = '',
    this.children = const [],
    this.accountStatus = 'active',
  });

  final String id;
  final String fullName;
  final AdminRoleType role;
  final String email;
  final String phone;
  final String accountStatus;
  final String? establishmentId;
  final String establishmentName;
  final String declaredSchoolName;
  final String declaredSchoolCity;

  /// Les enfants liés d'un parent, pour corriger l'école de l'un d'eux sans
  /// connaître son propre numéro.
  final List<AccountSchoolRecord> children;

  bool get hasSchool => establishmentId != null;
}

/// Un numéro sous la forme enregistrée à la connexion (+237…), ou null.
///
/// On accepte ce qu'un administrateur tape vraiment : espaces, tirets,
/// indicatif absent, « 00 » au lieu de « + ».
String? normalizeCameroonPhone(String raw) {
  final compact = raw.replaceAll(RegExp(r'[\s().-]'), '');
  if (compact.isEmpty) return null;
  // Mobile camerounais : le normaliseur unique de l'authentification, pour
  // retrouver exactement la forme enregistrée à la connexion.
  try {
    return CameroonPhoneNumber.normalize(compact);
  } on PhoneNumberFormatException {
    // Fixe ou numéro étranger : recherche d'un compte existant seulement.
  }
  final international = compact.startsWith('+') || compact.startsWith('00');
  final digits = compact.startsWith('+')
      ? compact.substring(1)
      : compact.startsWith('00')
      ? compact.substring(2)
      : compact;
  if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
  if (digits.length == 9 && digits.startsWith('2')) {
    return '${CameroonPhoneNumber.countryCode}$digits';
  }
  if (digits.length == 12 && digits.startsWith('237')) return '+$digits';
  // Un numéro étranger saisi avec son indicatif reste tel quel.
  if (international && digits.length >= 8 && digits.length <= 15) {
    return '+$digits';
  }
  return null;
}
