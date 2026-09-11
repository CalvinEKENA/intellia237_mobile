import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import 'admin_presentation_localization.dart';
import '../../auth/application/auth_controller.dart';

class BroadcastCenterScreen extends ConsumerStatefulWidget {
  const BroadcastCenterScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<BroadcastCenterScreen> createState() =>
      _BroadcastCenterScreenState();
}

class _BroadcastCenterScreenState extends ConsumerState<BroadcastCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _audience = adminAudienceWholeSchool;

  /// L'école destinataire, que l'administration générale choisit.
  String? _targetSchoolId;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = ref.watch(authControllerProvider).isSuperAdmin;
    final schools = isSuperAdmin
        ? ref.watch(adminEstablishmentsProvider).valueOrNull ??
              const <EstablishmentOption>[]
        : const <EstablishmentOption>[];
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final body = dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        message: stateMessageForKind(context, stateKindForError(error)),
        primaryLabel: context.l10n.retryLabel,
        onPrimary: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (dashboard) => ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.xl,
        ),
        children: [
          Text(
            context.l10n.broadcastCenterTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            context.l10n.broadcastCenterSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: context.l10n.titleLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? context.l10n.titleRequired
                          : null,
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    if (isSuperAdmin) ...[
                      DropdownButtonFormField<String>(
                        key: const ValueKey('broadcast-target-school'),
                        initialValue: _targetSchoolId,
                        decoration: InputDecoration(
                          labelText: context.l10n.broadcastTargetSchool,
                        ),
                        items: [
                          for (final school in schools)
                            DropdownMenuItem(
                              value: school.id,
                              child: Text(
                                school.city.isEmpty
                                    ? school.name
                                    : '${school.name} — ${school.city}',
                              ),
                            ),
                        ],
                        validator: (value) => value == null
                            ? context.l10n.broadcastTargetSchoolRequired
                            : null,
                        onChanged: (value) =>
                            setState(() => _targetSchoolId = value),
                      ),
                      const SizedBox(height: IntelliaSpacing.sm),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: _audience,
                      decoration: InputDecoration(
                        labelText: context.l10n.audienceLabel,
                      ),
                      items: [
                        for (final item in adminAudienceOptions)
                          DropdownMenuItem(
                            value: item,
                            child: Text(adminAudienceLabel(context, item)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _audience = value);
                        }
                      },
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.l10n.messageLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? context.l10n.messageRequired
                          : null,
                    ),
                    const SizedBox(height: IntelliaSpacing.md),
                    FilledButton.icon(
                      onPressed: _isSending ? null : _send,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.campaign_rounded),
                      label: Text(
                        _isSending
                            ? context.l10n.publishingLabel
                            : context.l10n.publishAnnouncementTitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Text(
            context.l10n.recentHistory,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          for (final ann in dashboard.recentAnnouncements) ...[
            _AnnouncementItem(announcement: ann),
            const SizedBox(height: IntelliaSpacing.xs),
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.broadcastCenterTitle)),
      body: body,
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final published = context.l10n.announcementPublished;
    final failed = context.l10n.announcementFailed;
    setState(() => _isSending = true);
    try {
      await ref
          .read(adminActionsProvider)
          .publishAnnouncement(
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            audience: _audience,
            establishmentId: _targetSchoolId,
          );
      _titleController.clear();
      _messageController.clear();
      messenger.showSnackBar(SnackBar(content: Text(published)));
    } catch (_) {
      // Une annonce refusée se dit ; elle ne fait plus planter l'écran.
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({required this.announcement});

  final AdminAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: IntelliaSpacing.xxs),
            Text(announcement.message),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              context.l10n.audienceValue(
                adminAudienceLabel(context, announcement.audience),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
