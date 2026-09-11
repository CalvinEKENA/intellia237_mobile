import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';

/// Choisit l'école d'un compte, ou l'ouvre si elle n'existe pas encore.
///
/// Renvoie l'identifiant de l'école retenue, ou null si la feuille se referme
/// sans choix. Réservé à l'administration générale, seule à voir toutes les
/// écoles et à pouvoir en ouvrir une.
Future<String?> showAttachSchoolSheet(BuildContext context, {String? body}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AttachSchoolSheet(body: body),
  );
}

class AttachSchoolSheet extends ConsumerStatefulWidget {
  const AttachSchoolSheet({super.key, this.body});

  /// Ce que la feuille explique ; par défaut, le cas d'une approbation.
  final String? body;

  @override
  ConsumerState<AttachSchoolSheet> createState() => _AttachSchoolSheetState();
}

class _AttachSchoolSheetState extends ConsumerState<AttachSchoolSheet> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  bool _creating = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 3) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.accountReviewFailed;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(adminActionsProvider)
          .createEstablishment(name: _name.text, city: _city.text);
      navigator.pop(id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schools = ref.watch(adminEstablishmentsProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          0,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          key: const ValueKey('attach-school-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.reviewAttachSchoolTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(widget.body ?? l10n.reviewAttachSchoolBody),
            const SizedBox(height: IntelliaSpacing.md),
            schools.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(IntelliaSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Card(
                child: ListTile(
                  title: Text(l10n.accountReviewFailed),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.invalidate(adminEstablishmentsProvider),
                    child: Text(l10n.retryLabel),
                  ),
                ),
              ),
              data: (options) => Column(
                children: [
                  for (final option in options)
                    Card(
                      child: ListTile(
                        key: ValueKey('attach-school-${option.id}'),
                        leading: const Icon(Icons.school_outlined),
                        title: Text(option.name),
                        subtitle: option.city.isEmpty
                            ? null
                            : Text(option.city),
                        onTap: () => Navigator.of(context).pop(option.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: IntelliaSpacing.md),
            if (!_creating)
              OutlinedButton.icon(
                key: const ValueKey('attach-school-create'),
                onPressed: () => setState(() => _creating = true),
                icon: const Icon(Icons.add_business_outlined),
                label: Text(l10n.reviewCreateSchool),
              )
            else ...[
              TextField(
                key: const ValueKey('attach-school-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.schoolNameLabel),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              TextField(
                key: const ValueKey('attach-school-city'),
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.schoolCityLabel),
              ),
              const SizedBox(height: IntelliaSpacing.md),
              FilledButton(
                key: const ValueKey('attach-school-confirm'),
                onPressed: _saving ? null : _create,
                child: Text(l10n.reviewCreateSchoolAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
