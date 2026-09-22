import '../../../app/router/app_routes.dart';

enum AppRole { student, parent, teacher, admin }

class StoredAppRoleResolution {
  const StoredAppRoleResolution({
    required this.role,
    required this.isLegacy,
    this.isSuperAdmin = false,
  });

  final AppRole? role;
  final bool isLegacy;

  /// Le super administrateur se présente comme AppRole.admin, mais sa portée
  /// n'est pas la même : il n'est rattaché à aucun établissement.
  final bool isSuperAdmin;

  bool get isUnknown => role == null;
}

/// Parses only stable storage identifiers and the explicitly supported legacy
/// aliases. Display labels are deliberately excluded from this contract.
StoredAppRoleResolution parseStoredAppRole(String storedValue) {
  final normalized = storedValue.trim();
  if (normalized == 'superAdmin' || normalized == 'super_admin') {
    return StoredAppRoleResolution(
      role: AppRole.admin,
      isLegacy: normalized == 'super_admin',
      isSuperAdmin: true,
    );
  }
  for (final role in AppRole.values) {
    if (role.name == normalized) {
      return StoredAppRoleResolution(role: role, isLegacy: false);
    }
  }
  return const StoredAppRoleResolution(role: null, isLegacy: false);
}

/// Parses stored roles handling both the additive list `roles` and the legacy
/// singular `role` field.
/// Returns a distinct list of valid [AppRole]s, preserving primary role precedence.
List<AppRole> parseStoredAppRoles(
  dynamic storedRoles,
  String storedPrimaryRole,
) {
  final result = <AppRole>{};
  final primary = parseStoredAppRole(storedPrimaryRole).role;
  if (primary != null) {
    result.add(primary);
  }

  if (storedRoles is Iterable) {
    for (final item in storedRoles) {
      if (item is String) {
        final parsed = parseStoredAppRole(item).role;
        if (parsed != null) {
          result.add(parsed);
        }
      }
    }
  }

  return result.toList(growable: false);
}

extension AppRoleX on AppRole {
  String get label {
    return switch (this) {
      AppRole.student => 'Élève',
      AppRole.parent => 'Parent',
      AppRole.teacher => 'Enseignant',
      AppRole.admin => 'Administrateur',
    };
  }

  String get homePath {
    return switch (this) {
      AppRole.student => AppRoutes.studentHome,
      AppRole.parent => AppRoutes.parentHome,
      AppRole.teacher => AppRoutes.teacherHome,
      AppRole.admin => AppRoutes.adminHome,
    };
  }
}
