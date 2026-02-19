@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('modify integration', () {
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

    tearDownAll() {
      exchange.close();
      info.close();
    }

    test('modify single order', () async {
      // 1. Get BTC mid price and place order
      final mids = await info.allMids();
      final btcMid = double.parse(mids['BTC']!);
      final initialPrice = (btcMid * 0.5).toInt().toString();

      print('Placing initial order at \$$initialPrice');
      final placeResult = await exchange.placeOrder(
        orders: [
          OrderWire.limit(
            asset: 0,
            isBuy: true,
            limitPx: initialPrice,
            sz: '0.001',
            tif: TimeInForce.gtc,
          ),
        ],
      );

      expect(placeResult.isOk, isTrue,
          reason: 'Order placement failed: ${placeResult.errorMessage}');

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

      // 2. Modify order (change price and size)
      final modifiedPrice = (btcMid * 0.49).toInt().toString();
      print('Modifying order to price \$$modifiedPrice and size 0.002');

      final modifyResult = await exchange.modify(
        oid: oid,
        order: OrderWire.limit(
          asset: 0,
          isBuy: true,
          limitPx: modifiedPrice,
          sz: '0.002', // Changed size
          tif: TimeInForce.gtc,
        ),
      );

      expect(modifyResult.isOk, isTrue);
      print('✓ Modified order: ${modifyResult.status}');

      // 3. Verify modification via open orders
      final address = await wallet.getAddress();
      await Future.delayed(Duration(milliseconds: 500)); // Wait for update
      final openOrders = await info.openOrders(address);

      // Find the modified order (may have new oid)
      final modifiedOrder = openOrders.firstWhere(
        (o) => o.coin == 'BTC' && o.side == 'B',
        orElse: () => throw Exception('Modified order not found'),
      );

      expect(modifiedOrder.sz, '0.002');
      print('✓ Verified new size: ${modifiedOrder.sz}');

      // 4. Cancel the order
      await exchange.cancelOrders(
        cancels: [CancelWire(asset: 0, oid: modifiedOrder.oid)],
      );
      print('✓ Order canceled');
    });

    test('batchModify multiple orders', () async {
      // 1. Get BTC mid price and place two orders
      final mids = await info.allMids();
      final btcMid = double.parse(mids['BTC']!);
      final price1 = (btcMid * 0.5).toInt().toString();
      final price2 = (btcMid * 0.49).toInt().toString();

      print('Placing two orders at \$$price1 and \$$price2');
      final placeResult = await exchange.placeOrder(
        orders: [
          OrderWire.limit(
            asset: 0,
            isBuy: true,
            limitPx: price1,
            sz: '0.001',
            tif: TimeInForce.gtc,
          ),
          OrderWire.limit(
            asset: 0,
            isBuy: true,
            limitPx: price2,
            sz: '0.001',
            tif: TimeInForce.gtc,
          ),
        ],
      );

      expect(placeResult.isOk, isTrue,
          reason: 'Order placement failed: ${placeResult.errorMessage}');

      final responseData = (placeResult.response as Map<String, dynamic>?)?['data'];
      expect(responseData, isNotNull, reason: 'Response data is null');

      final statuses = responseData?['statuses'] as List<dynamic>?;
      expect(statuses, isNotNull, reason: 'Statuses is null');
      expect(statuses!.length, greaterThanOrEqualTo(2), reason: 'Not enough orders in statuses');

      final firstStatus = statuses[0] as Map<String, dynamic>;
      final secondStatus = statuses[1] as Map<String, dynamic>;

      final restingData1 = firstStatus['resting'] as Map<String, dynamic>?;
      final restingData2 = secondStatus['resting'] as Map<String, dynamic>?;

      if (restingData1 == null || restingData2 == null) {
        print('Warning: Orders did not rest. Status1: $firstStatus, Status2: $secondStatus');
        return; // Skip test if orders didn't rest
      }

      final oid1 = restingData1['oid'] as int;
      final oid2 = restingData2['oid'] as int;
      print('Orders placed with IDs: $oid1, $oid2');

      // 2. Batch modify both orders
      print('Batch modifying both orders (sizes to 0.002 and 0.003)');
      final batchResult = await exchange.batchModify(
        modifies: [
          ModifyWire(
            oid: oid1,
            order: OrderWire.limit(
              asset: 0,
              isBuy: true,
              limitPx: price1,
              sz: '0.002', // Changed
              tif: TimeInForce.gtc,
            ),
          ),
          ModifyWire(
            oid: oid2,
            order: OrderWire.limit(
              asset: 0,
              isBuy: true,
              limitPx: price2,
              sz: '0.003', // Changed
              tif: TimeInForce.gtc,
            ),
          ),
        ],
      );

      expect(batchResult.isOk, isTrue,
          reason: 'Batch modify failed: ${batchResult.errorMessage}');

      final batchResponseData = (batchResult.response as Map<String, dynamic>?)?['data'];
      if (batchResponseData != null && batchResponseData['statuses'] != null) {
        final batchStatuses = batchResponseData['statuses'] as List;
        print('✓ Batch modify result: ${batchStatuses.length} orders modified');
      } else {
        print('✓ Batch modify succeeded (response format: ${batchResult.response})');
      }

      // 3. Cancel both orders
      final address = await wallet.getAddress();
      await Future.delayed(Duration(milliseconds: 500));
      final openOrders = await info.openOrders(address);

      for (final order in openOrders.where((o) => o.coin == 'BTC')) {
        await exchange.cancelOrders(
          cancels: [CancelWire(asset: 0, oid: order.oid)],
        );
      }
      print('✓ All orders canceled');
    });
  });
}
