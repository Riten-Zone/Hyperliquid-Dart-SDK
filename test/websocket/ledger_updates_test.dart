@Tags(['integration'])
library;

import 'dart:async';
import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

/// Integration tests for WebSocket ledger update subscriptions.
///
/// These tests:
/// 1. Subscribe to real-time ledger updates
/// 2. Perform USD transfers to generate events
/// 3. Verify updates are received via WebSocket
/// 4. Test subscription cleanup
///
/// Run with: HYPERLIQUID_PRIVATE_KEY=0x... dart test test/websocket/ledger_updates_test.dart
void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('WebSocket ledger updates integration', () {
    late WebSocketClient ws;
    late ExchangeClient exchange;
    late String userAddress;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();
      ws = WebSocketClient(isTestnet: false);
      exchange = ExchangeClient(wallet: wallet, isTestnet: false);

      await ws.connect();
      print('\n📡 WebSocket Ledger Updates Test');
      print('User: $userAddress\n');
    });

    tearDownAll(() async {
      await ws.dispose();
      exchange.close();
    });

    test('receives ledger updates in real-time', () async {
      final updates = <LedgerUpdate>[];
      final completer = Completer<void>();

      // Subscribe to ledger updates
      print('Subscribing to ledger updates...');
      final handle = ws.subscribeUserNonFundingLedgerUpdates(
        userAddress,
        (newUpdates) {
          print('Received ${newUpdates.length} ledger update(s)');
          for (final update in newUpdates) {
            print('  Type: ${update.delta.type}');
            print('  Time: ${DateTime.fromMillisecondsSinceEpoch(update.time)}');
            if (update.delta.usdc != null) {
              print('  Amount: ${update.delta.usdc} USDC');
            }
            if (update.delta.toPerp != null) {
              final direction = update.delta.toPerp == true ? 'spot→perp' : 'perp→spot';
              print('  Direction: $direction');
            }
            print('  Hash: ${update.hash}');
            print('');
          }

          updates.addAll(newUpdates);

          // Complete after receiving at least 2 updates (roundtrip)
          if (updates.length >= 2 && !completer.isCompleted) {
            completer.complete();
          }
        },
      );

      expect(handle, isA<SubscriptionHandle>());
      print('✓ Subscription active\n');

      // Wait for initial connection
      await Future.delayed(const Duration(seconds: 2));

      // Perform USD transfer to generate ledger events
      const testAmount = '0.01';

      print('Step 1: Transferring $testAmount USDC (spot→perp)...');
      final result1 = await exchange.usdClassTransfer(
        amount: testAmount,
        toPerp: true,
      );
      expect(result1.status, equals('ok'));
      print('✓ Transfer 1 sent\n');

      // Wait a bit, then transfer back
      await Future.delayed(const Duration(seconds: 3));

      print('Step 2: Transferring $testAmount USDC (perp→spot)...');
      final result2 = await exchange.usdClassTransfer(
        amount: testAmount,
        toPerp: false,
      );
      expect(result2.status, equals('ok'));
      print('✓ Transfer 2 sent\n');

      // Wait for updates to arrive via WebSocket
      print('Waiting for WebSocket updates...');
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          fail('Timed out waiting for ledger updates (received ${updates.length})');
        },
      );

      // Verify updates
      expect(updates.length, greaterThanOrEqualTo(2));
      print('\n✓ Received ${updates.length} ledger updates via WebSocket');

      // Verify structure
      for (final update in updates) {
        expect(update.time, greaterThan(0));
        expect(update.hash, startsWith('0x'));
        expect(update.delta.type, isNotEmpty);
      }

      // Cleanup
      await handle.cancel();
      print('✓ Unsubscribed successfully');
    });

    test('subscription cleanup works', () async {
      var callCount = 0;

      final handle = ws.subscribeUserNonFundingLedgerUpdates(
        userAddress,
        (updates) {
          callCount++;
        },
      );

      await Future.delayed(const Duration(seconds: 1));

      // Unsubscribe
      await handle.cancel();
      final initialCount = callCount;

      // Wait and verify no more updates
      await Future.delayed(const Duration(seconds: 2));

      // Perform a transfer (should not trigger handler)
      await exchange.usdClassTransfer(amount: '0.01', toPerp: true);
      await Future.delayed(const Duration(seconds: 2));

      expect(callCount, equals(initialCount),
          reason: 'Handler should not be called after unsubscribe');

      print('✓ Subscription cleanup verified');
    });
  });
}
