import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/family_access_models.dart';

/// Accès famille, autoritaire côté serveur : aucun code, aucune empreinte ni
/// aucun lien n'est lu ou écrit directement dans Firestore par l'application.
abstract class FamilyAccessRepository {
  /// Échange un code d'accès contre une session Firebase de l'élève.
  Future<void> signInWithStudentAccessCode(String code);

  /// Émet un nouveau code d'accès pour [studentId] ; l'ancien cesse de
  /// fonctionner. Réservé au parent lié, à la direction de l'école de
  /// l'élève et à la super-administration.
  Future<IssuedStudentAccessCode> issueStudentAccessCode(String studentId);

  /// Cède le téléphone vérifié de l'élève au parent (confirmation explicite).
  Future<FamilyPhoneMigrationResult> migrateStudentPhoneToParent();

  /// Ouvre la session du parent à partir du jeton renvoyé par la migration.
  Future<void> signInWithCustomToken(String token);

  /// Enfants liés au parent connecté, avec école, accès et abonnement.
  Future<List<ParentChildSummary>> listParentChildren({String? parentUid});

  /// Nouvelle famille, enfant sans téléphone : le parent ouvre l'accès
  /// INTELLIA de son enfant et reçoit son code une seule fois.
  Future<CreatedChildAccess> createChildStudentAccess(String firstName);
}

class FirebaseFamilyAccessRepository implements FamilyAccessRepository {
  FirebaseFamilyAccessRepository({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  @override
  Future<void> signInWithStudentAccessCode(String code) async {
    final data = await _call('signInWithStudentAccessCode', {
      'code': StudentAccessCodeFormat.normalize(code),
    });
    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw const FamilyAccessException('internal');
    }
    await signInWithCustomToken(token);
  }

  @override
  Future<IssuedStudentAccessCode> issueStudentAccessCode(
    String studentId,
  ) async {
    final data = await _call('issueStudentAccessCode', {
      'studentId': studentId,
    });
    final code = data['code'];
    if (code is! String || code.isEmpty) {
      throw const FamilyAccessException('internal');
    }
    final issuedAt = data['issuedAt'];
    return IssuedStudentAccessCode(
      code: code,
      issuedAt: issuedAt is String ? DateTime.tryParse(issuedAt) : null,
    );
  }

  @override
  Future<FamilyPhoneMigrationResult> migrateStudentPhoneToParent() async {
    final data = await _call('migrateStudentPhoneToParent', {
      'requestId': _uuidV4(),
      'confirmed': true,
    });
    return FamilyPhoneMigrationResult.fromMap(data);
  }

  @override
  Future<void> signInWithCustomToken(String token) async {
    try {
      await _auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (error) {
      throw FamilyAccessException(error.code);
    }
  }

  @override
  Future<List<ParentChildSummary>> listParentChildren({
    String? parentUid,
  }) async {
    final data = await _call('listParentChildren', {'parentUid': ?parentUid});
    final raw = data['children'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          ParentChildSummary.fromMap(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<CreatedChildAccess> createChildStudentAccess(String firstName) async {
    final data = await _call('createChildStudentAccess', {
      'firstName': firstName.trim(),
      'requestId': _uuidV4(),
    });
    return CreatedChildAccess(
      studentId: data['studentId'] is String ? data['studentId'] as String : '',
      firstName: data['firstName'] is String
          ? data['firstName'] as String
          : firstName.trim(),
      code: data['code'] is String ? data['code'] as String : null,
    );
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(payload);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      final map = details is Map
          ? Map<String, dynamic>.from(details)
          : const <String, dynamic>{};
      throw FamilyAccessException(
        error.code,
        reason: map['reason'] is String ? map['reason'] as String : null,
        studentAccessCode: map['studentAccessCode'] is String
            ? map['studentAccessCode'] as String
            : null,
      );
    }
  }
}

/// Identifiant d'idempotence RFC 4122 v4, tiré d'un générateur sûr.
String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
