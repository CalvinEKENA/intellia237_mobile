import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/teacher_providers.dart';

class TeacherContentManagerScreen extends ConsumerStatefulWidget {
  const TeacherContentManagerScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<TeacherContentManagerScreen> createState() =>
      _TeacherContentManagerScreenState();
}

class _TeacherContentManagerScreenState
    extends ConsumerState<TeacherContentManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _chapterController = TextEditingController();
  final _summaryController = TextEditingController();
  String _selectedClass = 'sec_a';
  String _selectedSubject = 'Mathematiques';
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _chapterController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.xl,
      ),
      children: [
        if (!widget.embedded) ...[
          Text(
            context.l10n.contentManagementTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.md),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.publishContentTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClass,
                    decoration: InputDecoration(
                      labelText: context.l10n.classLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'sec_a',
                        child: Text(context.l10n.classSecondeA),
                      ),
                      DropdownMenuItem(
                        value: 'sec_c',
                        child: Text(context.l10n.classSecondeC),
                      ),
                      DropdownMenuItem(
                        value: 'prem_d',
                        child: Text(context.l10n.classPremiereD),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedClass = value!),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: InputDecoration(
                      labelText: context.l10n.subjectLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Mathematiques',
                        child: Text(context.l10n.subjectMathematics),
                      ),
                      DropdownMenuItem(
                        value: 'Physique',
                        child: Text(context.l10n.subjectPhysics),
                      ),
                      DropdownMenuItem(
                        value: 'Francais',
                        child: Text(context.l10n.subjectFrench),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedSubject = value!),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: context.l10n.lessonTitleLabel,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? context.l10n.titleRequired
                        : null,
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  TextFormField(
                    controller: _chapterController,
                    decoration: InputDecoration(
                      labelText: context.l10n.chapterLabel,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? context.l10n.chapterRequired
                        : null,
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  TextFormField(
                    controller: _summaryController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: context.l10n.summaryLabel,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? context.l10n.summaryRequired
                        : null,
                  ),
                  const SizedBox(height: IntelliaSpacing.md),
                  FilledButton.icon(
                    onPressed: _isPublishing ? null : _publish,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: Text(
                      _isPublishing
                          ? context.l10n.publishingLabel
                          : context.l10n.publishLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.contentLabel)),
      body: body,
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isPublishing = true);
    await ref
        .read(teacherActionsProvider)
        .publishContent(
          classId: _selectedClass,
          subject: _selectedSubject,
          title: _titleController.text.trim(),
          chapterTitle: _chapterController.text.trim(),
          summary: _summaryController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isPublishing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.contentPublishedSuccess)),
    );
    _titleController.clear();
    _chapterController.clear();
    _summaryController.clear();
  }
}
