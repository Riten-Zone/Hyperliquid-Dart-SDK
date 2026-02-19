import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Script to explore HLP vault's historical TVL and PnL data
///
/// Hyperliquid Provider (HLP) Vault:
/// - Vault Address: 0xdfc24b077bc1425ad1dea75bcb6f8158e10df303
/// - Leader: 0x677d831aef5328190852e24f13c46cac05f984e7
/// - Type: Parent vault with 7 child vaults
/// - See VAULT_REFERENCES.md for more details
void main() async {
  final info = InfoClient(isTestnet: false);

  print('🏦 Fetching HLP Vault Details...\n');

  // Fetch HLP vault details
  final details = await info.vaultDetails(
    vaultAddress: '0xdfc24b077bc1425ad1dea75bcb6f8158e10df303',
  );

  // Basic info
  print('═══════════════════════════════════════════════════');
  print('📊 ${details.name}');
  print('═══════════════════════════════════════════════════');
  print('🎯 APR: ${(details.apr * 100).toStringAsFixed(2)}%');
  print('👥 Followers: ${details.followers.length}');
  print('💰 Commission: ${(details.leaderCommission * 100).toStringAsFixed(2)}%');
  print('👨‍💼 Leader: ${details.leader}');
  print('🔒 Is Closed: ${details.isClosed}');
  print('💵 Max Distributable: \$${details.maxDistributable.toStringAsFixed(2)}');
  print('💸 Max Withdrawable: \$${details.maxWithdrawable.toStringAsFixed(2)}');

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

  print('\n═══════════════════════════════════════════════════');
  print('📈 HISTORICAL TVL (Account Value Over Time)');
  print('═══════════════════════════════════════════════════\n');

  // 24h TVL history
  print('📅 Last 24 Hours (${details.portfolio.day.accountValueHistory.length} data points):');
  final dayTvl = details.portfolio.day.accountValueHistory;
  if (dayTvl.isNotEmpty) {
    print('   First: \$${double.parse(dayTvl.first[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(dayTvl.first[0] as int)}');
    print('   Last:  \$${double.parse(dayTvl.last[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(dayTvl.last[0] as int)}');
    print('   Change: \$${(double.parse(dayTvl.last[1] as String) - double.parse(dayTvl.first[1] as String)).toStringAsFixed(2)}');
  }

  // 7d TVL history
  print('\n📅 Last 7 Days (${details.portfolio.week.accountValueHistory.length} data points):');
  final weekTvl = details.portfolio.week.accountValueHistory;
  if (weekTvl.isNotEmpty) {
    print('   First: \$${double.parse(weekTvl.first[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(weekTvl.first[0] as int)}');
    print('   Last:  \$${double.parse(weekTvl.last[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(weekTvl.last[0] as int)}');
    print('   Change: \$${(double.parse(weekTvl.last[1] as String) - double.parse(weekTvl.first[1] as String)).toStringAsFixed(2)}');
  }

  // 30d TVL history
  print('\n📅 Last 30 Days (${details.portfolio.month.accountValueHistory.length} data points):');
  final monthTvl = details.portfolio.month.accountValueHistory;
  if (monthTvl.isNotEmpty) {
    print('   First: \$${double.parse(monthTvl.first[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(monthTvl.first[0] as int)}');
    print('   Last:  \$${double.parse(monthTvl.last[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(monthTvl.last[0] as int)}');
    print('   Change: \$${(double.parse(monthTvl.last[1] as String) - double.parse(monthTvl.first[1] as String)).toStringAsFixed(2)}');
  }

  // All-time TVL history
  print('\n📅 All Time (${details.portfolio.allTime.accountValueHistory.length} data points):');
  final allTimeTvl = details.portfolio.allTime.accountValueHistory;
  if (allTimeTvl.isNotEmpty) {
    print('   First: \$${double.parse(allTimeTvl.first[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(allTimeTvl.first[0] as int)}');
    print('   Last:  \$${double.parse(allTimeTvl.last[1] as String).toStringAsFixed(2)} at ${DateTime.fromMillisecondsSinceEpoch(allTimeTvl.last[0] as int)}');
    print('   Change: \$${(double.parse(allTimeTvl.last[1] as String) - double.parse(allTimeTvl.first[1] as String)).toStringAsFixed(2)}');
  }

  print('\n═══════════════════════════════════════════════════');
  print('💵 HISTORICAL PNL (Profit/Loss Over Time)');
  print('═══════════════════════════════════════════════════\n');

  // 24h PnL history
  print('📅 Last 24 Hours (${details.portfolio.day.pnlHistory.length} data points):');
  final dayPnl = details.portfolio.day.pnlHistory;
  if (dayPnl.isNotEmpty) {
    print('   First: \$${dayPnl.first[1]} at ${DateTime.fromMillisecondsSinceEpoch(dayPnl.first[0] as int)}');
    print('   Last:  \$${dayPnl.last[1]} at ${DateTime.fromMillisecondsSinceEpoch(dayPnl.last[0] as int)}');
  }

  // 7d PnL history
  print('\n📅 Last 7 Days (${details.portfolio.week.pnlHistory.length} data points):');
  final weekPnl = details.portfolio.week.pnlHistory;
  if (weekPnl.isNotEmpty) {
    print('   First: \$${weekPnl.first[1]} at ${DateTime.fromMillisecondsSinceEpoch(weekPnl.first[0] as int)}');
    print('   Last:  \$${weekPnl.last[1]} at ${DateTime.fromMillisecondsSinceEpoch(weekPnl.last[0] as int)}');
  }

  // 30d PnL history
  print('\n📅 Last 30 Days (${details.portfolio.month.pnlHistory.length} data points):');
  final monthPnl = details.portfolio.month.pnlHistory;
  if (monthPnl.isNotEmpty) {
    print('   First: \$${monthPnl.first[1]} at ${DateTime.fromMillisecondsSinceEpoch(monthPnl.first[0] as int)}');
    print('   Last:  \$${monthPnl.last[1]} at ${DateTime.fromMillisecondsSinceEpoch(monthPnl.last[0] as int)}');
  }

  // All-time PnL history
  print('\n📅 All Time (${details.portfolio.allTime.pnlHistory.length} data points):');
  final allTimePnl = details.portfolio.allTime.pnlHistory;
  if (allTimePnl.isNotEmpty) {
    print('   First: \$${allTimePnl.first[1]} at ${DateTime.fromMillisecondsSinceEpoch(allTimePnl.first[0] as int)}');
    print('   Last:  \$${allTimePnl.last[1]} at ${DateTime.fromMillisecondsSinceEpoch(allTimePnl.last[0] as int)}');
  }

  print('\n═══════════════════════════════════════════════════');
  print('📊 TRADING VOLUME');
  print('═══════════════════════════════════════════════════\n');
  print('📅 24h Volume: \$${details.portfolio.day.vlm}');
  print('📅 7d Volume:  \$${details.portfolio.week.vlm}');
  print('📅 30d Volume: \$${details.portfolio.month.vlm}');
  print('📅 All Time:   \$${details.portfolio.allTime.vlm}');

  print('\n═══════════════════════════════════════════════════');
  print('👥 TOP FOLLOWERS (showing first 10 of ${details.followers.length})');
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

  // Check leading vaults
  print('═══════════════════════════════════════════════════');
  print('🏢 VAULTS BY THIS LEADER');
  print('═══════════════════════════════════════════════════\n');

  final vaults = await info.leadingVaults('0x677d831aef5328190852e24f13c46cac05f984e7');
  print('Found ${vaults.length} vault(s):');
  for (final vault in vaults) {
    print('  📊 ${vault.name}');
    print('     Address: ${vault.vaultAddress}');
  }

  info.close();

  print('\n✅ Done!');
}
