import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Check your vault positions and balances
///
/// Usage:
/// ```bash
/// export USER_ADDRESS=0xYOUR_ADDRESS
/// dart run check_vault_balance.dart
/// ```
///
/// Or use with private key to auto-detect address:
/// ```bash
/// export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
/// dart run check_vault_balance.dart
/// ```

void main() async {
  String? userAddress = Platform.environment['USER_ADDRESS'];
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  // If no address but private key provided, derive address
  if ((userAddress == null || userAddress.isEmpty) &&
      (privateKey != null && privateKey.isNotEmpty)) {
    final wallet = PrivateKeyWalletAdapter(privateKey);
    userAddress = await wallet.getAddress();
  }

  if (userAddress == null || userAddress.isEmpty) {
    print('❌ Error: No address provided!');
    print('\nUsage (Option 1 - Direct address):');
    print('  export USER_ADDRESS=0xYOUR_ADDRESS');
    print('  dart run check_vault_balance.dart');
    print('\nUsage (Option 2 - From private key):');
    print('  export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY');
    print('  dart run check_vault_balance.dart');
    exit(1);
  }

  // Non-null address after validation
  final address = userAddress;

  final info = InfoClient(isTestnet: false);

  print('🏦 VAULT BALANCE CHECK\n');
  print('👤 Address: $address\n');

  try {
    // Get all vault positions
    print('═══════════════════════════════════════════════════');
    print('📊 YOUR VAULT POSITIONS');
    print('═══════════════════════════════════════════════════\n');

    final equities = await info.userVaultEquities(address);

    if (equities.isEmpty) {
      print('No vault positions found.\n');
      print('💡 To deposit to a vault:');
      print('   export TEST_VAULT_ADDRESS=0xVAULT_ADDRESS');
      print('   dart run test_vault_deposit.dart');
      info.close();
      return;
    }

    print('Found ${equities.length} vault position(s):\n');

    double totalEquity = 0;

    // Get detailed info for each vault
    for (final equity in equities) {
      final vaultDetails = await info.vaultDetails(
        vaultAddress: equity.vaultAddress,
        user: address,
      );

      final equityValue = double.parse(equity.equity);
      totalEquity += equityValue;

      print('📊 ${vaultDetails.name}');
      print('   Address: ${equity.vaultAddress}');
      print('   Your Equity: \$${equityValue.toStringAsFixed(6)}');
      print('   Leader: ${vaultDetails.leader}');
      print('   Past Month Return: ${(vaultDetails.apr * 100).toStringAsFixed(2)}%');
      print('   Commission: ${(vaultDetails.leaderCommission * 100).toStringAsFixed(2)}%');

      // Check if user is in followers list (top 100)
      final followerEntry = vaultDetails.followers.where((f) =>
        f.user.toLowerCase() == address.toLowerCase()
      ).firstOrNull;

      if (followerEntry != null) {
        print('   Recent PnL: \$${followerEntry.pnl}');
        print('   All-Time PnL: \$${followerEntry.allTimePnl}');
        print('   Days Following: ${followerEntry.daysFollowing}');

        if (followerEntry.lockupUntil != null) {
          final lockupDate = DateTime.fromMillisecondsSinceEpoch(
            followerEntry.lockupUntil!
          );
          final now = DateTime.now();

          if (lockupDate.isAfter(now)) {
            final hoursRemaining = lockupDate.difference(now).inHours;
            print('   🔒 Locked Until: $lockupDate ($hoursRemaining hours remaining)');
          } else {
            print('   ✅ Unlocked (can withdraw)');
          }
        }
      } else {
        print('   ⚠️  Not in top 100 followers (position too small)');
      }

      print('');
    }

    print('═══════════════════════════════════════════════════');
    print('💰 TOTAL VAULT EQUITY: \$${totalEquity.toStringAsFixed(6)}');
    print('═══════════════════════════════════════════════════\n');

    print('💡 To explore a specific vault in detail:');
    print('   export TEST_VAULT_ADDRESS=0xVAULT_ADDRESS');
    print('   export TEST_VAULT_LEADER=0xLEADER_ADDRESS');
    print('   dart run explore_vault.dart');

  } catch (e, stackTrace) {
    print('❌ Error checking vault balance: $e');
    print(stackTrace);
    exit(1);
  } finally {
    info.close();
  }
}
