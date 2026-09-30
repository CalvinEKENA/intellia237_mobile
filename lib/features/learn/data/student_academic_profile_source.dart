import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentAcademicProfileSourceProvider =
    Provider<StudentAcademicProfileSource>((ref) {
      return FirebaseStudentAcademicProfileSource();
    });

abstract interface class StudentAcademicProfileSource {
  Future<Map<String, dynamic>> fetch(String uid);
}

/// Source capable de rendre, sans réseau, le dernier profil lu sur cet
/// appareil (null s'il n'y en a pas).
abstract interface class CachedStudentAcademicProfileSource {
  Future<Map<String, dynamic>?> fetchCached(String uid);
}

enum AcademicProfileFailureKind {
  missing,
  permission,
  network,
  appCheck,
  invalid,
  unknown,
}

class AcademicProfileException implements Exception {
  const AcademicProfileException({
    required this.kind,
    required this.normalizedErrorCode,
    required this.diagnosticId,
  });

  final AcademicProfileFailureKind kind;
  final String normalizedErrorCode;
  final String diagnosticId;

  @override
  String toString() => diagnosticId;
}

class FirebaseStudentAcademicProfileSource
    implements
        StudentAcademicProfileSource,
        CachedStudentAcademicProfileSource {
  FirebaseStudentAcademicProfileSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Le cache local de Firestore (persistance activée par défaut sur
  /// mobile) : quelques millisecondes, aucune attente réseau.
  @override
  Future<Map<String, dynamic>?> fetchCached(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('student_profiles')
          .doc(uid)
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 1));
      return snapshot.data();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> fetch(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('student_profiles')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final data = snapshot.data();
      if (data == null) {
        throw const AcademicProfileException(
          kind: AcademicProfileFailureKind.missing,
          normalizedErrorCode: 'profile-missing',
          diagnosticId: 'ACADEMIC-PROFILE-201',
        );
      }
      return data;
    } on AcademicProfileException {
      rethrow;
    } on FirebaseException catch (error) {
      final code = error.code.toLowerCase().replaceAll('_', '-');
      final source = '$code ${error.message ?? ''}'.toLowerCase();
      if (source.contains('app-check') || source.contains('app check')) {
        throw const AcademicProfileException(
          kind: AcademicProfileFailureKind.appCheck,
          normalizedErrorCode: 'app-check',
          diagnosticId: 'ACADEMIC-APP-CHECK-204',
        );
      }
      if (code == 'permission-denied') {
        throw const AcademicProfileException(
          kind: AcademicProfileFailureKind.permission,
          normalizedErrorCode: 'permission-denied',
          diagnosticId: 'ACADEMIC-PERM-202',
        );
      }
      if ({
        'unavailable',
        'deadline-exceeded',
        'network-request-failed',
      }.contains(code)) {
        throw AcademicProfileException(
          kind: AcademicProfileFailureKind.network,
          normalizedErrorCode: code,
          diagnosticId: 'ACADEMIC-NET-203',
        );
      }
      throw AcademicProfileException(
        kind: AcademicProfileFailureKind.unknown,
        normalizedErrorCode: code,
        diagnosticId: 'ACADEMIC-UNKNOWN-299',
      );
    } on TimeoutException {
      throw const AcademicProfileException(
        kind: AcademicProfileFailureKind.network,
        normalizedErrorCode: 'timeout',
        diagnosticId: 'ACADEMIC-NET-203',
      );
    }
  }
}
