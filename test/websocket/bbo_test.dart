@Tags(['integration'])
library;

import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BBO subscription integration', () {
    late WebSocketClient ws;

    setUpAll(() async {
      ws = WebSocketClient();
      await ws.connect();
      // Wait for connection to stabilize
      await Future.delayed(Duration(milliseconds: 500));
    });

    tearDownAll(() async {
      await ws.dispose();
    });

    test('subscribes to BTC BBO and receives updates', () async {
      var updateCount = 0;
      BboUpdate? lastUpdate;

      final handle = ws.subscribeBbo('BTC', (update) {
        updateCount++;
        lastUpdate = update;
        print('BBO update #$updateCount: ${update.coin} at ${update.time}');
        print('  Bid: ${update.bbo[0].px} @ ${update.bbo[0].sz}');
        print('  Ask: ${update.bbo[1].px} @ ${update.bbo[1].sz}');
      });

      // Wait for several updates
      await Future.delayed(Duration(seconds: 5));

      // Verify we received updates
      expect(updateCount, greaterThan(0), reason: 'Should receive BBO updates');
      expect(lastUpdate, isNotNull);
      expect(lastUpdate!.coin, isNotEmpty); // Coin should exist
      expect(lastUpdate!.bbo.length, 2); // bid and ask
      expect(lastUpdate!.bbo[0].px, isNotEmpty); // bid price
      expect(lastUpdate!.bbo[1].px, isNotEmpty); // ask price

      print('✓ Received $updateCount BBO updates in 5 seconds');
      print('  Last update coin: ${lastUpdate!.coin}');

      await handle.cancel();
    });

    test('subscribes to multiple coins simultaneously', () async {
      var btcCount = 0;
      var ethCount = 0;
      final btcCoins = <String>{};
      final ethCoins = <String>{};

      final btcHandle = ws.subscribeBbo('BTC', (update) {
        btcCount++;
        btcCoins.add(update.coin);
      });

      final ethHandle = ws.subscribeBbo('ETH', (update) {
        ethCount++;
        ethCoins.add(update.coin);
      });

      await Future.delayed(Duration(seconds: 5));

      expect(btcCount, greaterThan(0), reason: 'Should receive BTC subscription updates');
      expect(ethCount, greaterThan(0), reason: 'Should receive ETH subscription updates');

      print('✓ BTC subscription: $btcCount updates (coins: ${btcCoins.join(", ")})');
      print('✓ ETH subscription: $ethCount updates (coins: ${ethCoins.join(", ")})');

      await btcHandle.cancel();
      await ethHandle.cancel();
    });

    test('BBO updates have valid structure', () async {
      BboUpdate? update;

      final handle = ws.subscribeBbo('BTC', (bboUpdate) {
        update = bboUpdate;
      });

      // Wait for at least one update
      var attempts = 0;
      while (update == null && attempts < 20) {
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;
      }

      expect(update, isNotNull, reason: 'Should receive at least one update');

      if (update != null) {
        // Validate structure - coin should be valid (not empty)
        expect(update!.coin, isNotEmpty);
        print('  Received BBO for: ${update!.coin}');

        expect(update!.time, greaterThan(0));
        expect(update!.bbo.length, 2);

        final bid = update!.bbo[0];
        final ask = update!.bbo[1];

        // Bid and ask should have valid prices and sizes
        expect(double.parse(bid.px), greaterThan(0));
        expect(double.parse(bid.sz), greaterThan(0));
        expect(double.parse(ask.px), greaterThan(0));
        expect(double.parse(ask.sz), greaterThan(0));

        // Ask should be higher than bid (or equal in rare cases)
        expect(double.parse(ask.px), greaterThanOrEqualTo(double.parse(bid.px)));

        print('✓ BBO structure validated');
        print('  Bid: ${bid.px} @ ${bid.sz}');
        print('  Ask: ${ask.px} @ ${ask.sz}');
        print('  Spread: \$${double.parse(ask.px) - double.parse(bid.px)}');
      }

      await handle.cancel();
    });
  });
}
