import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/domain/app_role.dart';

class EditableProfile {
  const EditableProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.photoUrl,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
}

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<EditableProfile> fetch(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    final data = snapshot.data();
    if (data == null) {
      throw const ProfileUpdateException(
        'Le profil est introuvable. Reconnecte-toi puis réessaie.',
      );
    }
    return EditableProfile(
      firstName: _string(data['firstName']),
      lastName: _string(data['lastName']),
      email: _string(data['email']).isNotEmpty
          ? _string(data['email'])
          : (_auth.currentUser?.email ?? ''),
      phoneNumber: _string(data['phoneNumber']),
      photoUrl: _nullableString(data['photoUrl']),
    );
  }

  Future<void> update({
    required String userId,
    required AppRole role,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanPhone = normalizeCameroonPhone(phoneNumber);
    final validation = validateProfileFields(
      firstName: cleanFirstName,
      lastName: cleanLastName,
      phoneNumber: cleanPhone,
    );
    if (validation != null) throw ProfileUpdateException(validation);

    final batch = _firestore.batch();
    final values = <String, Object>{
      'firstName': cleanFirstName,
      'lastName': cleanLastName,
      'phoneNumber': cleanPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.update(_firestore.collection('users').doc(userId), values);

    // Ce miroir existe déjà dans le modèle élève et ses règles autorisent
    // uniquement ces champs éditoriaux. Les profils staff restent pilotés par
    // l'établissement : leur identité publique vient de users/{uid}.
    if (role == AppRole.student) {
      batch.update(_firestore.collection('student_profiles').doc(userId), {
        'firstName': cleanFirstName,
        'lastName': cleanLastName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      await _auth.currentUser?.updateDisplayName(
        '$cleanFirstName $cleanLastName'.trim(),
      );
    } on FirebaseException catch (error) {
      throw ProfileUpdateException(_messageForCode(error.code));
    }
  }

  static String _string(Object? value) => value is String ? value.trim() : '';

  static String? _nullableString(Object? value) {
    final result = _string(value);
    return result.isEmpty ? null : result;
  }

  static String _messageForCode(String code) => switch (code) {
    'permission-denied' => 'Cette modification n’est pas autorisée.',
    'unavailable' => 'Le réseau est indisponible. Réessaie plus tard.',
    _ => 'Le profil n’a pas pu être enregistré pour le moment.',
  };
}

String normalizeCameroonPhone(String value) {
  var digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('00237')) digits = '+237${digits.substring(5)}';
  if (digits.startsWith('237') && !digits.startsWith('+')) digits = '+$digits';
  if (RegExp(r'^6\d{8}$').hasMatch(digits)) digits = '+237$digits';
  return digits;
}

String? validateProfileFields({
  required String firstName,
  required String lastName,
  required String phoneNumber,
}) {
  if (firstName.length < 2 || firstName.length > 60) {
    return 'Le prénom doit contenir entre 2 et 60 caractères.';
  }
  if (lastName.length < 2 || lastName.length > 60) {
    return 'Le nom doit contenir entre 2 et 60 caractères.';
  }
  if (phoneNumber.isNotEmpty &&
      !RegExp(r'^\+2376\d{8}$').hasMatch(phoneNumber)) {
    return 'Saisis un numéro camerounais valide, par exemple 6 99 00 00 00.';
  }
  return null;
}

class ProfileUpdateException implements Exception {
  const ProfileUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
