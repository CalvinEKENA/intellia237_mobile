import '../domain/parent_dashboard.dart';

abstract class ParentRepository {
  Future<ParentDashboard> fetchDashboard({required String parentUid});
}
