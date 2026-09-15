import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Récupère (ou génère) le code de liaison parent de l'élève, via un callable
/// autoritaire côté serveur. Le code est stable et idempotent : le même élève
/// obtient toujours le même code.
class StudentLinkCodeService {
  StudentLinkCodeService({FirebaseFunctions? functions})
    : _override = functions;

  final FirebaseFunctions? _override;

  FirebaseFunctions get _functions =>
      _override ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<String> ensureLinkCode() => _callForCode('ensureStudentLinkCode');

  /// Révoque le code actuel et en génère un nouveau (l'ancien devient invalide).
  Future<String> rotateLinkCode() => _callForCode('rotateStudentLinkCode');

  /// Code de liaison d'un élève désigné, pour un adulte de confiance : parent
  /// déjà lié (second responsable), direction de l'école de l'élève,
  /// super-administration. Le serveur vérifie cette autorisation.
  Future<String> ensureLinkCodeFor(String studentId) =>
      _callForCode('ensureStudentLinkCode', studentId: studentId);

  /// Remplace le code de liaison d'un élève désigné.
  Future<String> rotateLinkCodeFor(String studentId) =>
      _callForCode('rotateStudentLinkCode', studentId: studentId);

  Future<String> _callForCode(String name, {String? studentId}) async {
    final response = await _functions.httpsCallable(name).call<dynamic>(
      <String, dynamic>{'studentId': ?studentId},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['code'] as String?)?.trim() ?? '';
  }
}

final studentLinkCodeServiceProvider = Provider<StudentLinkCodeService>(
  (ref) => StudentLinkCodeService(),
);

/// Code de liaison de l'élève courant, chargé à la demande (généré au besoin).
final studentLinkCodeProvider = FutureProvider.autoDispose<String>((ref) async {
  return ref.read(studentLinkCodeServiceProvider).ensureLinkCode();
});
