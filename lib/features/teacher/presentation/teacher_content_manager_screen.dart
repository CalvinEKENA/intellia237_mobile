import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
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
            'Gestion de contenus',
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
                    'Publier un contenu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClass,
                    decoration: const InputDecoration(labelText: 'Classe'),
                    items: const [
                      DropdownMenuItem(
                        value: 'sec_a',
                        child: Text('Seconde A'),
                      ),
                      DropdownMenuItem(
                        value: 'sec_c',
                        child: Text('Seconde C'),
                      ),
                      DropdownMenuItem(
                        value: 'prem_d',
                        child: Text('Première D'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedClass = value!),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Matière'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Mathematiques',
                        child: Text('Mathématiques'),
                      ),
                      DropdownMenuItem(
                        value: 'Physique',
                        child: Text('Physique'),
                      ),
                      DropdownMenuItem(
                        value: 'Francais',
                        child: Text('Français'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedSubject = value!),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la leçon',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Titre requis'
                        : null,
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  TextFormField(
                    controller: _chapterController,
                    decoration: const InputDecoration(labelText: 'Chapitre'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Chapitre requis'
                        : null,
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  TextFormField(
                    controller: _summaryController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Résumé'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Résumé requis'
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
                    label: Text(_isPublishing ? 'Publication…' : 'Publier'),
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
      appBar: AppBar(title: const Text('Contenus')),
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
      const SnackBar(content: Text('Contenu publié avec succès.')),
    );
    _titleController.clear();
    _chapterController.clear();
    _summaryController.clear();
  }
}
