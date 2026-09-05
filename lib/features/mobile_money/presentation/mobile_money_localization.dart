import 'package:flutter/material.dart';

import '../../../core/localization/localization_extensions.dart';
import '../data/mobile_money_repository.dart';
import '../domain/mobile_money_models.dart';

String mobileMoneyErrorMessage(BuildContext context, Object error) {
  if (error is! MobileMoneyException) {
    return context.l10n.mobileMoneyGenericError;
  }
  return switch (error.code) {
    'already-exists' => context.l10n.mobileMoneyReferenceAlreadySubmitted,
    'failed-precondition' => context.l10n.mobileMoneyOfferNoLongerAvailable,
    'permission-denied' => context.l10n.mobileMoneyPermissionDenied,
    'invalid-argument' => context.l10n.mobileMoneyInvalidDetails,
    'unavailable' ||
    'deadline-exceeded' => context.l10n.mobileMoneyTemporarilyUnavailable,
    _ => context.l10n.mobileMoneyGenericError,
  };
}

String mobileMoneyStatusLabel(
  BuildContext context,
  MobileMoneyPaymentStatus status,
) => switch (status) {
  MobileMoneyPaymentStatus.pending => context.l10n.paymentPendingReview,
  MobileMoneyPaymentStatus.approved => context.l10n.paymentApproved,
  MobileMoneyPaymentStatus.rejected => context.l10n.paymentRejected,
};
