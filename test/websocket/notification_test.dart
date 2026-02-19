@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('Notification subscription integration', () {
    late WebSocketClient ws;
    late String userAddress;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();

      ws = WebSocketClient();
      await ws.connect();
      await Future.delayed(Duration(milliseconds: 500));
    });

    tearDownAll(() async {
      await ws.dispose();
    });

    test('subscribes to notifications channel', () async {
      var notificationCount = 0;
      final notifications = <NotificationMessage>[];

      final handle = ws.subscribeNotification(userAddress, (notification) {
        notificationCount++;
        notifications.add(notification);
        print('Notification #$notificationCount: ${notification.message}');
      });

      // Wait to see if any notifications arrive
      // Note: Notifications may be rare/empty if no account activity
      await Future.delayed(Duration(seconds: 5));

      print('Received $notificationCount notifications in 5 seconds');

      // Verify subscription was successful (even if no notifications received)
      // The test passes as long as the subscription doesn't error
      expect(handle, isNotNull);

      if (notifications.isNotEmpty) {
        final firstNotif = notifications.first;
        expect(firstNotif.user.toLowerCase(), userAddress.toLowerCase());
        expect(firstNotif.message, isNotEmpty);
        print('✓ Sample notification: "${firstNotif.message}"');
      } else {
        print('✓ No notifications received (account may be inactive)');
      }

      await handle.cancel();
    });

    test('notification subscription handles connection', () async {
      // This test verifies the subscription is properly set up
      // even if no notifications are actually sent

      final handle = ws.subscribeNotification(userAddress, (notification) {
        // Handler is set up correctly
        expect(notification, isA<NotificationMessage>());
        expect(notification.user, isNotEmpty);
      });

      // Wait a moment
      await Future.delayed(Duration(seconds: 2));

      // Cancel should work without errors
      await handle.cancel();

      print('✓ Notification subscription lifecycle complete');
    });

    test('multiple notification subscriptions', () async {
      // Verify we can have multiple handlers (though messages go to same user)
      var handler1Count = 0;
      var handler2Count = 0;

      final handle1 = ws.subscribeNotification(userAddress, (notification) {
        handler1Count++;
      });

      final handle2 = ws.subscribeNotification(userAddress, (notification) {
        handler2Count++;
      });

      await Future.delayed(Duration(seconds: 3));

      print('Handler 1: $handler1Count notifications');
      print('Handler 2: $handler2Count notifications');

      // Both handlers should receive the same messages
      // (if any notifications were sent)
      if (handler1Count > 0 || handler2Count > 0) {
        expect(handler1Count, equals(handler2Count),
            reason: 'Both handlers should receive same notifications');
      }

      await handle1.cancel();
      await handle2.cancel();

      print('✓ Multiple handlers managed correctly');
    });
  });
}
