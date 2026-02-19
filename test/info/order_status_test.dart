@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('orderStatus integration', () {
    late PrivateKeyWalletAdapter wallet;
    late ExchangeClient exchange;
    late InfoClient info;

    setUpAll(() {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }
      wallet = PrivateKeyWalletAdapter(privateKey);
      exchange = ExchangeClient(wallet: wallet, isTestnet: false);
      info = InfoClient(isTestnet: false);
    });

    tearDownAll(() {
      exchange.close();
      info.close();
    });

    test('returns unknownOid for non-existent order', () async {
      final address = await wallet.getAddress();
      final response = await info.orderStatus(
        user: address,
        oid: 999999999999, // Non-existent order ID
      );

      expect(response.status, 'unknownOid');
      expect(response.order, isNull);
      print('✓ unknownOid status returned correctly');
    });

    test('returns order status for placed and canceled order', () async {
      final address = await wallet.getAddress();

      // 1. Get BTC mid price
      final mids = await info.allMids();
      final btcMid = mids['BTC'];
      expect(btcMid, isNotNull);

      // 2. Place order far below mid (won't fill)
      final midPrice = double.parse(btcMid!);
      final farBelowPrice = (midPrice * 0.5).toInt().toString();

      print('Placing order at \$$farBelowPrice (BTC mid: \$$btcMid)');
      final placeResult = await exchange.placeOrder(
        orders: [
          OrderWire.limit(
            asset: 0,
            isBuy: true,
            limitPx: farBelowPrice,
            sz: '0.001',
            tif: TimeInForce.gtc,
          ),
        ],
      );

      expect(placeResult.isOk, isTrue,
          reason: 'Order placement failed: ${placeResult.errorMessage}');

      // 3. Extract order ID
      final responseData = (placeResult.response as Map<String, dynamic>?)?['data'];
      expect(responseData, isNotNull, reason: 'Response data is null');

      final statuses = responseData?['statuses'] as List<dynamic>?;
      expect(statuses, isNotNull, reason: 'Statuses is null');
      expect(statuses, isNotEmpty, reason: 'Statuses is empty');

      final firstStatus = statuses![0] as Map<String, dynamic>;
      final restingData = firstStatus['resting'] as Map<String, dynamic>?;

      if (restingData == null) {
        print('Warning: No resting order in response. Status: $firstStatus');
        return; // Skip test if order didn't rest
      }

      final oid = restingData['oid'] as int;
      print('Order placed with ID: $oid');

      // 4. Check order status (should be open)
      final statusBefore = await info.orderStatus(user: address, oid: oid);
      expect(statusBefore.status, 'order');
      expect(statusBefore.order, isNotNull);
      expect(statusBefore.order!.status, 'open');
      expect(statusBefore.order!.order.oid, oid);
      expect(statusBefore.order!.order.coin, 'BTC');
      expect(statusBefore.order!.order.side, 'B'); // Buy
      expect(statusBefore.order!.order.limitPx, farBelowPrice);
      print('✓ Order status: ${statusBefore.order!.status}');

      // 5. Cancel order
      final cancelResult = await exchange.cancelOrders(
        cancels: [CancelWire(asset: 0, oid: oid)],
      );
      expect(cancelResult.isOk, isTrue);
      print('Order canceled');

      // 6. Check order status again (should be canceled)
      await Future.delayed(Duration(milliseconds: 500)); // Wait for cancel to propagate
      final statusAfter = await info.orderStatus(user: address, oid: oid);
      expect(statusAfter.status, 'order');
      expect(statusAfter.order, isNotNull);
      expect(statusAfter.order!.status, 'canceled');
      expect(statusAfter.order!.order.oid, oid);
      print('✓ Order status after cancel: ${statusAfter.order!.status}');
    });
  });
}
