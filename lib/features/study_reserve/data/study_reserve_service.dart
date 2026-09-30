import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/study_reserve.dart';

/// Lit la réserve d'étude product-safe depuis le callable serveur.
///
/// [studentId] null → sa propre réserve (élève). Un parent passe l'UID d'un
/// enfant **lié** ; le serveur refuse tout élève non lié.
class StudyReserveService {
  StudyReserveService({FirebaseFunctions? functions}) : _override = functions;

  final FirebaseFunctions? _override;

  FirebaseFunctions get _functions =>
      _override ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<StudyReserve> fetch({String? studentId}) async {
    final response = await _functions
        .httpsCallable('getStudyReserve')
        .call<dynamic>(<String, dynamic>{'studentId': ?studentId});
    final data = Map<String, dynamic>.from(response.data as Map);
    return StudyReserve.fromMap(studentId ?? '', data);
  }
}

final studyReserveServiceProvider = Provider<StudyReserveService>(
  (ref) => StudyReserveService(),
);

/// Réserve d'un élève. `null` = l'élève courant ; sinon un enfant lié (parent).
/// Chaque enfant a sa propre réserve — aucune agrégation au foyer.
final studyReserveProvider = FutureProvider.family<StudyReserve, String?>(
  (ref, studentId) =>
      ref.watch(studyReserveServiceProvider).fetch(studentId: studentId),
);
