import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';

void main() {
  test('canonical stored roles remain non-legacy', () {
    for (final role in AppRole.values) {
      final resolution = parseStoredAppRole(role.name);
      expect(resolution.role, role);
      expect(resolution.isLegacy, isFalse);
    }
  });

  test('known super-admin aliases recover as legacy admin roles', () {
    for (final stored in const ['superAdmin', 'super_admin']) {
      final resolution = parseStoredAppRole(stored);
      expect(resolution.role, AppRole.admin);
      expect(resolution.isLegacy, isTrue);
    }
  });

  test('unknown and localized labels never become authentication roles', () {
    for (final stored in const ['', 'super-admin', 'Élève', 'Administrateur']) {
      expect(parseStoredAppRole(stored).isUnknown, isTrue);
    }
  });
}
