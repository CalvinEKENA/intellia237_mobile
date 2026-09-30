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

/// Espaces d'un compte : le rôle principal `role` et les espaces additifs
/// `roles`, lus exactement comme le serveur (functions/src/auth/userRoles.ts)
/// et les règles Firestore :
/// - un compte élève n'a pas d'autre espace ;
/// - `roles` n'ajoute que parent, enseignant ou direction — jamais élève,
///   jamais super-administration (qui ne se lit que dans `role`).
/// Le rôle principal vient en premier.
List<AppRole> parseStoredAppRoles(
  dynamic storedRoles,
  String storedPrimaryRole,
) {
  final result = <AppRole>{};
  final primary = parseStoredAppRole(storedPrimaryRole).role;
  if (primary != null) {
    result.add(primary);
  }
  if (primary == AppRole.student) return result.toList(growable: false);

  if (storedRoles is Iterable) {
    for (final item in storedRoles) {
      if (item is! String) continue;
      final role = switch (item.trim()) {
        'parent' => AppRole.parent,
        'teacher' => AppRole.teacher,
        'admin' => AppRole.admin,
        _ => null,
      };
      if (role != null) result.add(role);
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
