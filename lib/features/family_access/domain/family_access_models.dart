/// Accès famille : ce que le serveur dit d'un enfant, d'un code d'accès élève
/// et de la migration du téléphone familial.
///
/// Cinq dimensions restent séparées : identité (UID), méthode d'accès,
/// relation (lien parent approuvé), école de l'enfant, payeur. Aucun modèle
/// ici ne porte un numéro de téléphone ni un code en dehors de l'instant où
/// le serveur le renvoie une seule fois.
library;

/// Code d'accès INTELLIA d'un élève, renvoyé une seule fois à l'émission.
class IssuedStudentAccessCode {
  const IssuedStudentAccessCode({required this.code, this.issuedAt});

  /// Forme lisible `XXXX-XXXX-XXXX`. Jamais stocké, jamais journalisé.
  final String code;
  final DateTime? issuedAt;

  @override
  String toString() => 'IssuedStudentAccessCode(••••)';
}

/// Accès ouvert par un parent pour un enfant sans téléphone.
class CreatedChildAccess {
  const CreatedChildAccess({
    required this.studentId,
    required this.firstName,
    this.code,
  });

  final String studentId;
  final String firstName;

  /// Montré une seule fois ; null sur une réponse rejouée.
  final String? code;

  @override
  String toString() => 'CreatedChildAccess($studentId)';
}

/// Règles de saisie partagées avec le serveur (`studentAccessCode.ts`).
abstract final class StudentAccessCodeFormat {
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const length = 12;

  /// Majuscules, sans espaces ni tirets.
  static String normalize(String input) =>
      input.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '');

  static bool isWellFormed(String input) {
    final code = normalize(input);
    if (code.length != length) return false;
    for (final symbol in code.split('')) {
      if (!alphabet.contains(symbol)) return false;
    }
    return true;
  }

  /// `ABCDEFGHJKMN` → `ABCD-EFGH-JKMN`.
  static String format(String input) {
    final code = normalize(input);
    final groups = <String>[];
    for (var start = 0; start < code.length; start += 4) {
      final end = start + 4 > code.length ? code.length : start + 4;
      groups.add(code.substring(start, end));
    }
    return groups.join('-');
  }
}

/// Issue d'une migration du téléphone familial, côté serveur.
class FamilyPhoneMigrationResult {
  const FamilyPhoneMigrationResult({
    required this.studentId,
    required this.studentFirstName,
    required this.parentUid,
    this.parentToken,
    this.studentAccessCode,
  });

  final String studentId;
  final String studentFirstName;
  final String parentUid;

  /// Jeton personnalisé du parent ; null si la session est déjà la sienne.
  final String? parentToken;

  /// Code d'accès élève émis par cet appel ; null s'il l'a été avant (il
  /// n'est pas stocké : le parent en génère un nouveau depuis la fiche).
  final String? studentAccessCode;

  factory FamilyPhoneMigrationResult.fromMap(Map<String, dynamic> map) =>
      FamilyPhoneMigrationResult(
        studentId: _string(map['studentId']),
        studentFirstName: _string(map['studentFirstName']),
        parentUid: _string(map['parentUid']),
        parentToken: _nullableString(map['parentToken']),
        studentAccessCode: _nullableString(map['studentAccessCode']),
      );

  @override
  String toString() =>
      'FamilyPhoneMigrationResult(studentId: $studentId, parentUid: $parentUid)';
}

/// Échec d'un appel d'accès famille, sans donnée sensible dans le message.
class FamilyAccessException implements Exception {
  const FamilyAccessException(this.code, {this.reason, this.studentAccessCode});

  /// Code Firebase Functions (`permission-denied`, `resource-exhausted`…).
  final String code;

  /// Raison détaillée renvoyée par le serveur (`migration-compensated`…).
  final String? reason;

  /// Code d'accès élève transmis par le serveur quand la migration s'est
  /// arrêtée après l'avoir émis : il ouvre déjà l'espace de l'élève.
  final String? studentAccessCode;

  bool get isUnavailableService =>
      code == 'not-found' || code == 'unimplemented' || code == 'internal';

  @override
  String toString() => 'FamilyAccessException($code, $reason)';
}

/// Comment un enfant se connecte, sans jamais exposer de numéro ni de code.
class ChildAccessMethods {
  const ChildAccessMethods({
    required this.ownPhone,
    required this.accessCode,
    this.accessCodeIssuedAt,
  });

  static const unknown = ChildAccessMethods(ownPhone: false, accessCode: false);

  /// L'enfant se connecte avec son propre téléphone.
  final bool ownPhone;

  /// Un code d'accès INTELLIA est actif pour cet enfant.
  final bool accessCode;
  final DateTime? accessCodeIssuedAt;
}

enum ChildSubscriptionPayer { you, anotherGuardian }

/// Abonnement qui couvre un enfant, résolu comme sa Réserve d'étude.
class ChildSubscription {
  const ChildSubscription({
    required this.active,
    this.endsAt,
    this.offerId,
    this.paidBy,
  });

  static const inactive = ChildSubscription(active: false);

  final bool active;
  final DateTime? endsAt;
  final String? offerId;
  final ChildSubscriptionPayer? paidBy;
}

/// Ce que le serveur projette d'un enfant pour un parent lié.
class ParentChildSummary {
  const ParentChildSummary({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.classLevel,
    required this.establishmentId,
    required this.establishmentName,
    required this.access,
    required this.subscription,
    required this.offerAvailable,
    this.series,
    this.pendingFirstSignIn = false,
  });

  final String studentId;

  /// Accès ouvert par le parent ; l'enfant n'a pas encore rempli son profil.
  final bool pendingFirstSignIn;
  final String firstName;
  final String lastName;
  final String classLevel;
  final String? series;
  final String establishmentId;
  final String establishmentName;
  final ChildAccessMethods access;
  final ChildSubscription subscription;
  final bool offerAvailable;

  factory ParentChildSummary.fromMap(Map<String, dynamic> map) {
    final access = _map(map['access']);
    final subscription = _map(map['subscription']);
    return ParentChildSummary(
      studentId: _string(map['studentId']),
      firstName: _string(map['firstName']),
      lastName: _string(map['lastName']),
      classLevel: _string(map['classLevel']),
      series: _nullableString(map['series']),
      establishmentId: _string(map['establishmentId']),
      establishmentName: _string(map['establishmentName']),
      access: ChildAccessMethods(
        ownPhone: access['ownPhone'] == true,
        accessCode: access['accessCode'] == true,
        accessCodeIssuedAt: _date(access['accessCodeIssuedAt']),
      ),
      subscription: ChildSubscription(
        active: subscription['status'] == 'active',
        endsAt: _date(subscription['endsAt']),
        offerId: _nullableString(subscription['offerId']),
        paidBy: switch (subscription['paidBy']) {
          'you' => ChildSubscriptionPayer.you,
          'another_guardian' => ChildSubscriptionPayer.anotherGuardian,
          _ => null,
        },
      ),
      offerAvailable: map['offerAvailable'] == true,
      pendingFirstSignIn: map['status'] == 'pending_first_sign_in',
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String _string(Object? value) => value is String ? value.trim() : '';

String? _nullableString(Object? value) {
  final string = _string(value);
  return string.isEmpty ? null : string;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;
