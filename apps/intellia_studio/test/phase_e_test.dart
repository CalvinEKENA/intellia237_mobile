import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/core/navigation/studio_navigation.dart';
import 'package:intellia_studio/features/audit/presentation/audit_log_screen.dart';

void main() {
  group('Phase E: Audit & Security Contracts (account_management_audit)', () {
    test(
      'StudioAuditEvent models an immutable audit entry with required motif',
      () {
        const event = StudioAuditEvent(
          id: 'aud_01',
          timestamp: '2026-03-15 08:35:12',
          actorUid: 'usr_admin_01',
          actorRole: 'superAdmin',
          action: 'APPROVE_PAYMENT',
          targetResourceId: 'pay_req_01',
          reason:
              'Validation virement Orange Money vérifié sur relevé bancaire',
          ipAddress: '102.244.155.10',
        );

        expect(event.actorUid, 'usr_admin_01');
        expect(event.action, 'APPROVE_PAYMENT');
        expect(event.reason.isNotEmpty, isTrue);
        expect(event.ipAddress, '102.244.155.10');
      },
    );
  });

  group('Phase E: Full 31 Modules Navigation Completeness', () {
    test(
      'All 31 canonical StudioModule entries are defined and partitioned into sections',
      () {
        expect(StudioModule.values.length, 31);

        // Verify sections distribution
        final orgModules = StudioModule.values
            .where((m) => m.section == StudioSection.organization)
            .toList();
        final contentModules = StudioModule.values
            .where((m) => m.section == StudioSection.content)
            .toList();
        final financeModules = StudioModule.values
            .where((m) => m.section == StudioSection.finance)
            .toList();
        final operationsModules = StudioModule.values
            .where((m) => m.section == StudioSection.operations)
            .toList();
        final systemModules = StudioModule.values
            .where((m) => m.section == StudioSection.system)
            .toList();

        expect(orgModules.length, greaterThanOrEqualTo(3));
        expect(contentModules.length, greaterThanOrEqualTo(7));
        expect(financeModules.length, greaterThanOrEqualTo(3));
        expect(operationsModules.length, greaterThanOrEqualTo(4));
        expect(systemModules.length, greaterThanOrEqualTo(5));
      },
    );

    test('Detail routes and top-level routes have valid path patterns', () {
      for (final module in StudioModule.values) {
        expect(module.path, startsWith('/'));
        expect(module.title.isNotEmpty, isTrue);
      }

      // Explicit verification of key detail routes
      expect(StudioModule.establishmentDetail.path, '/establishments/:id');
      expect(StudioModule.studentDetail.path, '/students/:id');
      expect(StudioModule.parentDetail.path, '/parents/:id');
      expect(StudioModule.lessonEditor.path, '/content/lesson/:id');
      expect(StudioModule.mobileRelease.path, '/mobile-release');
    });
  });
}
