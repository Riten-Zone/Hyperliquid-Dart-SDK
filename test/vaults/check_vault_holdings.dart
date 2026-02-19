import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Check what positions and orders a vault is currently holding
///
/// Usage:
/// ```bash
/// export VAULT_ADDRESS=0xVAULT_ADDRESS
/// dart run check_vault_holdings.dart
/// ```

void main() async {
  final vaultAddress = Platform.environment['VAULT_ADDRESS'];

  if (vaultAddress == null || vaultAddress.isEmpty) {
    print('❌ Error: VAULT_ADDRESS not set!');
    print('\nUsage:');
    print('  export VAULT_ADDRESS=0xVAULT_ADDRESS');
    print('  dart run check_vault_holdings.dart');
    print('\nExample (Growi HF vault):');
    print('  export VAULT_ADDRESS=0x1e37a337ed460039d1b15bd3bc489de789768d5e');
    print('  dart run check_vault_holdings.dart');
    exit(1);
  }

  final info = InfoClient(isTestnet: false);

  print('🏦 VAULT HOLDINGS CHECK\n');
  print('📍 Vault Address: $vaultAddress\n');

  try {
    // Get vault basic info
    print('═══════════════════════════════════════════════════');
    print('📊 VAULT INFORMATION');
    print('═══════════════════════════════════════════════════\n');

    final vaultDetails = await info.vaultDetails(vaultAddress: vaultAddress);
    print('Name: ${vaultDetails.name}');
    print('Leader: ${vaultDetails.leader}');
    print('Past Month Return: ${(vaultDetails.apr * 100).toStringAsFixed(2)}%');
    print('Commission: ${(vaultDetails.leaderCommission * 100).toStringAsFixed(2)}%');

    // Get vault's current positions
    print('\n═══════════════════════════════════════════════════');
    print('📈 CURRENT POSITIONS');
    print('═══════════════════════════════════════════════════\n');

    final state = await info.clearinghouseState(vaultAddress);

    if (state.assetPositions.isEmpty) {
      print('No open positions.\n');
    } else {
      print('Found ${state.assetPositions.length} open position(s):\n');

      for (final pos in state.assetPositions) {
        final position = pos['position'] as Map<String, dynamic>;
        final szi = position['szi'].toString();
        final side = szi.startsWith('-') ? 'SHORT' : 'LONG';
        final size = double.parse(szi).abs();
        final entryPx = double.parse(position['entryPx'].toString());
        final unrealizedPnl = double.parse(position['unrealizedPnl'].toString());
        final leverageMap = position['leverage'] as Map<String, dynamic>;
        final leverage = double.parse(leverageMap['value'].toString());
        final marginUsed = double.parse(position['marginUsed'].toString());
        final coin = position['coin'] as String;
        final liquidationPx = position['liquidationPx']?.toString();

        print('📊 $coin');
        print('   Side: $side');
        print('   Size: ${size.toStringAsFixed(4)}');
        print('   Entry Price: \$${entryPx.toStringAsFixed(4)}');
        print('   Unrealized PnL: \$${unrealizedPnl.toStringAsFixed(2)}');
        print('   Leverage: ${leverage.toStringAsFixed(1)}x');
        print('   Margin Used: \$${marginUsed.toStringAsFixed(2)}');
        print('   Liquidation Price: ${liquidationPx != null ? '\$$liquidationPx' : 'N/A'}');
        print('');
      }
    }

    // Account summary
    print('═══════════════════════════════════════════════════');
    print('💰 ACCOUNT SUMMARY');
    print('═══════════════════════════════════════════════════\n');

    final accountValue = double.parse(state.accountValue);
    final totalMarginUsed = double.parse(state.totalMarginUsed);
    final totalNtlPos = double.parse(state.totalNtlPos);

    // Calculate total unrealized PnL from positions
    double totalUnrealizedPnl = 0;
    for (final pos in state.assetPositions) {
      final position = pos['position'] as Map<String, dynamic>;
      totalUnrealizedPnl += double.parse(position['unrealizedPnl'].toString());
    }

    print('Account Value: \$${accountValue.toStringAsFixed(2)}');
    print('Total Margin Used: \$${totalMarginUsed.toStringAsFixed(2)}');
    print('Total Notional: \$${totalNtlPos.toStringAsFixed(2)}');
    print('Total Unrealized PnL: \$${totalUnrealizedPnl.toStringAsFixed(2)}');
    print('Withdrawable: \$${state.withdrawable}');

    // Get vault's open orders
    print('\n═══════════════════════════════════════════════════');
    print('📋 OPEN ORDERS');
    print('═══════════════════════════════════════════════════\n');

    final orders = await info.openOrders(vaultAddress);

    if (orders.isEmpty) {
      print('No open orders.\n');
    } else {
      print('Found ${orders.length} open order(s):\n');

      for (final order in orders) {
        final side = order.side == 'B' ? 'BUY' : 'SELL';
        final orderType = order.orderType;

        print('📝 ${order.coin}');
        print('   Order ID: ${order.oid}');
        print('   Side: $side');
        print('   Type: $orderType');
        print('   Size: ${order.sz}');
        print('   Limit Price: \$${order.limitPx}');
        print('   Timestamp: ${DateTime.fromMillisecondsSinceEpoch(order.timestamp)}');
        print('');
      }
    }

    // Get vault's recent fills
    print('═══════════════════════════════════════════════════');
    print('📊 RECENT FILLS (Last 10)');
    print('═══════════════════════════════════════════════════\n');

    final fills = await info.userFills(vaultAddress);

    if (fills.isEmpty) {
      print('No recent fills.\n');
    } else {
      final recentFills = fills.take(10);
      print('Showing ${recentFills.length} most recent fill(s):\n');

      for (final fill in recentFills) {
        final side = fill.side == 'B' ? 'BUY' : 'SELL';
        final time = DateTime.fromMillisecondsSinceEpoch(fill.time);

        print('💵 ${fill.coin}');
        print('   Side: $side');
        print('   Price: \$${fill.px}');
        print('   Size: ${fill.sz}');
        print('   Fee: \$${fill.fee}');
        print('   Time: $time');
        print('');
      }
    }

    print('═══════════════════════════════════════════════════');
    print('✅ HOLDINGS CHECK COMPLETE');
    print('═══════════════════════════════════════════════════');

  } catch (e, stackTrace) {
    print('❌ Error checking vault holdings: $e');
    print(stackTrace);
    exit(1);
  } finally {
    info.close();
  }
}
