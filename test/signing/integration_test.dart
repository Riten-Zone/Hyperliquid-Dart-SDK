@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

/// Live integration test against Hyperliquid mainnet.
///
/// Requires:
///   - `HYPERLIQUID_PRIVATE_KEY` env var set to an EOA private key (hex, with or without 0x)
///
/// Run with:
///   dart test --tags integration
void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('Live mainnet integration', () {
    late PrivateKeyWalletAdapter wallet;
    late ExchangeClient exchange;
    late InfoClient info;

    setUpAll(() {
      if (privateKey == null || privateKey.isEmpty) {
        fail(
          'HYPERLIQUID_PRIVATE_KEY env var not set. '
          'Run: HYPERLIQUID_PRIVATE_KEY=0x... dart test --tags integration',
        );
      }
      wallet = PrivateKeyWalletAdapter(privateKey);
      exchange = ExchangeClient(wallet: wallet, isTestnet: false);
      info = InfoClient(isTestnet: false);
    });

    tearDownAll(() {
      exchange.close();
      info.close();
    });

    test('wallet derives a valid address', () async {
      final address = await wallet.getAddress();
      expect(address, startsWith('0x'));
      expect(address.length, 42);
      print('Wallet address: $address');
    });

    test('can fetch clearinghouse state for wallet', () async {
      final address = await wallet.getAddress();
      final state = await info.clearinghouseState(address);
      print('Account value: ${state.accountValue}');
      print('Positions: ${state.assetPositions.length}');
      expect(state, isNotNull);
    });

    test('updateLeverage succeeds (non-destructive)', () async {
      // updateLeverage is idempotent and non-destructive — safe for live testing.
      // Sets BTC (asset 0) to 10x cross margin.
      try {
        final result = await exchange.updateLeverage(
          asset: 0,
          leverage: 10,
          isCross: true,
        );
        print('updateLeverage result: ${result.status}');
        expect(result.isError, isFalse);
      } on HyperliquidApiException catch (e) {
        // "Leverage already set" is an acceptable response
        print('updateLeverage response: ${e.message}');
        expect(
          e.message.toLowerCase(),
          anyOf(
            contains('leverage'),
            contains('already'),
            contains('success'),
          ),
        );
      }
    });

    test('can fetch open orders', () async {
      final address = await wallet.getAddress();
      final orders = await info.openOrders(address);
      print('Open orders: ${orders.length}');
      expect(orders, isA<List<OpenOrder>>());
    });

    test('place and cancel a limit order', () async {
      // 1. Get BTC mid price
      final mids = await info.allMids();
      final btcMid = mids['BTC'];
      expect(btcMid, isNotNull, reason: 'BTC mid price should exist');
      print('BTC mid price: $btcMid');

      // 2. Place a tiny limit buy at 50% below mid (won't fill)
      final midPrice = double.parse(btcMid!);
      final farBelowPrice = (midPrice * 0.5).toInt().toString();
      print('Placing limit buy at: $farBelowPrice');

      final placeResult = await exchange.placeOrder(
        orders: [
          OrderWire.limit(
            asset: 0, // BTC
            isBuy: true,
            limitPx: farBelowPrice,
            sz: '0.001',
            tif: TimeInForce.gtc,
          ),
        ],
      );
      print('Place order result: ${placeResult.status}');
      expect(placeResult.isOk, isTrue, reason: 'Order placement should succeed');

      // 3. Extract order ID from response
      final statuses = (placeResult.response as Map<String, dynamic>?)?['data']
          ?['statuses'] as List<dynamic>?;
      expect(statuses, isNotNull, reason: 'Response should contain statuses');
      expect(statuses, isNotEmpty, reason: 'Should have at least one status');
      print('Order statuses: $statuses');

      // Extract oid — format varies: {resting: {oid: 123}} or {filled: {oid: 123}}
      final firstStatus = statuses![0] as Map<String, dynamic>;
      int? oid;
      if (firstStatus.containsKey('resting')) {
        oid = (firstStatus['resting'] as Map<String, dynamic>)['oid'] as int;
      } else if (firstStatus.containsKey('filled')) {
        // Shouldn't happen at 50% below mid, but handle it
        oid = (firstStatus['filled'] as Map<String, dynamic>)['oid'] as int;
      }
      expect(oid, isNotNull, reason: 'Should get an order ID');
      print('Order ID: $oid');

      // 4. Verify order exists in open orders
      final address = await wallet.getAddress();
      final openOrders = await info.openOrders(address);
      final found = openOrders.any((o) => o.oid == oid);
      expect(found, isTrue, reason: 'Order should appear in open orders');

      // 5. Cancel the order
      final cancelResult = await exchange.cancelOrders(
        cancels: [CancelWire(asset: 0, oid: oid!)],
      );
      print('Cancel result: ${cancelResult.status}');
      expect(cancelResult.isOk, isTrue, reason: 'Cancellation should succeed');

      // 6. Verify order is gone
      final afterCancel = await info.openOrders(address);
      final stillThere = afterCancel.any((o) => o.oid == oid);
      expect(stillThere, isFalse, reason: 'Order should be cancelled');
      print('Order successfully placed and cancelled.');
    });
  });
}
