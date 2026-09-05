import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/notifications/notification_push_service.dart';

void main() {
  test('a shared installation cannot overwrite another user device record', () {
    final first = notificationDeviceDocumentId(
      userId: 'guardian-a',
      installationId: 'shared-phone',
    );
    final second = notificationDeviceDocumentId(
      userId: 'guardian-b',
      installationId: 'shared-phone',
    );

    expect(first, 'guardian-a_shared-phone');
    expect(second, 'guardian-b_shared-phone');
    expect(first, isNot(second));
  });
}
