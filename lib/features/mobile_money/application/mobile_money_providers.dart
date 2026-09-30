import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mobile_money_repository.dart';
import '../domain/mobile_money_models.dart';

final mobileMoneyRepositoryProvider = Provider<MobileMoneyRepository>((ref) {
  return FirebaseMobileMoneyRepository();
});

/// Vue Mobile Money du parent ; la famille est l'enfant choisi (null : aucun
/// enfant nommé, comportement des versions antérieures).
final parentMobileMoneyOverviewProvider =
    FutureProvider.family<MobileMoneyOverview, String?>((
      ref,
      beneficiaryStudentId,
    ) {
      return ref
          .watch(mobileMoneyRepositoryProvider)
          .fetchParentOverview(beneficiaryStudentId: beneficiaryStudentId);
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
    String? beneficiaryStudentId,
    required MobileMoneyOffer offer,
    required MobileMoneyOperator operator,
    required String payerPhone,
    required String transactionReference,
    required String clientRequestId,
  }) async {
    await _ref
        .read(mobileMoneyRepositoryProvider)
        .submitPayment(
          beneficiaryStudentId: beneficiaryStudentId,
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
