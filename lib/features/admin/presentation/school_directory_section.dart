import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import 'admin_presentation_localization.dart';
import '../../auth/application/auth_controller.dart';
import 'account_management_controls.dart';

/// L'annuaire de toute l'école, en lecture.
///
/// Registre de décisions : aucune action d'ajout, de retrait ou de changement
/// d'école n'existe ici, pour aucun rôle. Les élèves entrent par leur propre
/// inscription ; la direction les voit, elle ne les administre pas.
class SchoolDirectorySection extends ConsumerStatefulWidget {
  const SchoolDirectorySection({super.key, this.establishmentId});

  /// L'école à lire, pour l'administration générale ; une direction lit
  /// toujours la sienne.
  final String? establishmentId;

  @override
  ConsumerState<SchoolDirectorySection> createState() =>
      _SchoolDirectorySectionState();
}

class _SchoolDirectorySectionState
    extends ConsumerState<SchoolDirectorySection> {
  static const _roles = [
    AdminRoleType.teacher,
    AdminRoleType.admin,
    AdminRoleType.parent,
    AdminRoleType.student,
  ];

  AdminRoleType _role = AdminRoleType.teacher;
  final List<String> _cursors = [];

  @override
  void didUpdateWidget(SchoolDirectorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.establishmentId != widget.establishmentId) _cursors.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <Widget>[];
    String? nextCursor;
    var loading = false;

    // Chaque page reste une lecture distincte : « voir plus » ajoute un
    // curseur, sans relire ce qui est déjà affiché.
    for (final cursor in <String?>[null, ..._cursors]) {
      final filter = (
        role: _role,
        afterId: cursor,
        establishmentId: widget.establishmentId,
      );
      ref
          .watch(schoolDirectoryProvider(filter))
          .when<void>(
            data: (page) {
              for (final member in page.members) {
                rows.add(_MemberTile(member: member));
              }
              nextCursor = page.nextCursor;
            },
            loading: () {
              loading = true;
              nextCursor = null;
            },
            error: (error, _) {
              nextCursor = null;
              rows.add(
                _InlineRetry(
                  onRetry: () =>
                      ref.invalidate(schoolDirectoryProvider(filter)),
                ),
              );
            },
          );
    }

    return Column(
      key: const ValueKey('school-directory'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schoolDirectoryTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<AdminRoleType>(
            segments: [
              for (final role in _roles)
                ButtonSegment(
                  value: role,
                  label: Text(adminRoleLabel(context, role)),
                ),
            ],
            selected: {_role},
            onSelectionChanged: (selection) => setState(() {
              _role = selection.first;
              _cursors.clear();
            }),
          ),
        ),
        if (_role == AdminRoleType.student) ...[
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            l10n.schoolDirectoryStudentsNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: IntelliaSpacing.sm),
        ...rows,
        if (loading)
          const Padding(
            padding: EdgeInsets.all(IntelliaSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (rows.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Text(l10n.schoolDirectoryEmpty),
            ),
          ),
        if (!loading && nextCursor != null)
          Center(
            child: TextButton(
              key: const ValueKey('school-directory-more'),
              onPressed: () => setState(() => _cursors.add(nextCursor!)),
              child: Text(l10n.schoolDirectoryLoadMore),
            ),
          ),
      ],
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});

  final SchoolDirectoryMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = [
      member.classLevel,
      member.email,
      member.phone,
      if (member.accountStatus == 'suspended')
        context.l10n.adminStatusSuspended,
    ].where((detail) => detail.isNotEmpty).join(' · ');
    final initial = member.fullName.trim().isEmpty
        ? '?'
        : member.fullName.trim()[0].toUpperCase();
    return Card(
      child: ListTile(
        key: ValueKey('directory-member-${member.id}'),
        leading: CircleAvatar(child: Text(initial)),
        title: Text(member.fullName),
        subtitle: details.isEmpty ? null : Text(details),
        trailing: ref.watch(authControllerProvider).isSuperAdmin
            ? AccountManagementMenu(
                accountId: member.id,
                name: member.fullName,
                status: member.accountStatus,
              )
            : member.accountStatus == 'pending_validation'
            ? Tooltip(
                message: context.l10n.schoolDirectoryPending,
                child: const Icon(Icons.hourglass_top_rounded),
              )
            : null,
      ),
    );
  }
}

/// Les classes de l'école : la direction les nomme, sans en changer la
/// composition — les règles refusent d'ailleurs toute retouche des effectifs.
class SchoolClassesSection extends ConsumerWidget {
  const SchoolClassesSection({super.key, this.establishmentId});

  final String? establishmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('school-classes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schoolClassesTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        ref
            .watch(schoolClassesProvider(establishmentId))
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(IntelliaSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _InlineRetry(
                onRetry: () =>
                    ref.invalidate(schoolClassesProvider(establishmentId)),
              ),
              data: (classes) => classes.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(IntelliaSpacing.md),
                        child: Text(l10n.schoolClassesEmpty),
                      ),
                    )
                  : Column(
                      children: [
                        for (final schoolClass in classes)
                          Card(
                            child: ListTile(
                              key: ValueKey('school-class-${schoolClass.id}'),
                              title: Text(schoolClass.name),
                              subtitle: Text(
                                [
                                  if (schoolClass.levelLabel.isNotEmpty)
                                    schoolClass.levelLabel,
                                  l10n.schoolClassCounts(
                                    schoolClass.studentCount,
                                    schoolClass.teacherCount,
                                  ),
                                ].join(' · '),
                              ),
                              trailing: IconButton(
                                key: ValueKey('rename-class-${schoolClass.id}'),
                                tooltip: l10n.renameClassLabel,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _rename(context, ref, schoolClass),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    SchoolClassSummary schoolClass,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.accountReviewFailed;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameClassDialog(initialName: schoolClass.name),
    );
    if (name == null || name.trim() == schoolClass.name) return;
    try {
      await ref
          .read(adminActionsProvider)
          .renameSchoolClass(classId: schoolClass.id, name: name);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }
}

class _RenameClassDialog extends StatefulWidget {
  const _RenameClassDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameClassDialog> createState() => _RenameClassDialogState();
}

class _RenameClassDialogState extends State<_RenameClassDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.renameClassLabel),
      content: TextField(
        key: const ValueKey('rename-class-field'),
        controller: _name,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(labelText: l10n.classNameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_name.text.trim()),
          child: Text(l10n.saveLabel),
        ),
      ],
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.cloud_off_rounded),
      title: Text(context.l10n.accountReviewFailed),
      trailing: TextButton(
        onPressed: onRetry,
        child: Text(context.l10n.retryLabel),
      ),
    ),
  );
}
