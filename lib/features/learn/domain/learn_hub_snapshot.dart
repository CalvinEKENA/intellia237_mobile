import 'learn_academic_context.dart';
import 'learn_subject.dart';

class LearnHubSnapshot {
  const LearnHubSnapshot({required this.context, required this.subjects});

  final LearnAcademicContext context;
  final List<LearnSubject> subjects;
}
