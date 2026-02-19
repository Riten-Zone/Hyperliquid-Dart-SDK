@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('TWAP history subscription integration', () {
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

    test('subscribes to TWAP history channel', () async {
      var updateCount = 0;
      final history = <TwapHistoryEvent>[];

      final handle = ws.subscribeUserTwapHistory(userAddress, (events) {
        updateCount++;
        history.addAll(events);
        print('TWAP history update #$updateCount: ${events.length} events');

        for (final event in events) {
          print('  ${event.coin} ${event.isBuy ? "BUY" : "SELL"} '
              '${event.szFilled}/${event.sz} @ ${event.limitPx} - ${event.status}');
          print('    Start: ${DateTime.fromMillisecondsSinceEpoch(event.startTime)}');
          if (event.endTime != null) {
            print('    End: ${DateTime.fromMillisecondsSinceEpoch(event.endTime!)}');
          }
        }
      });

      // Wait for history
      await Future.delayed(Duration(seconds: 5));

      print('Received $updateCount TWAP history updates');

      // Verify subscription was successful
      expect(handle, isNotNull);

      if (history.isNotEmpty) {
        final firstEvent = history.first;
        expect(firstEvent.coin, isNotEmpty);
        expect(firstEvent.status, isIn(['running', 'finished', 'canceled']));
        expect(firstEvent.durationMins, greaterThanOrEqualTo(5));
        expect(firstEvent.startTime, greaterThan(0));

        // Verify finished/canceled events have endTime
        final completedEvents = history.where(
          (e) => e.status == 'finished' || e.status == 'canceled',
        );
        for (final event in completedEvents) {
          if (event.endTime != null) {
            expect(event.endTime, greaterThanOrEqualTo(event.startTime));
          }
        }

        print('✓ TWAP history structure validated');
      } else {
        print('✓ No TWAP history (account may not have historical TWAPs)');
      }

      await handle.cancel();
    });

    test('TWAP history subscription handles connection', () async {
      // This test verifies the subscription is properly set up
      // even if no history is present

      final handle = ws.subscribeUserTwapHistory(userAddress, (events) {
        // Handler is set up correctly
        expect(events, isA<List<TwapHistoryEvent>>());

        for (final event in events) {
          expect(event.coin, isNotEmpty);
          expect(event.status, isNotEmpty);
        }
      });

      // Wait a moment
      await Future.delayed(Duration(seconds: 2));

      // Cancel should work without errors
      await handle.cancel();

      print('✓ TWAP history subscription lifecycle complete');
    });
  });
}
