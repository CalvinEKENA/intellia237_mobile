import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/mobile_money_models.dart';

abstract class MobileMoneyRepository {
  Future<MobileMoneyOverview> fetchParentOverview();

  Future<void> submitPayment({
    required String offerId,
    required String operatorCode,
    required String payerPhone,
    required String transactionReference,
    required String clientRequestId,
  });

  Future<List<AdminPaymentRequest>> fetchAdminQueue();

  Future<void> reviewPayment({
    required String requestId,
    required bool approved,
    String? reviewNote,
  });
}

class FirebaseMobileMoneyRepository implements MobileMoneyRepository {
  FirebaseMobileMoneyRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<MobileMoneyOverview> fetchParentOverview() async {
    try {
      final result = await _functions
          .httpsCallable('getMobileMoneyOverview')
          .call<Map<String, dynamic>>();
      return MobileMoneyOverview.fromMap(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw MobileMoneyException(error.code);
    }
  }

  @override
  Future<void> submitPayment({
    required String offerId,
    required String operatorCode,
    required String payerPhone,
    required String transactionReference,
    required String clientRequestId,
  }) async {
    try {
      await _functions.httpsCallable('submitMobileMoneyPayment').call<void>({
        'offerId': offerId,
        'operatorCode': operatorCode,
        'payerPhone': payerPhone,
        'transactionReference': transactionReference,
        'clientRequestId': clientRequestId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw MobileMoneyException(error.code);
    }
  }

  @override
  Future<List<AdminPaymentRequest>> fetchAdminQueue() async {
    try {
      final result = await _functions
          .httpsCallable('listMobileMoneyPayments')
          .call<Map<String, dynamic>>({'status': 'pending'});
      final raw = result.data['requests'];
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map)
            AdminPaymentRequest.fromMap(Map<String, dynamic>.from(item)),
      ];
    } on FirebaseFunctionsException catch (error) {
      throw MobileMoneyException(error.code);
    }
  }

  @override
  Future<void> reviewPayment({
    required String requestId,
    required bool approved,
    String? reviewNote,
  }) async {
    try {
      await _functions.httpsCallable('reviewMobileMoneyPayment').call<void>({
        'requestId': requestId,
        'decision': approved ? 'approved' : 'rejected',
        if (reviewNote != null && reviewNote.trim().isNotEmpty)
          'reviewNote': reviewNote.trim(),
      });
    } on FirebaseFunctionsException catch (error) {
      throw MobileMoneyException(error.code);
    }
  }
}

class MobileMoneyException implements Exception {
  const MobileMoneyException(this.code);

  final String code;

  @override
  String toString() => code;
}

String newMobileMoneyRequestId() {
  final random = Random.secure().nextInt(1 << 32).toRadixString(16);
  return 'mm_${DateTime.now().microsecondsSinceEpoch}_$random';
}
