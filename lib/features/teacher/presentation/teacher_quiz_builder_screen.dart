import 'package:flutter/material.dart';
import '../../admin/presentation/content_studio_screen.dart';

/// Teachers use the same catalogue and publication pipeline as administrators.
class TeacherQuizBuilderScreen extends StatelessWidget {
  const TeacherQuizBuilderScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context) =>
      ContentStudioScreen(embedded: embedded, initialTab: 1);
}
