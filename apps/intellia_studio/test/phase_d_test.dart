import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/features/finance/domain/finance_models.dart';

void main() {
  group('Phase D: Study Reserve Contracts & Policies', () {
    test(
      'StudioStudyReserve computes consumption ratio and critical status',
      () {
        const reserveNormal = StudioStudyReserve(
          studentId: 'std_01',
          studentName: 'Calvin',
          classLevel: 'Terminale',
          allowanceInternal: 600000,
          consumedInternal: 300000,
          cycleStart: '2026-03-01',
          cycleEnd: '2026-03-31',
        );

        expect(reserveNormal.consumptionRatio, 0.5);
        expect(reserveNormal.consumptionPercent, 50);
        expect(reserveNormal.isCritical, isFalse);

        const reserveCritical = StudioStudyReserve(
          studentId: 'std_02',
          studentName: 'Brenda',
          classLevel: 'Terminale',
          allowanceInternal: 600000,
          consumedInternal: 500000,
          cycleStart: '2026-03-01',
          cycleEnd: '2026-03-31',
          latestThresholdEmitted: '80%',
        );

        expect(reserveCritical.consumptionPercent, 83);
        expect(reserveCritical.isCritical, isTrue);
        expect(reserveCritical.latestThresholdEmitted, '80%');
      },
    );

    test('Zero allowance handled safely without division by zero', () {
      const zeroReserve = StudioStudyReserve(
        studentId: 'std_zero',
        studentName: 'Test',
        classLevel: 'Terminale',
        allowanceInternal: 0,
        consumedInternal: 0,
        cycleStart: '2026-03-01',
        cycleEnd: '2026-03-31',
      );

      expect(zeroReserve.consumptionRatio, 0.0);
      expect(zeroReserve.consumptionPercent, 0);
      expect(zeroReserve.isCritical, isFalse);
    });
  });

  group('Phase D: Mobile Money & Financial Auditing', () {
    test(
      'StudioPaymentRequest accurately formats XAF currency and tracks review metadata',
      () {
        const pendingReq = StudioPaymentRequest(
          id: 'req_01',
          parentId: 'par_01',
          parentName: 'Suzanne Ekena',
          establishmentId: 'est_01',
          amountXaf: 5000,
          operator: PaymentOperator.orangeMoney,
          reference: 'OM-2026-98124',
          phoneNumber: '+237 699 01 23 45',
          status: PaymentRequestStatus.pending,
          createdAt: '2026-03-15 08:30',
        );

        expect(pendingReq.formattedAmount, '5 000 FCFA');
        expect(pendingReq.status, PaymentRequestStatus.pending);
        expect(pendingReq.reviewedAt, isNull);

        const approvedReq = StudioPaymentRequest(
          id: 'req_02',
          parentId: 'par_02',
          parentName: 'Jean Kamga',
          establishmentId: 'est_01',
          amountXaf: 45000,
          operator: PaymentOperator.mtnMomo,
          reference: 'MTN-2026-44321',
          phoneNumber: '+237 677 89 12 34',
          status: PaymentRequestStatus.approved,
          createdAt: '2026-03-14 14:15',
          reviewedAt: '2026-03-14 15:00',
          reviewedByUid: 'adm_01',
        );

        expect(approvedReq.formattedAmount, '45 000 FCFA');
        expect(approvedReq.status, PaymentRequestStatus.approved);
        expect(approvedReq.reviewedByUid, 'adm_01');
      },
    );

    test(
      'LegacyFinancialRecord preserves collection classification and read-only integrity',
      () {
        const legacyCredit = LegacyFinancialRecord(
          id: 'cred_01',
          collectionName: 'Credit',
          userId: 'usr_01',
          rawData: {'balance': 200},
          classification:
              DataCollectionClassification.legacyRequiresClassification,
          timestamp: '2025-08-01',
        );

        expect(legacyCredit.collectionName, 'Credit');
        expect(
          legacyCredit.classification,
          DataCollectionClassification.legacyRequiresClassification,
        );
        expect(legacyCredit.rawData['balance'], 200);
      },
    );

    test(
      'StudioSubscriptionPlan tracks Firestore provisioning status vs fallback',
      () {
        const fallbackPlan = StudioSubscriptionPlan(
          id: 'plan_fallback',
          name: 'Formule Atelier',
          priceXaf: 5000,
          billingPeriod: 'Mensuel',
          features: ['Parcours', 'Kira IA'],
          isProvisionedInFirestore: false,
          establishmentId: 'est_01',
        );

        expect(fallbackPlan.isProvisionedInFirestore, isFalse);
        expect(fallbackPlan.formattedPrice, '5 000 FCFA');
      },
    );
  });
}
