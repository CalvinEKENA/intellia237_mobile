import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
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

  Future<void> _editSchool(EstablishmentOption option) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.accountReviewFailed;
    final draft = await showDialog<({String name, String city})>(
      context: context,
      builder: (_) => _EditSchoolDialog(initial: option),
    );
    if (draft == null) return;
    try {
      await ref
          .read(adminActionsProvider)
          .updateEstablishment(
            establishmentId: option.id,
            name: draft.name,
            city: draft.city,
          );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  Future<void> _toggleArchive(EstablishmentOption option) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.accountReviewFailed;
    try {
      await ref
          .read(adminActionsProvider)
          .setEstablishmentArchived(
            establishmentId: option.id,
            archived: !option.archived,
          );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
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
                          leading: Icon(
                            option.archived
                                ? Icons.school_outlined
                                : Icons.school_rounded,
                            color: option.archived ? theme.disabledColor : null,
                          ),
                          title: Text(option.name),
                          subtitle: Text(
                            [
                              if (option.city.isNotEmpty) option.city,
                              if (option.archived)
                                l10n.establishmentArchivedBadge,
                            ].join(' · '),
                          ),
                          selected: option.id == _selectedId,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PopupMenuButton<String>(
                                key: ValueKey('school-menu-${option.id}'),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editSchool(option);
                                  } else if (value == 'archive') {
                                    _toggleArchive(option);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(l10n.editEstablishmentLabel),
                                  ),
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Text(
                                      option.archived
                                          ? l10n.unarchiveEstablishmentLabel
                                          : l10n.archiveEstablishmentLabel,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                option.id == _selectedId
                                    ? Icons.expand_less_rounded
                                    : Icons.chevron_right_rounded,
                              ),
                            ],
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

class _EditSchoolDialog extends StatefulWidget {
  const _EditSchoolDialog({required this.initial});

  final EstablishmentOption initial;

  @override
  State<_EditSchoolDialog> createState() => _EditSchoolDialogState();
}

class _EditSchoolDialogState extends State<_EditSchoolDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial.name,
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.initial.city,
  );

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.editEstablishmentLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('edit-school-name'),
            controller: _name,
            autofocus: true,
            maxLength: 120,
            decoration: InputDecoration(labelText: l10n.schoolsOverviewTitle),
          ),
          TextField(
            key: const ValueKey('edit-school-city'),
            controller: _city,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.establishmentCityLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          key: const ValueKey('edit-school-submit'),
          onPressed: () => Navigator.of(
            context,
          ).pop((name: _name.text.trim(), city: _city.text.trim())),
          child: Text(l10n.saveLabel),
        ),
      ],
    );
  }
}
