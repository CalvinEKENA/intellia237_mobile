import '../../../app/router/app_routes.dart';

enum AppRole { student, parent, teacher, admin }

extension AppRoleX on AppRole {
  String get label {
    return switch (this) {
      AppRole.student => 'Student',
      AppRole.parent => 'Parent',
      AppRole.teacher => 'Teacher',
      AppRole.admin => 'Admin',
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
