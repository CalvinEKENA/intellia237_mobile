import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/campus_providers.dart';
import '../widgets/campus_scaffold.dart';
import 'audit/campus_audit_view.dart';
import 'classes/campus_classes_view.dart';
import 'communications/campus_communications_view.dart';
import 'direction/direction_dashboard_view.dart';
import 'program/campus_program_view.dart';
import 'reports/campus_reports_view.dart';
import 'staff/campus_staff_view.dart';
import 'students/campus_students_view.dart';
import 'studio/campus_studio_view.dart';
import 'teacher/teacher_dashboard_view.dart';

class CampusRootScreen extends ConsumerWidget {
  const CampusRootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSection = ref.watch(campusActiveNavProvider);

    final Widget body = switch (activeSection) {
      CampusNavSection.overview => const DirectionDashboardView(),
      CampusNavSection.today => const TeacherDashboardView(),
      CampusNavSection.classes => const CampusClassesView(),
      CampusNavSection.students => const CampusStudentsView(),
      CampusNavSection.staff => const CampusStaffView(),
      CampusNavSection.program => const CampusProgramView(),
      CampusNavSection.evaluations => const CampusStudioView(),
      CampusNavSection.studio => const CampusStudioView(),
      CampusNavSection.communications => const CampusCommunicationsView(),
      CampusNavSection.reports => const CampusReportsView(),
      CampusNavSection.administration => const CampusAuditView(),
    };

    return CampusScaffold(body: body);
  }
}
