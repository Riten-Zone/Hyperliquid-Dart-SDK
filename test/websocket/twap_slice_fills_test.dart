@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('TWAP slice fills subscription integration', () {
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

    test('subscribes to TWAP slice fills channel', () async {
      var fillCount = 0;
      final fills = <TwapSliceFill>[];

      final handle = ws.subscribeUserTwapSliceFills(userAddress, (sliceFills) {
        fillCount++;
        fills.addAll(sliceFills);
        print('TWAP slice fills update #$fillCount: ${sliceFills.length} fills');

        for (final fill in sliceFills) {
          print('  ${fill.coin} ${fill.isBuy ? "BUY" : "SELL"} '
              '${fill.sz} @ ${fill.px} - Time: ${fill.time}');
          print('    Hash: ${fill.hash}');
          if (fill.twapId != null) {
            print('    TWAP ID: ${fill.twapId}');
          }
        }
      });

      // Wait to see if any TWAP slice fills arrive
      // Note: These will only arrive if TWAPs are actively executing and filling
      await Future.delayed(Duration(seconds: 5));

      print('Received $fillCount TWAP slice fill updates in 5 seconds');

      // Verify subscription was successful (even if no fills received)
      expect(handle, isNotNull);

      if (fills.isNotEmpty) {
        final firstFill = fills.first;
        expect(firstFill.coin, isNotEmpty);
        expect(firstFill.user.toLowerCase(), userAddress.toLowerCase());
        expect(firstFill.time, greaterThan(0));

        // Verify TWAP fills have special hash format
        expect(firstFill.hash, matches(r'^0x0+$'),
            reason: 'TWAP fills should have hash="0x000...000"');

        print('✓ TWAP slice fill structure validated');
        print('  Confirmed hash format: ${firstFill.hash}');
      } else {
        print('✓ No TWAP slice fills (no active TWAPs executing)');
      }

      await handle.cancel();
    });

    test('TWAP slice fills subscription handles connection', () async {
      // This test verifies the subscription is properly set up
      // even if no fills occur

      final handle = ws.subscribeUserTwapSliceFills(userAddress, (fills) {
        // Handler is set up correctly
        expect(fills, isA<List<TwapSliceFill>>());

        for (final fill in fills) {
          expect(fill.coin, isNotEmpty);
          expect(fill.user, isNotEmpty);
          expect(fill.px, isNotEmpty);
          expect(fill.sz, isNotEmpty);
        }
      });

      // Wait a moment
      await Future.delayed(Duration(seconds: 2));

      // Cancel should work without errors
      await handle.cancel();

      print('✓ TWAP slice fills subscription lifecycle complete');
    });

    test('multiple TWAP slice fill subscriptions', () async {
      // Verify we can have multiple handlers
      var handler1Count = 0;
      var handler2Count = 0;

      final handle1 = ws.subscribeUserTwapSliceFills(userAddress, (fills) {
        handler1Count++;
      });

      final handle2 = ws.subscribeUserTwapSliceFills(userAddress, (fills) {
        handler2Count++;
      });

      await Future.delayed(Duration(seconds: 3));

      print('Handler 1: $handler1Count updates');
      print('Handler 2: $handler2Count updates');

      // Both handlers should receive the same messages
      // (if any fills were sent)
      if (handler1Count > 0 || handler2Count > 0) {
        expect(handler1Count, equals(handler2Count),
            reason: 'Both handlers should receive same updates');
      }

      await handle1.cancel();
      await handle2.cancel();

      print('✓ Multiple handlers managed correctly');
    });
  });
}
