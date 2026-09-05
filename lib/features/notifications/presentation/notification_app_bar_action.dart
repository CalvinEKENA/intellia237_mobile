import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../data/notification_repository.dart';

class NotificationAppBarAction extends ConsumerWidget {
  const NotificationAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final label = unread == 0
        ? 'Ouvrir les notifications'
        : 'Ouvrir les notifications, $unread non lue${unread > 1 ? 's' : ''}';
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: 'Notifications',
        onPressed: () => context.push(AppRoutes.studentNotifications),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          child: const Icon(Icons.notifications_none_rounded),
        ),
      ),
    );
  }
}
