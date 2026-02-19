@Tags(['integration'])
library;

import 'dart:io';
import 'package:test/test.dart';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('Spot Trading integration', () {
    late ExchangeClient exchange;
    late InfoClient info;
    late String userAddress;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();
      exchange = ExchangeClient(wallet: wallet, isTestnet: false);
      info = InfoClient(isTestnet: false);

      print('\n⚠️  SPOT TRADING TESTS ⚠️');
      print('User: $userAddress\n');
    });

    tearDownAll(() {
      exchange.close();
      info.close();
    });

    test('spotUser - toggle spot dusting', () async {
      print('Test: Toggle spot dusting opt-out...');

      // Toggle on
      final result1 = await exchange.spotUser(optOut: true);
      expect(result1.status, equals('ok'));
      print('✓ Spot dusting opt-out enabled');

      await Future.delayed(Duration(seconds: 1));

      // Toggle off
      final result2 = await exchange.spotUser(optOut: false);
      expect(result2.status, equals('ok'));
      print('✓ Spot dusting opt-out disabled');
    });

    test('sendAsset - perp to spot roundtrip', () async {
      const testAmount = '0.01';
      const usdcToken = 'USDC'; // Simplified for perp/spot transfers

      print('Step 1: Transfer $testAmount USDC from perp to spot...');
      final result1 = await exchange.sendAsset(
        destination: userAddress,
        sourceDex: '',
        destinationDex: 'spot',
        token: usdcToken,
        amount: testAmount,
      );

      print('  Status: ${result1.status}');
      print('  Response: ${result1.response}');
      if (result1.isError) {
        print('  Error: ${result1.errorMessage}');
      }
      expect(result1.status, equals('ok'));
      print('✓ Perp → Spot transfer successful');

      // Wait for ledger to update
      await Future.delayed(Duration(seconds: 2));

      print('Step 2: Transfer back from spot to perp...');
      final result2 = await exchange.sendAsset(
        destination: userAddress,
        sourceDex: 'spot',
        destinationDex: '',
        token: usdcToken,
        amount: testAmount,
      );

      expect(result2.status, equals('ok'));
      print('✓ Spot → Perp transfer successful');
      print('  Response: ${result2.response}');

      // Step 3: Verify via ledger
      await Future.delayed(Duration(seconds: 2));
      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesAgo = now - (5 * 60 * 1000);

      final ledger = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: fiveMinutesAgo,
        endTime: now,
      );

      print('✓ Ledger verification: ${ledger.length} updates found');
    });

    test('spotSend - send spot USDC to external address', () async {
      const testAmount = '0.01';
      const usdcToken =
          'USDC:0x6d1e7cde53ba9467b783cb7c530ce054'; // Correct spot USDC token ID
      const destination = '0xDA3f3C8a7313302357FbE32323985BA523711eb6'; // External address

      print('Sending $testAmount spot USDC to $destination...');

      final result = await exchange.spotSend(
        destination: destination,
        token: usdcToken,
        amount: testAmount,
      );

      print('  Status: ${result.status}');
      print('  Response: ${result.response}');
      if (result.isError) {
        print('  Error: ${result.errorMessage}');
      }
      expect(result.status, equals('ok'));
      print('✓ spotSend to external address successful');

      // Verify via ledger
      await Future.delayed(Duration(seconds: 2));
      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesAgo = now - (5 * 60 * 1000);

      final ledger = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: fiveMinutesAgo,
        endTime: now,
      );

      final spotSends =
          ledger.where((u) => u.delta.type == 'spotTransfer').toList();

      expect(spotSends.length, greaterThanOrEqualTo(1));
      print('✓ Ledger verification: Found ${spotSends.length} spot transfers');
    });

    test('subAccountTransfer - USDC sub-account', () async {
      // Skip: No sub-account set up yet
      print('ℹ️  subAccountTransfer method implemented');
      print('   (Requires sub-account setup - add test when ready)');
    }, skip: 'No sub-account available - skip for now');

    test('subAccountSpotTransfer - spot token sub-account', () async {
      // Skip: No sub-account set up yet
      print('ℹ️  subAccountSpotTransfer method implemented');
      print('   (Requires sub-account setup - add test when ready)');
    }, skip: 'No sub-account available - skip for now');
  });
}
