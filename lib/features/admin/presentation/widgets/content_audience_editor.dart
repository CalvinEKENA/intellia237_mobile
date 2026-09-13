import 'package:flutter/material.dart';
import '../../../learn/domain/content_audience.dart';
import '../../domain/admin_content_models.dart';

/// Each group is an alternative audience; selected dimensions inside a group
/// must all match. An empty dimension means all values, never an unknown value.
class ContentAudienceEditor extends StatelessWidget {
  const ContentAudienceEditor({
    required this.value,
    required this.defaultClass,
    required this.onChanged,
    super.key,
  });
  final ContentAudience? value;
  final String defaultClass;
  final ValueChanged<ContentAudience> onChanged;
  static const labels = {
    'educationSystems': 'Systèmes éducatifs',
    'educationTypes': 'Types d’enseignement',
    'classLevels': 'Classes',
    'series': 'Séries',
    'tracks': 'Filières / spécialités',
    'languages': 'Langues du contenu',
    'establishments': 'Établissements (identifiants)',
  };
  @override
  Widget build(BuildContext context) {
    final groups =
        value?.clauses ??
        [
          {
            'classLevels': [defaultClass],
          },
        ];
    void update(int index, String dimension, List<String> selected) {
      final next = [
        for (final group in groups) Map<String, List<String>>.from(group),
      ];
      next[index][dimension] = selected;
      onChanged(ContentAudience(clauses: next));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Public visé',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Text(
          'Chaque groupe ajoute un public. Dans un groupe, tous les critères sélectionnés doivent correspondre. Un critère vide signifie « tous ». Le périmètre de votre établissement reste applicable.',
        ),
        for (var i = 0; i < groups.length; i++)
          ExpansionTile(
            key: ValueKey('audience-group-$i'),
            title: Text('Public ${i + 1}'),
            subtitle: Text(
              groups[i].values.expand((e) => e).join(' · ').isEmpty
                  ? 'Tout le secondaire'
                  : groups[i].values.expand((e) => e).join(' · '),
            ),
            children: [
              for (final dimension in ContentAudience.dimensions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _dimension(
                    context,
                    dimension,
                    groups[i][dimension] ?? [],
                    (v) => update(i, dimension, v),
                  ),
                ),
              if (groups.length > 1)
                TextButton(
                  onPressed: () => onChanged(
                    ContentAudience(clauses: [...groups]..removeAt(i)),
                  ),
                  child: const Text('Retirer ce public'),
                ),
            ],
          ),
        if (groups.length < 12)
          TextButton.icon(
            onPressed: () => onChanged(
              ContentAudience(
                clauses: [
                  ...groups,
                  {
                    'classLevels': [defaultClass],
                  },
                ],
              ),
            ),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Ajouter un autre public'),
          ),
      ],
    );
  }

  Widget _dimension(
    BuildContext context,
    String key,
    List<String> selected,
    ValueChanged<List<String>> changed,
  ) {
    final options = switch (key) {
      'educationSystems' => ['francophone', 'anglophone'],
      'educationTypes' => ['general', 'technical'],
      'classLevels' => kAllClassLevels,
      'languages' => ['fr', 'en'],
      _ => <String>[],
    };
    if (options.isEmpty) {
      return TextFormField(
        key: ValueKey(key),
        initialValue: selected.join(', '),
        decoration: InputDecoration(
          labelText: labels[key],
          helperText:
              'Valeurs séparées par des virgules. Laisser vide pour tous.',
        ),
        onFieldSubmitted: (s) => changed(
          s
              .split(',')
              .map((v) => v.trim())
              .where((v) => v.isNotEmpty)
              .toSet()
              .toList(),
        ),
        onChanged: (s) => changed(
          s
              .split(',')
              .map((v) => v.trim())
              .where((v) => v.isNotEmpty)
              .toSet()
              .toList(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labels[key]!),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(option),
                selected: selected.contains(option),
                onSelected: (yes) => changed(
                  yes ? [...selected, option] : [...selected]
                    ..remove(option),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
