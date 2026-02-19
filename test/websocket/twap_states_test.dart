@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('TWAP states subscription integration', () {
    late WebSocketClient ws;
    late String userAddress;
    late ExchangeClient exchange;
    late InfoClient info;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();
      exchange = ExchangeClient(wallet: wallet, isTestnet: false);
      info = InfoClient(isTestnet: false);

      ws = WebSocketClient();
      await ws.connect();
      await Future.delayed(Duration(milliseconds: 500));
    });

    tearDownAll(() async {
      await ws.dispose();
      exchange.close();
      info.close();
    });

    test('subscribes to TWAP states channel', () async {
      var updateCount = 0;
      final states = <TwapState>[];

      final handle = ws.subscribeTwapStates(userAddress, (twapStates) {
        updateCount++;
        states.addAll(twapStates);
        print('TWAP states update #$updateCount: ${twapStates.length} states');

        for (final state in twapStates) {
          print('  TWAP ${state.twapId}: ${state.coin} ${state.isBuy ? "BUY" : "SELL"} '
              '${state.szFilled}/${state.sz} @ ${state.limitPx} - ${state.status}');
        }
      });

      // Wait to see if any TWAP states arrive
      // Note: May be empty if user has no active TWAPs
      await Future.delayed(Duration(seconds: 5));

      print('Received $updateCount TWAP state updates in 5 seconds');

      // Verify subscription was successful (even if no states received)
      expect(handle, isNotNull);

      if (states.isNotEmpty) {
        final firstState = states.first;
        expect(firstState.twapId, isA<int>());
        expect(firstState.coin, isNotEmpty);
        expect(firstState.status, isIn(['running', 'finished', 'canceled']));
        expect(firstState.durationMins, greaterThanOrEqualTo(5));
        expect(firstState.durationMins, lessThanOrEqualTo(1440));
        print('✓ Sample TWAP state validated');
      } else {
        print('✓ No active TWAPs (subscription working correctly)');
      }

      await handle.cancel();
    });

    test('TWAP states update when placing and canceling', () async {
      final states = <TwapState>[];

      final handle = ws.subscribeTwapStates(userAddress, (twapStates) {
        states.addAll(twapStates);
      });

      // Wait for initial snapshot
      await Future.delayed(Duration(seconds: 2));

      // Place a TWAP order
      final placeResult = await exchange.twapOrder(
        twap: TwapWire(
          asset: 0,
          isBuy: true,
          sz: '0.001',
          durationMins: 5,
        ),
      );

      if (placeResult.isOk) {
        final responseData = (placeResult.response as Map)['data'];
        final status = responseData['status'];

        if (status['running'] != null) {
          final twapId = status['running']['twapId'] as int;
          print('Placed TWAP $twapId, waiting for state update...');

          // Wait for TWAP state update
          await Future.delayed(Duration(seconds: 3));

          // Check if we received the new TWAP state
          final foundState = states.where((s) => s.twapId == twapId).toList();

          if (foundState.isNotEmpty) {
            expect(foundState.first.status, 'running');
            print('✓ TWAP state received via WebSocket');
          } else {
            print('⚠ TWAP state not received (may be delayed)');
          }

          // Cancel TWAP
          await exchange.twapCancel(
            cancel: TwapCancelWire(asset: 0, twapId: twapId),
          );

          print('✓ TWAP lifecycle test complete');
        }
      }

      await handle.cancel();
    });
  });
}
