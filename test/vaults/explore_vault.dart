import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Generalized vault explorer script - shows EVERYTHING about any vault
///
/// Usage:
/// ```bash
/// export TEST_VAULT_ADDRESS=0xYOUR_VAULT_ADDRESS
/// export TEST_VAULT_LEADER=0xLEADER_ADDRESS  # Optional
/// dart run explore_vault.dart
/// ```
///
/// Examples in VAULT_REFERENCES.md

void main() async {
  // Get vault address from environment variable
  final vaultAddress = Platform.environment['TEST_VAULT_ADDRESS'];
  final leaderAddress = Platform.environment['TEST_VAULT_LEADER'];

  if (vaultAddress == null || vaultAddress.isEmpty) {
    print('❌ Error: TEST_VAULT_ADDRESS environment variable not set!');
    print('\nUsage:');
    print('  export TEST_VAULT_ADDRESS=0xYOUR_VAULT_ADDRESS');
    print('  export TEST_VAULT_LEADER=0xLEADER_ADDRESS  # Optional');
    print('  dart run explore_vault.dart');
    print('\nSee VAULT_REFERENCES.md for known vault addresses');
    exit(1);
  }

  final info = InfoClient(isTestnet: false);

  print('🏦 Fetching Vault Details...\n');
  print('📍 Vault Address: $vaultAddress\n');

  try {
    // Fetch vault details
    final details = await info.vaultDetails(vaultAddress: vaultAddress);

    // ═══════════════════════════════════════════════════════════════
    // BASIC INFORMATION
    // ═══════════════════════════════════════════════════════════════
    print('═══════════════════════════════════════════════════');
    print('📊 ${details.name}');
    print('═══════════════════════════════════════════════════');
    print('📍 Address: ${details.vaultAddress}');
    print('👨‍💼 Leader: ${details.leader}');
    print('📈 Past Month Return: ${(details.apr * 100).toStringAsFixed(2)}%');
    print('💰 Commission: ${(details.leaderCommission * 100).toStringAsFixed(2)}%');
    print('👥 Followers: ${details.followers.length}+ (showing top 100 by equity)');
    print('🔒 Is Closed: ${details.isClosed}');
    print('📬 Allow Deposits: ${details.allowDeposits}');
    print('💵 Max Distributable: \$${details.maxDistributable.toStringAsFixed(2)}');
    print('💸 Max Withdrawable: \$${details.maxWithdrawable.toStringAsFixed(2)}');
    print('📊 Leader Fraction: ${(details.leaderFraction * 100).toStringAsFixed(4)}%');

    if (details.description != null && details.description!.isNotEmpty) {
      print('\n📝 Description:');
      print('   ${details.description}');
    }

    // Relationship info
    if (details.relationship != null) {
      print('\n🔗 Relationship: ${details.relationship!.type}');
      if (details.relationship!.data?.childAddresses != null) {
        print('   Child vaults: ${details.relationship!.data!.childAddresses!.length}');
        print('   Children:');
        for (final child in details.relationship!.data!.childAddresses!) {
          print('     - $child');
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // HISTORICAL TVL (ACCOUNT VALUE)
    // ═══════════════════════════════════════════════════════════════
    print('\n═══════════════════════════════════════════════════');
    print('📈 HISTORICAL TVL (Account Value Over Time)');
    print('═══════════════════════════════════════════════════\n');

    _printTvlHistory('24h', details.portfolio.day.accountValueHistory);
    _printTvlHistory('7d', details.portfolio.week.accountValueHistory);
    _printTvlHistory('30d', details.portfolio.month.accountValueHistory);
    _printTvlHistory('All Time', details.portfolio.allTime.accountValueHistory);

    // ═══════════════════════════════════════════════════════════════
    // HISTORICAL PNL
    // ═══════════════════════════════════════════════════════════════
    print('\n═══════════════════════════════════════════════════');
    print('💵 HISTORICAL PNL (Profit/Loss Over Time)');
    print('═══════════════════════════════════════════════════\n');

    _printPnlHistory('24h', details.portfolio.day.pnlHistory);
    _printPnlHistory('7d', details.portfolio.week.pnlHistory);
    _printPnlHistory('30d', details.portfolio.month.pnlHistory);
    _printPnlHistory('All Time', details.portfolio.allTime.pnlHistory);

    // ═══════════════════════════════════════════════════════════════
    // TRADING VOLUME
    // ═══════════════════════════════════════════════════════════════
    print('\n═══════════════════════════════════════════════════');
    print('📊 TRADING VOLUME');
    print('═══════════════════════════════════════════════════\n');
    print('📅 24h Volume: \$${details.portfolio.day.vlm}');
    print('📅 7d Volume:  \$${details.portfolio.week.vlm}');
    print('📅 30d Volume: \$${details.portfolio.month.vlm}');
    print('📅 All Time:   \$${details.portfolio.allTime.vlm}');

    // ═══════════════════════════════════════════════════════════════
    // TOP FOLLOWERS
    // ═══════════════════════════════════════════════════════════════
    print('\n═══════════════════════════════════════════════════');
    print('👥 TOP FOLLOWERS (showing 10 of ${details.followers.length})');
    print('═══════════════════════════════════════════════════\n');

    for (final follower in details.followers.take(10)) {
      print('👤 ${follower.user}');
      print('   💰 Equity: \$${follower.vaultEquity}');
      print('   📈 PnL: \$${follower.pnl}');
      print('   📊 All-Time PnL: \$${follower.allTimePnl}');
      print('   📅 Days Following: ${follower.daysFollowing}');
      if (follower.lockupUntil != null) {
        print('   🔒 Locked Until: ${DateTime.fromMillisecondsSinceEpoch(follower.lockupUntil!)}');
      }
      print('');
    }

    // ═══════════════════════════════════════════════════════════════
    // VAULTS BY THIS LEADER (if leader address provided)
    // ═══════════════════════════════════════════════════════════════
    if (leaderAddress != null && leaderAddress.isNotEmpty) {
      print('═══════════════════════════════════════════════════');
      print('🏢 ALL VAULTS BY THIS LEADER');
      print('═══════════════════════════════════════════════════\n');

      final vaults = await info.leadingVaults(leaderAddress);
      print('Found ${vaults.length} vault(s) managed by $leaderAddress:\n');
      for (final vault in vaults) {
        print('  📊 ${vault.name}');
        print('     Address: ${vault.vaultAddress}');
        print('');
      }
    }

    print('✅ Done!');
  } catch (e, stackTrace) {
    print('❌ Error fetching vault details: $e');
    print(stackTrace);
    exit(1);
  } finally {
    info.close();
  }
}

void _printTvlHistory(String period, List<List<dynamic>> history) {
  print('📅 $period (${history.length} data points):');
  if (history.isEmpty) {
    print('   No data available\n');
    return;
  }

  final first = double.parse(history.first[1] as String);
  final last = double.parse(history.last[1] as String);
  final change = last - first;
  final changePercent = (change / first) * 100;

  print('   First: \$${first.toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(history.first[0] as int)}');
  print('   Last:  \$${last.toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(history.last[0] as int)}');
  print('   Change: \$${change.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)');
  print('');
}

void _printPnlHistory(String period, List<List<dynamic>> history) {
  print('📅 $period (${history.length} data points):');
  if (history.isEmpty) {
    print('   No data available\n');
    return;
  }

  final first = history.first[1] as String;
  final last = history.last[1] as String;

  print('   First: \$${first} at ${DateTime.fromMillisecondsSinceEpoch(history.first[0] as int)}');
  print('   Last:  \$${last} at ${DateTime.fromMillisecondsSinceEpoch(history.last[0] as int)}');
  print('');
}
