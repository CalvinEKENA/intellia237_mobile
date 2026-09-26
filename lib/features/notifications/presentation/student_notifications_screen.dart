import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/notifications/notification_push_service.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../auth/application/auth_controller.dart';
import '../data/notification_repository.dart';
import '../domain/student_notification.dart';

class StudentNotificationsScreen extends ConsumerStatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  ConsumerState<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends ConsumerState<StudentNotificationsScreen> {
  NotificationPermissionState? _permission;
  bool _requestingPermission = false;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifications = ref.watch(studentNotificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(l10n.notificationMarkAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentNotificationsProvider);
          await _refreshPermission();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.md,
                IntelliaSpacing.md,
                IntelliaSpacing.md,
                IntelliaSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: _PermissionCard(
                  state: _permission,
                  loading: _requestingPermission,
                  onEnable: _enablePush,
                ),
              ),
            ),
            notifications.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: IntelliaStateView(kind: IntelliaStateKind.loading),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: IntelliaStateView(
                  kind: IntelliaStateKind.errorRetryable,
                  title: l10n.notificationsUnavailable,
                  message: l10n.notificationsSyncError,
                  primaryLabel: l10n.retryLabel,
                  onPrimary: () => ref.invalidate(studentNotificationsProvider),
                ),
              ),
              data: (items) => items.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: IntelliaStateView(
                        kind: IntelliaStateKind.empty,
                        title: l10n.notificationsEmptyTitle,
                        message: l10n.notificationsEmptyBody,
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        IntelliaSpacing.md,
                        IntelliaSpacing.xs,
                        IntelliaSpacing.md,
                        IntelliaSpacing.xl,
                      ),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: IntelliaSpacing.sm),
                        itemBuilder: (context, index) => _NotificationCard(
                          notification: items[index],
                          onTap: () => _open(items[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPermission() async {
    final state = await NotificationPushService.permissionState();
    if (mounted) setState(() => _permission = state);
  }

  Future<void> _enablePush() async {
    final userId = ref.read(authControllerProvider).userId;
    if (userId == null) return;
    setState(() => _requestingPermission = true);
    final state = await NotificationPushService.requestAndRegister(userId);
    if (!mounted) return;
    setState(() {
      _permission = state;
      _requestingPermission = false;
    });
    if (state == NotificationPermissionState.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notificationPermissionDenied)),
      );
    }
  }

  Future<void> _markAllRead() async {
    final userId = ref.read(authControllerProvider).userId;
    if (userId == null) return;
    await ref.read(notificationRepositoryProvider).markAllRead(userId);
  }

  Future<void> _open(StudentNotification notification) async {
    final userId = ref.read(authControllerProvider).userId;
    if (userId == null) return;
    await ref
        .read(notificationRepositoryProvider)
        .markRead(userId: userId, id: notification.id);
    if (!mounted) return;
    final route = notification.route;
    if (route != null && AppRoutes.isSafeNotificationRoute(route)) {
      context.go(route);
    }
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.state,
    required this.loading,
    required this.onEnable,
  });

  final NotificationPermissionState? state;
  final bool loading;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state == null ||
        state == NotificationPermissionState.enabled ||
        state == NotificationPermissionState.unsupported) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.notificationEnableTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(l10n.notificationEnableBody),
            const SizedBox(height: IntelliaSpacing.sm),
            FilledButton.icon(
              onPressed: loading ? null : onEnable,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_rounded),
              label: Text(l10n.notificationEnableAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final StudentNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: notification.isUnread ? colors.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notification.isUnread
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: notification.isUnread ? colors.primary : null,
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _notificationTitle(context, notification),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(_notificationBody(context, notification)),
                    const SizedBox(height: 6),
                    Text(
                      _dateLabel(notification.createdAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              if (notification.isUnread) ...[
                const SizedBox(width: IntelliaSpacing.xs),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} · '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

/// Titre affiché : localisé côté client pour les notifications composées par
/// code de type (Réserve d'étude), sinon le titre stocké.
String _notificationTitle(BuildContext context, StudentNotification n) {
  if (n.isLocalizedByType) return context.l10n.studyReserveNotifTitle;
  return n.title;
}

/// Corps affiché : pour la Réserve d'étude, texte FR/EN dérivé du seuil (jamais
/// alarmiste), sinon le corps stocké.
String _notificationBody(BuildContext context, StudentNotification n) {
  if (!n.isLocalizedByType) return n.body;
  final percent = n.thresholdPercent ?? 0;
  final l10n = context.l10n;
  if (percent <= 0) return l10n.studyReserveNotifDepleted;
  if (percent <= 5) return l10n.studyReserveNotifCritical(percent);
  if (percent <= 25) return l10n.studyReserveNotifLow(percent);
  return l10n.studyReserveNotifInfo(percent);
}
