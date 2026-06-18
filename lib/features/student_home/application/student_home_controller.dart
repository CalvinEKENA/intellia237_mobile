import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_home_repository.dart';
import '../domain/student_home_snapshot.dart';

final studentHomeControllerProvider =
    AsyncNotifierProvider<StudentHomeController, StudentHomeSnapshot>(
      StudentHomeController.new,
    );

class StudentHomeController extends AsyncNotifier<StudentHomeSnapshot> {
  StudentHomeRepository get _repository =>
      ref.read(studentHomeRepositoryProvider);

  @override
  Future<StudentHomeSnapshot> build() async {
    final firstName = ref.watch(studentFirstNameProvider);
    return _repository.fetchHomeSnapshot(firstName: firstName);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firstName = ref.read(studentFirstNameProvider);
      return _repository.fetchHomeSnapshot(firstName: firstName);
    });
  }
}
