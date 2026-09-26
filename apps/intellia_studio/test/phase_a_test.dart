import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/features/auth/domain/auth_session.dart';
import 'package:intellia_studio/features/auth/domain/rbac_capabilities.dart';
import 'package:intellia_studio/features/control_plane/fake_control_plane_api.dart';
import 'package:intellia_studio/core/navigation/studio_navigation.dart';

void main() {
  group('Phase A: Auth & RBAC Domain Tests', () {
    test('AuthSession accurately parses and identifies SuperAdmin', () {
      final session = AuthSession(
        uid: 'admin_123',
        email: 'admin@intellia.cm',
        displayName: 'Super Admin',
        role: 'superAdmin',
        idToken: 'token_mock',
        refreshToken: 'refresh_mock',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(session.isSuperAdmin, isTrue);
      expect(session.isSchoolAdmin, isFalse);
      expect(session.isExpired, isFalse);

      final rbac = RbacCapabilities.fromSession(session);
      expect(rbac.canViewGlobalDashboard, isTrue);
      expect(rbac.canManageAllEstablishments, isTrue);
      expect(rbac.canManageAccounts, isTrue);
      expect(rbac.canConfigureStudyReserve, isTrue);
      expect(rbac.canViewAuditLog, isTrue);
    });

    test('AuthSession for School Admin restricts global capabilities', () {
      final session = AuthSession(
        uid: 'school_admin_456',
        email: 'principal@school.cm',
        displayName: 'Directeur École',
        role: 'admin',
        establishmentId: 'est_douala_01',
        idToken: 'token_mock',
        refreshToken: 'refresh_mock',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(session.isSuperAdmin, isFalse);
      expect(session.isSchoolAdmin, isTrue);

      final rbac = RbacCapabilities.fromSession(session);
      expect(rbac.canViewGlobalDashboard, isFalse);
      expect(rbac.canManageAllEstablishments, isFalse);
      expect(rbac.canManageOwnEstablishment, isTrue);
      expect(rbac.canManageAccounts, isFalse); // general admin only
      expect(
        rbac.canConfigureStudyReserve,
        isFalse,
      ); // owner/server config only
      expect(rbac.canReviewPayments, isTrue); // establishment scoped
    });

    test('Unauthenticated session grants zero capabilities', () {
      final rbac = RbacCapabilities.fromSession(null);
      expect(rbac.canViewGlobalDashboard, isFalse);
      expect(rbac.canManageOwnEstablishment, isFalse);
      expect(rbac.canReviewPayments, isFalse);
      expect(rbac.canPublishContent, isFalse);
    });
  });

  group('Phase A: Navigation & Module Map Tests', () {
    test('All 31 canonical modules are properly declared and mapped', () {
      expect(StudioModule.values.length, equals(31));
      expect(StudioModule.login.path, equals('/login'));
      expect(StudioModule.dashboard.path, equals('/dashboard'));
      expect(StudioModule.mobileRelease.path, equals('/mobile-release'));
    });
  });

  group('Phase A: Fake Control Plane API Tests', () {
    test(
      'FakeControlPlaneApi executes soft delete with immutable audit log',
      () async {
        final api = FakeControlPlaneApi();
        final result = await api.manageAccount(
          action: 'delete',
          accountId: 'user_target_99',
          reason: 'Archivage demandé par inspection académique',
        );

        expect(result['accountId'], equals('user_target_99'));
        expect(result['status'], equals('deleted'));

        final logs = await api.fetchAuditLogs();
        expect(logs.isNotEmpty, isTrue);
        expect(logs.first.targetId, equals('user_target_99'));
        expect(logs.first.action, equals('delete'));
        expect(logs.first.status, equals('deleted'));
        expect(logs.first.reason, contains('Archivage demandé'));
      },
    );
  });
}
