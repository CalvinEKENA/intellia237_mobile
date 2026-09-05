import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tutor_persona.dart';

final tutorPreferenceRepositoryProvider = Provider<TutorPreferenceRepository>(
  (ref) => TutorPreferenceRepository(),
);

class TutorPreferenceRepository {
  TutorPreferenceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Persists the canonical companion id in the authoritative student profile.
  ///
  /// The public `users` mirror intentionally stays unchanged: Firestore rules
  /// only allow students to edit this preference in `student_profiles`.
  Future<void> save({required String userId, required String tutorId}) async {
    final canonicalId = TutorPersona.resolveId(tutorId);
    try {
      await _firestore.collection('student_profiles').doc(userId).update({
        'tutorId': canonicalId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw TutorPreferenceException(error.code);
    }
  }
}

class TutorPreferenceException implements Exception {
  const TutorPreferenceException(this.code);

  final String code;

  @override
  String toString() => 'TutorPreferenceException($code)';
}
