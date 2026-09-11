import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import 'attach_school_sheet.dart';
import 'school_directory_section.dart';

/// Toutes les écoles, vues par l'administration générale.
///
/// Registre de décisions : l'administration générale n'appartient à aucune
/// école, elle les voit toutes. Choisir une école ouvre son annuaire et ses
/// classes, comme sa direction les voit — sans jamais ajouter ni retirer un
/// élève : les changements d'école passent par leur propre section, motivés.
class SchoolsOverviewSection extends ConsumerStatefulWidget {
  const SchoolsOverviewSection({super.key});

  @override
  ConsumerState<SchoolsOverviewSection> createState() =>
      _SchoolsOverviewSectionState();
}

class _SchoolsOverviewSectionState
    extends ConsumerState<SchoolsOverviewSection> {
  String? _selectedId;

  Future<void> _openSchool() async {
    final id = await showAttachSchoolSheet(
      context,
      body: context.l10n.schoolsOverviewHint,
    );
    if (id != null && mounted) setState(() => _selectedId = id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schools = ref.watch(adminEstablishmentsProvider);

    return Column(
      key: const ValueKey('schools-overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.schoolsOverviewTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('schools-overview-create'),
              onPressed: _openSchool,
              icon: const Icon(Icons.add_business_outlined),
              label: Text(l10n.schoolsOverviewCreate),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(l10n.schoolsOverviewBody, style: theme.textTheme.bodySmall),
        const SizedBox(height: IntelliaSpacing.sm),
        schools.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(IntelliaSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Card(
            child: ListTile(
              title: Text(l10n.accountReviewFailed),
              trailing: TextButton(
                onPressed: () => ref.invalidate(adminEstablishmentsProvider),
                child: Text(l10n.retryLabel),
              ),
            ),
          ),
          data: (options) => options.isEmpty
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(IntelliaSpacing.md),
                    child: Text(l10n.schoolsOverviewEmpty),
                  ),
                )
              : Column(
                  children: [
                    for (final option in options)
                      Card(
                        child: ListTile(
                          key: ValueKey('schools-overview-${option.id}'),
                          leading: const Icon(Icons.school_outlined),
                          title: Text(option.name),
                          subtitle: option.city.isEmpty
                              ? null
                              : Text(option.city),
                          selected: option.id == _selectedId,
                          trailing: Icon(
                            option.id == _selectedId
                                ? Icons.expand_less_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          onTap: () => setState(
                            () => _selectedId = option.id == _selectedId
                                ? null
                                : option.id,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (_selectedId != null) ...[
          const SizedBox(height: IntelliaSpacing.xl),
          SchoolDirectorySection(
            key: ValueKey('directory-$_selectedId'),
            establishmentId: _selectedId,
          ),
          const SizedBox(height: IntelliaSpacing.xl),
          SchoolClassesSection(establishmentId: _selectedId),
        ],
      ],
    );
  }
}
