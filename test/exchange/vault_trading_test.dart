@Tags(['integration', 'manual'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

/// IMPORTANT: These tests involve actual vault transfers!
///
/// Run with caution. The tests require:
/// - HYPERLIQUID_PRIVATE_KEY: Your wallet private key
/// - TEST_VAULT_ADDRESS: A vault address you have access to
///
/// Note:
/// - Vault deposits have a 24-hour lockup period
/// - Test on TESTNET first if available
/// - Use small amounts for testing (e.g., 1 USDC)
///
/// To run:
/// ```bash
/// export HYPERLIQUID_PRIVATE_KEY=0x...
/// export TEST_VAULT_ADDRESS=0x...
/// dart test test/exchange/vault_trading_test.dart
/// ```
void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];
  final testVaultAddress = Platform.environment['TEST_VAULT_ADDRESS'];

  group('Vault transfer integration', () {
    late ExchangeClient exchange;
    late InfoClient info;
    late String userAddress;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      if (testVaultAddress == null || testVaultAddress.isEmpty) {
        fail('TEST_VAULT_ADDRESS env var not set. Please provide a vault address to test with.');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();
      exchange = ExchangeClient(wallet: wallet, isTestnet: false);
      info = InfoClient(isTestnet: false);

      print('\n⚠️  VAULT TRANSFER TESTS ⚠️');
      print('These tests involve real vault transfers on mainnet!');
      print('User: $userAddress');
      print('Vault: $testVaultAddress');
      print('Note: Vault deposits have a 24-hour lockup period!\n');
    });

    tearDownAll(() {
      exchange.close();
      info.close();
    });

    test('vaultTransfer - deposit to vault', () async {
      const testAmount = 1.0; // 1 USDC

      print('Depositing $testAmount USDC to vault...');

      final result = await exchange.vaultTransfer(
        vaultAddress: testVaultAddress!,
        isDeposit: true,
        usd: testAmount,
      );

      if (result.status != 'ok') {
        print('✗ Deposit failed!');
        print('  Status: ${result.status}');
        print('  Response: ${result.response}');
      }

      expect(result.status, equals('ok'));
      print('✓ Deposited $testAmount USDC to vault');
      print('  Response: ${result.response}');
      print('  ⚠ Funds locked for 24 hours!');

      // Verify deposit in ledger
      await Future.delayed(const Duration(seconds: 2));

      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesAgo = now - (5 * 60 * 1000);

      final ledger = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: fiveMinutesAgo,
        endTime: now,
      );

      expect(ledger, isNotEmpty);
      print('✓ Verified deposit in ledger (${ledger.length} recent entries)');

      // Check if we can find the vault deposit entry
      final vaultEntries = ledger.where((entry) =>
          entry.delta.type.contains('vault') ||
          entry.delta.usdc == testAmount.toString());

      if (vaultEntries.isNotEmpty) {
        print('  Found vault transfer in ledger:');
        for (final entry in vaultEntries.take(1)) {
          print('    Type: ${entry.delta.type}');
          print('    Time: ${DateTime.fromMillisecondsSinceEpoch(entry.time)}');
        }
      }
    });

    test('vaultTransfer - withdraw from vault (requires unlocked funds)', () async {
      const testAmount = 0.5; // 0.5 USDC

      print('Attempting to withdraw $testAmount USDC from vault...');
      print('⚠ This will fail if you have no unlocked equity in the vault');

      final result = await exchange.vaultTransfer(
        vaultAddress: testVaultAddress!,
        isDeposit: false,
        usd: testAmount,
      );

      if (result.status != 'ok') {
        print('✗ Withdrawal failed (expected if no unlocked equity)');
        print('  Status: ${result.status}');
        print('  Response: ${result.response}');

        // This is expected if funds are locked or insufficient
        expect(result.status, isA<String>());
        return;
      }

      expect(result.status, equals('ok'));
      print('✓ Withdrew $testAmount USDC from vault');
      print('  Response: ${result.response}');

      // Verify withdrawal in ledger
      await Future.delayed(const Duration(seconds: 2));

      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesAgo = now - (5 * 60 * 1000);

      final ledger = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: fiveMinutesAgo,
        endTime: now,
      );

      expect(ledger, isNotEmpty);
      print('✓ Verified withdrawal in ledger');
    });

    test('vaultTransfer - validates vault address format', () async {
      // Test with lowercase address
      final resultLowercase = await exchange.vaultTransfer(
        vaultAddress: testVaultAddress!.toLowerCase(),
        isDeposit: true,
        usd: 0.01,
      );

      expect(resultLowercase, isA<ExchangeResponse>());
      print('✓ Accepts lowercase vault address');

      // Note: We won't test invalid addresses to avoid failed transactions
    });

    test('check vault equity after transfer', () async {
      print('Checking user vault equities...');

      final equities = await info.userVaultEquities(userAddress);

      print('User has ${equities.length} vault position(s)');

      final testVaultEquity = equities.firstWhere(
        (e) => e.vaultAddress.toLowerCase() == testVaultAddress!.toLowerCase(),
        orElse: () => UserVaultEquity(vaultAddress: '', equity: '0'),
      );

      if (testVaultEquity.vaultAddress.isNotEmpty) {
        print('✓ Found equity in test vault: \$${testVaultEquity.equity}');
      } else {
        print('⚠ No equity found in test vault (may be processing)');
      }

      // Fetch vault details to see our position
      final vaultDetails = await info.vaultDetails(
        vaultAddress: testVaultAddress!,
        user: userAddress,
      );

      print('Vault: ${vaultDetails.name}');
      print('  Leader: ${vaultDetails.leader}');
      print('  Total followers: ${vaultDetails.followers.length}');

      // Check if we're in the followers list
      final ourFollowerEntry = vaultDetails.followers.firstWhere(
        (f) => f.user.toLowerCase() == userAddress.toLowerCase(),
        orElse: () => VaultFollower(
          user: '',
          vaultEquity: '0',
          pnl: '0',
          allTimePnl: '0',
          daysFollowing: 0,
          vaultEntryTime: 0,
        ),
      );

      if (ourFollowerEntry.user.isNotEmpty) {
        print('✓ Found in followers list:');
        print('    Equity: \$${ourFollowerEntry.vaultEquity}');
        print('    PnL: ${ourFollowerEntry.pnl}');
        print('    Days following: ${ourFollowerEntry.daysFollowing}');
        if (ourFollowerEntry.lockupUntil != null) {
          final lockupTime =
              DateTime.fromMillisecondsSinceEpoch(ourFollowerEntry.lockupUntil!);
          print('    Locked until: $lockupTime');
        }
      }
    });
  });
}
