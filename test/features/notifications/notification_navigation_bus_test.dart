import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/notifications/notification_navigation_bus.dart';

void main() {
  test('retains a cold-start route until the app router subscribes', () {
    NotificationNavigationBus.open('/notifications');
    expect(NotificationNavigationBus.takePending(), '/notifications');
    expect(NotificationNavigationBus.takePending(), isNull);
  });

  test('ignores absent and invalid empty destinations', () {
    NotificationNavigationBus.open(null);
    NotificationNavigationBus.open('   ');
    expect(NotificationNavigationBus.takePending(), isNull);
  });
}
