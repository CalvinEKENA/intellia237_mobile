import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mobile_money_repository.dart';
import '../domain/mobile_money_models.dart';

final mobileMoneyRepositoryProvider = Provider<MobileMoneyRepository>((ref) {
  return FirebaseMobileMoneyRepository();
});

final parentMobileMoneyOverviewProvider = FutureProvider<MobileMoneyOverview>((
  ref,
) {
  return ref.watch(mobileMoneyRepositoryProvider).fetchParentOverview();
});

final adminMobileMoneyQueueProvider = FutureProvider<List<AdminPaymentRequest>>(
  (ref) {
    return ref.watch(mobileMoneyRepositoryProvider).fetchAdminQueue();
  },
);

final mobileMoneyActionsProvider = Provider<MobileMoneyActions>((ref) {
  return MobileMoneyActions(ref);
});

class MobileMoneyActions {
  MobileMoneyActions(this._ref);

  final Ref _ref;

  Future<void> submit({
    required MobileMoneyOffer offer,
    required MobileMoneyOperator operator,
    required String payerPhone,
    required String transactionReference,
    required String clientRequestId,
  }) async {
    await _ref
        .read(mobileMoneyRepositoryProvider)
        .submitPayment(
          offerId: offer.id,
          operatorCode: operator.code,
          payerPhone: payerPhone,
          transactionReference: transactionReference,
          clientRequestId: clientRequestId,
        );
    _ref.invalidate(parentMobileMoneyOverviewProvider);
  }

  Future<void> review({
    required String requestId,
    required bool approved,
    String? reviewNote,
  }) async {
    await _ref
        .read(mobileMoneyRepositoryProvider)
        .reviewPayment(
          requestId: requestId,
          approved: approved,
          reviewNote: reviewNote,
        );
    _ref.invalidate(adminMobileMoneyQueueProvider);
  }
}
