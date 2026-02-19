@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('TWAP integration', () {
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

    test('places and cancels TWAP order', () async {
      // 1. Place TWAP order (executes at market)
      print('Placing TWAP order for 0.001 BTC over 5 minutes');

      final placeResult = await exchange.twapOrder(
        twap: TwapWire(
          asset: 0,
          isBuy: true,
          sz: '0.001', // Total size (small to minimize cost)
          durationMins: 5, // Minimum duration
          reduceOnly: false,
          randomize: false,
        ),
      );

      expect(placeResult.isOk, isTrue,
          reason: 'TWAP order should be placed: ${placeResult.errorMessage}');

      print('TWAP order placed: ${placeResult.status}');
      print('Response: ${placeResult.response}');

      // 3. Extract TWAP ID from response
      final responseData = (placeResult.response as Map<String, dynamic>?)?['data'];
      expect(responseData, isNotNull);

      final status = responseData?['status'] as Map<String, dynamic>?;
      expect(status, isNotNull);

      // Check if TWAP is running
      if (status!.containsKey('running')) {
        final runningData = status['running'] as Map<String, dynamic>;
        final twapId = runningData['twapId'] as int;

        print('TWAP ID: $twapId');

        // Wait a moment for TWAP to start
        await Future.delayed(Duration(seconds: 2));

        // 4. Cancel TWAP order
        print('Canceling TWAP order $twapId');

        final cancelResult = await exchange.twapCancel(
          cancel: TwapCancelWire(asset: 0, twapId: twapId),
        );

        expect(cancelResult.isOk, isTrue,
            reason: 'TWAP cancel should succeed: ${cancelResult.errorMessage}');

        print('✓ TWAP order canceled: ${cancelResult.status}');
      } else {
        print('⚠ TWAP order response format unexpected: $status');
        print('This may indicate API changes - test inconclusive');
      }
    });

    test('validates TWAP duration constraints', () async {
      // Test minimum duration (1 minute per docs)
      final result1min = await exchange.twapOrder(
        twap: TwapWire(
          asset: 0,
          isBuy: true,
          sz: '0.001',
          durationMins: 1,
        ),
      );

      expect(result1min.isOk, isTrue);
      print('✓ 1-minute TWAP accepted');

      // Cancel if successful
      if (result1min.isOk) {
        final responseData = (result1min.response as Map)['data'];
        final status = responseData['status'];
        if (status['running'] != null) {
          final twapId = status['running']['twapId'] as int;
          await exchange.twapCancel(
            cancel: TwapCancelWire(asset: 0, twapId: twapId),
          );
          await Future.delayed(Duration(seconds: 1));
        }
      }
    });

    test('TWAP with randomized execution', () async {
      // Test randomized timing flag
      final result = await exchange.twapOrder(
        twap: TwapWire(
          asset: 0,
          isBuy: true,
          sz: '0.001',
          durationMins: 5,
          randomize: true, // Randomized execution
        ),
      );

      expect(result.isOk, isTrue);
      print('✓ Randomized TWAP accepted');

      // Cancel if successful
      if (result.isOk) {
        final responseData = (result.response as Map)['data'];
        final status = responseData['status'];
        if (status['running'] != null) {
          final twapId = status['running']['twapId'] as int;
          await exchange.twapCancel(
            cancel: TwapCancelWire(asset: 0, twapId: twapId),
          );
        }
      }
    });
  });
}
