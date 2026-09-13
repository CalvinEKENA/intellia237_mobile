import 'widgets/content_audience_editor.dart';
import '../../learn/domain/content_audience.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/admin_content_providers.dart';
import '../domain/admin_content_models.dart';
import 'admin_presentation_localization.dart';

/// Crée une matière du programme national pour une classe.
///
/// Registre de décisions : la matière naît en brouillon. Elle devient visible
/// quand une première leçon y est publiée — une matière vide ne s'affiche pas
/// chez l'élève.
class NewSubjectDialog extends ConsumerStatefulWidget {
  const NewSubjectDialog({required this.classLevel, super.key});

  final String classLevel;

  @override
  ConsumerState<NewSubjectDialog> createState() => _NewSubjectDialogState();
}

class _NewSubjectDialogState extends ConsumerState<NewSubjectDialog> {
  /// Les matières courantes du secondaire camerounais, pour aller vite.
  static const _suggestions = <(String, String)>[
    ('Mathématiques', 'math'),
    ('Français', 'french'),
    ('Anglais', 'english'),
    ('Physique-Chimie', 'physic'),
    ('SVT', 'biology'),
    ('Histoire-Géographie', 'history'),
    ('Philosophie', 'philosophy'),
    ('Informatique', 'computer'),
    ('Économie', 'economics'),
    ('ECM', 'book'),
  ];

  final _title = TextEditingController();
  final _description = TextEditingController();
  String _iconKey = 'book';
  int _color = kSubjectColorOptions.first;
  final Set<String> _series = {};
  ContentAudience? _audience;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    if (title.length < 2) {
      setState(() => _error = 'Donnez un nom à la matière.');
      return;
    }
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminContentActionsProvider)
          .createSubject(
            classLevel: widget.classLevel,
            title: title,
            description: _description.text.trim(),
            colorHex: _color,
            iconKey: _iconKey,
            allowedSeries: _series.toList(growable: false),
            audience: _audience,
          );
      navigator.pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = kSeriesByClass[widget.classLevel];
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        top: IntelliaSpacing.md,
        bottom: IntelliaSpacing.xs,
      ),
      child: Text(text, style: theme.textTheme.labelLarge),
    );

    return AlertDialog(
      title: Text(
        'Nouvelle matière — '
        '${adminClassLevelDisplay(context, widget.classLevel)}',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContentAudienceEditor(
                value:
                    _audience ??
                    ContentAudience(
                      clauses: [
                        {
                          'classLevels': [widget.classLevel],
                          'series': _series.toList(),
                        },
                      ],
                    ),
                defaultClass: widget.classLevel,
                onChanged: (a) => setState(() => _audience = a),
              ),
              label('Suggestions'),
              Wrap(
                spacing: IntelliaSpacing.xs,
                runSpacing: IntelliaSpacing.xs,
                children: [
                  for (var index = 0; index < _suggestions.length; index++)
                    ActionChip(
                      key: ValueKey('new-subject-suggestion-$index'),
                      label: Text(_suggestions[index].$1),
                      onPressed: () => setState(() {
                        _title.text = _suggestions[index].$1;
                        _iconKey = _suggestions[index].$2;
                        _color =
                            kSubjectColorOptions[index %
                                kSubjectColorOptions.length];
                        _error = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              TextField(
                key: const ValueKey('new-subject-title'),
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nom de la matière',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              TextField(
                key: const ValueKey('new-subject-description'),
                controller: _description,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (facultative)',
                ),
              ),
              label('Icône'),
              Wrap(
                spacing: IntelliaSpacing.xs,
                runSpacing: IntelliaSpacing.xs,
                children: [
                  for (final entry in kSubjectIconOptions.entries)
                    ChoiceChip(
                      label: Icon(entry.value, size: 18),
                      selected: _iconKey == entry.key,
                      onSelected: (_) => setState(() => _iconKey = entry.key),
                    ),
                ],
              ),
              label('Couleur'),
              Wrap(
                spacing: IntelliaSpacing.sm,
                runSpacing: IntelliaSpacing.xs,
                children: [
                  for (final color in kSubjectColorOptions)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 3,
                            color: _color == color
                                ? theme.colorScheme.onSurface
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (series != null && _audience == null) ...[
                label('Séries concernées — aucune cochée : toutes'),
                Wrap(
                  spacing: IntelliaSpacing.xs,
                  children: [
                    for (final item in series)
                      FilterChip(
                        label: Text(item),
                        selected: _series.contains(item),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _series.add(item)
                              : _series.remove(item),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                'La matière naît en brouillon. Elle devient visible pour les '
                'élèves dès que vous publiez une de ses leçons.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const ValueKey('new-subject-create'),
          onPressed: _saving ? null : _create,
          child: const Text('Créer la matière'),
        ),
      ],
    );
  }
}
