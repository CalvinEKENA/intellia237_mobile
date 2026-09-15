import 'package:flutter/material.dart';

enum StudioSection {
  overview,
  organization,
  community,
  content,
  finance,
  operations,
  system,
}

enum StudioModule {
  login('/login', '01 Login', Icons.login_rounded, StudioSection.overview),
  dashboard(
    '/dashboard',
    '02 Dashboard',
    Icons.dashboard_rounded,
    StudioSection.overview,
  ),
  establishments(
    '/establishments',
    '03 Establishments',
    Icons.school_rounded,
    StudioSection.organization,
  ),
  establishmentDetail(
    '/establishments/:id',
    '04 Establishment Detail',
    Icons.apartment_rounded,
    StudioSection.organization,
  ),
  schoolClasses(
    '/classes',
    '05 School Classes',
    Icons.class_rounded,
    StudioSection.organization,
  ),
  students(
    '/students',
    '06 Students',
    Icons.person_outline_rounded,
    StudioSection.community,
  ),
  studentDetail(
    '/students/:id',
    '07 Student Detail',
    Icons.badge_outlined,
    StudioSection.community,
  ),
  parents(
    '/parents',
    '08 Parents',
    Icons.family_restroom_rounded,
    StudioSection.community,
  ),
  parentDetail(
    '/parents/:id',
    '09 Parent Detail',
    Icons.escalator_warning_rounded,
    StudioSection.community,
  ),
  teachers(
    '/teachers',
    '10 Teachers',
    Icons.co_present_rounded,
    StudioSection.community,
  ),
  accountsAndRoles(
    '/accounts',
    '11 Accounts & Roles',
    Icons.manage_accounts_rounded,
    StudioSection.organization,
  ),
  contentStudio(
    '/content',
    '12 Content Studio',
    Icons.library_books_rounded,
    StudioSection.content,
  ),
  lessonEditor(
    '/content/lesson/:id',
    '13 Lesson Editor',
    Icons.edit_note_rounded,
    StudioSection.content,
  ),
  notebookLmImport(
    '/notebooklm',
    '14 NotebookLM Import',
    Icons.auto_awesome_motion_rounded,
    StudioSection.content,
  ),
  mediaLibrary(
    '/media',
    '15 Media Library',
    Icons.perm_media_rounded,
    StudioSection.content,
  ),
  flowStudio(
    '/flow',
    '16 FLOW Studio',
    Icons.view_carousel_rounded,
    StudioSection.content,
  ),
  quizStudio(
    '/quiz',
    '17 Quiz Studio',
    Icons.quiz_rounded,
    StudioSection.content,
  ),
  audiences(
    '/audiences',
    '18 Audiences',
    Icons.group_work_rounded,
    StudioSection.content,
  ),
  publishingCenter(
    '/publishing',
    '19 Publishing Center',
    Icons.publish_rounded,
    StudioSection.content,
  ),
  companions(
    '/companions',
    '20 Companions',
    Icons.smart_toy_rounded,
    StudioSection.operations,
  ),
  plansAndSubscriptions(
    '/plans',
    '21 Plans & Subscriptions',
    Icons.card_membership_rounded,
    StudioSection.finance,
  ),
  studyReserve(
    '/study-reserve',
    '22 Study Reserve',
    Icons.hourglass_top_rounded,
    StudioSection.finance,
  ),
  payments(
    '/payments',
    '23 Payments & Mobile Money',
    Icons.account_balance_wallet_rounded,
    StudioSection.finance,
  ),
  notifications(
    '/notifications',
    '24 Notifications',
    Icons.notifications_active_rounded,
    StudioSection.operations,
  ),
  announcements(
    '/announcements',
    '25 Announcements',
    Icons.campaign_rounded,
    StudioSection.operations,
  ),
  analytics(
    '/analytics',
    '26 Analytics',
    Icons.analytics_rounded,
    StudioSection.operations,
  ),
  systemHealth(
    '/system-health',
    '27 System Health',
    Icons.health_and_safety_rounded,
    StudioSection.system,
  ),
  auditLog(
    '/audit-log',
    '28 Audit Log',
    Icons.security_rounded,
    StudioSection.system,
  ),
  globalSettings(
    '/settings',
    '29 Global Settings',
    Icons.settings_suggest_rounded,
    StudioSection.system,
  ),
  featureFlags(
    '/feature-flags',
    '30 Feature Flags',
    Icons.flag_rounded,
    StudioSection.system,
  ),
  mobileRelease(
    '/mobile-release',
    '31 Mobile Release',
    Icons.phone_android_rounded,
    StudioSection.system,
  );

  const StudioModule(this.path, this.title, this.icon, this.section);

  final String path;
  final String title;
  final IconData icon;
  final StudioSection section;

  bool get isDetailRoute => path.contains(':id') || this == StudioModule.login;
}
