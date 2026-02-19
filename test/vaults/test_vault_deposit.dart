import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Test script for depositing to a vault and checking results
///
/// IMPORTANT: This script deposits REAL MONEY on MAINNET!
/// - Uses $5 deposit (protocol minimum)
/// - 24-hour lockup period applies after deposit
/// - Make sure you have at least $5 USDC in your PERP account (not spot!)
///
/// Usage:
/// ```bash
/// export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
/// export TEST_VAULT_ADDRESS=0xVAULT_ADDRESS
/// dart run test_vault_deposit.dart
/// ```

void main() async {
  // Get credentials from environment
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];
  final vaultAddress = Platform.environment['TEST_VAULT_ADDRESS'];

  if (privateKey == null || privateKey.isEmpty) {
    print('❌ Error: HYPERLIQUID_PRIVATE_KEY environment variable not set!');
    print('\nUsage:');
    print('  export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY');
    print('  export TEST_VAULT_ADDRESS=0xVAULT_ADDRESS');
    print('  dart run test_vault_deposit.dart');
    exit(1);
  }

  if (vaultAddress == null || vaultAddress.isEmpty) {
    print('❌ Error: TEST_VAULT_ADDRESS environment variable not set!');
    print('\nUsage:');
    print('  export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY');
    print('  export TEST_VAULT_ADDRESS=0xVAULT_ADDRESS');
    print('  dart run test_vault_deposit.dart');
    print('\nSee VAULT_REFERENCES.md for known vault addresses');
    exit(1);
  }

  final wallet = PrivateKeyWalletAdapter(privateKey);
  final userAddress = await wallet.getAddress();
  final exchange = ExchangeClient(wallet: wallet, isTestnet: false); // MAINNET
  final info = InfoClient(isTestnet: false); // MAINNET

  print('⚠️  MAINNET VAULT DEPOSIT TEST ⚠️\n');
  print('👤 Your Address: $userAddress');
  print('🏦 Vault Address: $vaultAddress');
  print('💰 Deposit Amount: \$5.00 USDC (protocol minimum)\n');

  try {
    // Step 1: Fetch vault details to show what we're depositing into
    print('═══════════════════════════════════════════════════');
    print('📊 VAULT INFORMATION');
    print('═══════════════════════════════════════════════════\n');

    final vaultDetails = await info.vaultDetails(vaultAddress: vaultAddress);
    print('Vault Name: ${vaultDetails.name}');
    print('Leader: ${vaultDetails.leader}');
    print('Past Month Return: ${(vaultDetails.apr * 100).toStringAsFixed(2)}%');
    print('Commission: ${(vaultDetails.leaderCommission * 100).toStringAsFixed(2)}%');
    print('TVL: \$${vaultDetails.portfolio.allTime.accountValueHistory.isNotEmpty ? double.parse(vaultDetails.portfolio.allTime.accountValueHistory.last[1] as String).toStringAsFixed(2) : "N/A"}');
    print('');

    // Step 2: Check current vault positions (before deposit)
    print('═══════════════════════════════════════════════════');
    print('📊 YOUR CURRENT VAULT POSITIONS');
    print('═══════════════════════════════════════════════════\n');

    final beforeEquities = await info.userVaultEquities(userAddress);
    if (beforeEquities.isEmpty) {
      print('No existing vault positions found.\n');
    } else {
      print('Found ${beforeEquities.length} vault position(s):');
      for (final equity in beforeEquities) {
        print('  Vault ${equity.vaultAddress}');
        print('    Equity: \$${equity.equity}\n');
      }
    }

    // Step 3: Check if already in this vault
    final existingPosition = beforeEquities.where((e) =>
      e.vaultAddress.toLowerCase() == vaultAddress.toLowerCase()
    ).firstOrNull;

    if (existingPosition != null) {
      print('⚠️  You already have a position in this vault!');
      print('   Current equity: \$${existingPosition.equity}');
      print('   This deposit will ADD to your existing position.\n');
    }

    // Step 4: Get user confirmation
    print('⚠️  CONFIRMATION REQUIRED ⚠️');
    print('═══════════════════════════════════════════════════');
    print('You are about to deposit \$5.00 USDC to vault $vaultAddress');
    print('This is REAL MONEY on MAINNET!');
    print('');
    print('⏰ IMPORTANT: 24-hour lockup period applies');
    print('   You CANNOT withdraw for 24 hours after deposit');
    print('');
    print('Type "CONFIRM" to proceed with deposit: ');

    final confirmation = stdin.readLineSync();
    if (confirmation?.trim().toUpperCase() != 'CONFIRM') {
      print('\n❌ Deposit cancelled by user');
      exit(0);
    }

    // Step 5: Execute deposit
    print('\n═══════════════════════════════════════════════════');
    print('💸 EXECUTING DEPOSIT');
    print('═══════════════════════════════════════════════════\n');

    print('Depositing \$5.00 USDC...');
    final depositResult = await exchange.vaultTransfer(
      vaultAddress: vaultAddress,
      isDeposit: true,
      usd: 5.0,
    );

    if (depositResult.status != 'ok') {
      print('❌ Deposit failed!');
      print('Status: ${depositResult.status}');
      print('Response: ${depositResult.response}');
      exit(1);
    }

    print('✅ Deposit successful!\n');
    print('Response: ${depositResult.response}');

    // Step 6: Wait a moment for the deposit to process
    print('\n⏳ Waiting 5 seconds for deposit to process...');
    await Future.delayed(Duration(seconds: 5));

    // Step 7: Check vault positions after deposit
    print('\n═══════════════════════════════════════════════════');
    print('📊 UPDATED VAULT POSITIONS');
    print('═══════════════════════════════════════════════════\n');

    final afterEquities = await info.userVaultEquities(userAddress);
    if (afterEquities.isEmpty) {
      print('⚠️  No positions found yet (may take a moment to update)');
    } else {
      print('Found ${afterEquities.length} vault position(s):');
      for (final equity in afterEquities) {
        final isNew = equity.vaultAddress.toLowerCase() == vaultAddress.toLowerCase();
        print('  ${isNew ? "🆕 " : ""}Vault ${equity.vaultAddress}');
        print('    Equity: \$${equity.equity}');

        if (isNew && existingPosition != null) {
          final previousEquity = double.parse(existingPosition.equity);
          final newEquity = double.parse(equity.equity);
          final change = newEquity - previousEquity;
          print('    Change: +\$${change.toStringAsFixed(2)}');
        }
        print('');
      }
    }

    // Step 8: Get detailed follower state
    print('═══════════════════════════════════════════════════');
    print('📊 YOUR DETAILED POSITION IN THIS VAULT');
    print('═══════════════════════════════════════════════════\n');

    final updatedVault = await info.vaultDetails(
      vaultAddress: vaultAddress,
      user: userAddress,
    );

    if (updatedVault.followerState != null) {
      print('Follower State Found:');
      print('${updatedVault.followerState!.data}');
    } else {
      print('⚠️  Follower state not available yet');
      print('   (May take a few minutes to appear in vault followers list)');
    }

    // Check if user appears in followers list
    final followerEntry = updatedVault.followers.where((f) =>
      f.user.toLowerCase() == userAddress.toLowerCase()
    ).firstOrNull;

    if (followerEntry != null) {
      print('\n✅ You appear in vault followers list:');
      print('   Vault Equity: \$${followerEntry.vaultEquity}');
      print('   Recent PnL: \$${followerEntry.pnl}');
      print('   All-Time PnL: \$${followerEntry.allTimePnl}');
      print('   Days Following: ${followerEntry.daysFollowing}');
      if (followerEntry.lockupUntil != null) {
        final lockupDate = DateTime.fromMillisecondsSinceEpoch(followerEntry.lockupUntil!);
        print('   🔒 Locked Until: $lockupDate');
        print('      (${lockupDate.difference(DateTime.now()).inHours} hours remaining)');
      }
    } else {
      print('\n⚠️  Not yet in vault followers list (top 100 by equity)');
      print('   Your position may be too small to appear in top 100');
    }

    print('\n═══════════════════════════════════════════════════');
    print('✅ DEPOSIT TEST COMPLETE');
    print('═══════════════════════════════════════════════════\n');
    print('📝 Summary:');
    print('   ✓ Deposited \$5.00 USDC to ${vaultDetails.name}');
    print('   ✓ 24-hour lockup period active');
    print('   ✓ Check again after 24 hours to withdraw');
    print('\n💡 To check your position later:');
    print('   export TEST_VAULT_ADDRESS=$vaultAddress');
    print('   export TEST_VAULT_LEADER=${vaultDetails.leader}');
    print('   dart run explore_vault.dart');

  } catch (e, stackTrace) {
    print('\n❌ Error during deposit test: $e');
    print(stackTrace);
    exit(1);
  } finally {
    exchange.close();
    info.close();
  }
}
