import '../../../app/router/app_routes.dart';

enum AppRole { student, parent, teacher, admin }

class StoredAppRoleResolution {
  const StoredAppRoleResolution({required this.role, required this.isLegacy});

  final AppRole? role;
  final bool isLegacy;

  bool get isUnknown => role == null;
}

/// Parses only stable storage identifiers and the explicitly supported legacy
/// aliases. Display labels are deliberately excluded from this contract.
StoredAppRoleResolution parseStoredAppRole(String storedValue) {
  final normalized = storedValue.trim();
  if (normalized == 'superAdmin' || normalized == 'super_admin') {
    return const StoredAppRoleResolution(role: AppRole.admin, isLegacy: true);
  }
  for (final role in AppRole.values) {
    if (role.name == normalized) {
      return StoredAppRoleResolution(role: role, isLegacy: false);
    }
  }
  return const StoredAppRoleResolution(role: null, isLegacy: false);
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
