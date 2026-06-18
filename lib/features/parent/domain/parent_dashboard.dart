import 'parent_announcement.dart';
import 'parent_child_profile.dart';

class ParentDashboard {
  const ParentDashboard({required this.children, required this.announcements});

  final List<ParentChildProfile> children;
  final List<ParentAnnouncement> announcements;
}
