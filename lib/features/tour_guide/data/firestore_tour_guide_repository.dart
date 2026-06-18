import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tour_guide_repository.dart';

final tourGuideRepositoryProvider = Provider<TourGuideRepository>((ref) {
  try {
    return FirestoreTourGuideRepository(firestore: FirebaseFirestore.instance);
  } catch (_) {
    // Fallback local si Firebase n'est pas pret/disponible.
    return LocalTourGuideRepository();
  }
});

class FirestoreTourGuideRepository implements TourGuideRepository {
  FirestoreTourGuideRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';

  @override
  Future<bool> hasSeenTour(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKey(uid);

    final cached = prefs.getBool(cacheKey);
    if (cached == true) {
      return true;
    }

    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();
      final data = snapshot.data();
      final remoteSeen = data?['tourGuideSeen'] as bool? ?? false;

      if (remoteSeen) {
        await prefs.setBool(cacheKey, true);
      }

      return remoteSeen;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markTourSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheKey(uid), true);

    try {
      await _firestore.collection(_usersCollection).doc(uid).set(
        <String, dynamic>{
          'tourGuideSeen': true,
          'updatedAt': DateTime.now().toUtc(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Le cache local reste prioritaire en mode degrade.
    }
  }

  String _cacheKey(String uid) => 'edunova_tour_seen_$uid';
}

class LocalTourGuideRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cacheKey(uid)) ?? false;
  }

  @override
  Future<void> markTourSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheKey(uid), true);
  }

  String _cacheKey(String uid) => 'edunova_tour_seen_$uid';
}
