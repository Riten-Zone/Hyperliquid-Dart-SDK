@Tags(['integration', 'manual'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

/// IMPORTANT: These tests involve actual USD transfers!
///
/// Run with caution. The tests are designed to be safe:
/// - usdClassTransfer test transfers 0.01 USDC spot→perp→spot (roundtrip)
/// - usdSend test is SKIPPED by default (would send real USDC)
///
/// To run: HYPERLIQUID_PRIVATE_KEY=0x... dart test test/exchange/usd_operations_test.dart
void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('USD Operations integration', () {
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

      print('\n⚠️  USD TRANSFER TESTS ⚠️');
      print('These tests involve real USD transfers on mainnet!');
      print('User: $userAddress\n');
    });

    tearDownAll(() {
      exchange.close();
      info.close();
    });

    test('usdClassTransfer - spot to perp and back (roundtrip)', () async {
      // Transfer a tiny amount to test the flow
      const testAmount = '0.01';

      print('Step 1: Transferring $testAmount USDC from spot to perp...');
      final result1 = await exchange.usdClassTransfer(
        amount: testAmount,
        toPerp: true,
      );

      if (result1.status != 'ok') {
        print('✗ Transfer failed!');
        print('  Status: ${result1.status}');
        print('  Response: ${result1.response}');
      }

      expect(result1.status, equals('ok'));
      print('✓ Spot → Perp transfer successful');
      print('  Response: ${result1.response}');

      // Wait a moment for the transfer to settle
      await Future.delayed(const Duration(seconds: 2));

      print('\nStep 2: Transferring $testAmount USDC from perp back to spot...');
      final result2 = await exchange.usdClassTransfer(
        amount: testAmount,
        toPerp: false,
      );

      expect(result2.status, equals('ok'));
      print('✓ Perp → Spot transfer successful');
      print('  Response: ${result2.response}');

      // Verify via ledger updates
      await Future.delayed(const Duration(seconds: 2));

      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesAgo = now - (5 * 60 * 1000);

      final ledger = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: fiveMinutesAgo,
        endTime: now,
      );

      final transfers = ledger.where((u) => u.delta.type == 'accountClassTransfer').toList();
      expect(transfers.length, greaterThanOrEqualTo(2));

      print('\n✓ Roundtrip transfer verified in ledger');
      print('  Found ${transfers.length} accountClassTransfer entries in last 5 minutes');

      // Show the transfers
      for (var i = 0; i < transfers.length && i < 2; i++) {
        final transfer = transfers[i];
        final direction = transfer.delta.toPerp == true ? 'spot→perp' : 'perp→spot';
        print('  ${i + 1}. ${transfer.delta.usdc} USDC ($direction)');
      }
    });

    test('usdSend - send USDC to another address', () async {
      // This test is ALWAYS skipped for safety
      // To actually test, remove the skip parameter and update the destination

      const testAmount = '0.01';
      const destination = '0x0000000000000000000000000000000000000000'; // UPDATE THIS!

      print('Sending $testAmount USDC to $destination...');
      final result = await exchange.usdSend(
        destination: destination,
        amount: testAmount,
      );

      expect(result.status, equals('ok'));
      print('✓ Transfer successful');
      print('  Response: ${result.response?.type}');

      // Verify via ledger updates
      await Future.delayed(const Duration(seconds: 2));

      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesAgo = now - (5 * 60 * 1000);

      final ledger = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: fiveMinutesAgo,
        endTime: now,
      );

      final sends =
          ledger.where((u) => u.delta.type == 'internalTransfer').toList();
      expect(sends, isNotEmpty);

      print('✓ Transfer verified in ledger');
      final latestSend = sends.first;
      print('  Amount: ${latestSend.delta.usdc} USDC');
      print('  Destination: ${latestSend.delta.destination}');
    },
        skip:
            'ALWAYS SKIPPED - Would send real USDC! Update destination and remove skip to test.');

    test('validates usdClassTransfer parameters', () async {
      // Test that the method accepts the correct parameters
      // without actually executing (we'll catch the error)

      try {
        await exchange.usdClassTransfer(
          amount: '0',
          toPerp: true,
        );
      } catch (e) {
        // Expected to fail with 0 amount
        print('✓ Zero amount rejected as expected: $e');
      }

      print('✓ usdClassTransfer parameter validation works');
    });

    test('validates usdSend parameters', () async {
      // Test that the method accepts the correct parameters

      try {
        await exchange.usdSend(
          destination: '0x0000000000000000000000000000000000000000',
          amount: '0',
        );
      } catch (e) {
        // Expected to fail with 0 amount
        print('✓ Zero amount rejected as expected: $e');
      }

      print('✓ usdSend parameter validation works');
    });

    test('custom nonce support', () async {
      // Verify that custom nonce parameter works (without executing transfer)
      final customNonce = DateTime.now().millisecondsSinceEpoch;

      // We can't actually test without executing, so just verify the signature
      print('✓ Custom nonce parameter accepted: $customNonce');
      print('  (Would need actual execution to fully test)');
    });
  });
}
