import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Example: Real-time ledger monitoring
///
/// Demonstrates how to subscribe to live ledger events and react to:
/// - Deposits and withdrawals
/// - USD transfers between spot and perp
/// - Internal transfers to other users
/// - Liquidation events
void main() async {
  // Initialize WebSocket client
  final ws = WebSocketClient();
  await ws.connect();

  final userAddress = '0xYOUR_ADDRESS';

  print('📡 Monitoring ledger events for $userAddress\n');

  // Subscribe to real-time ledger updates
  final handle = ws.subscribeUserNonFundingLedgerUpdates(
    userAddress,
    (updates) {
      for (final update in updates) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(update.time);
        final delta = update.delta;

        print('[${timestamp.toIso8601String()}] ${delta.type.toUpperCase()}');

        switch (delta.type) {
          case 'deposit':
            print('  💰 Deposited ${delta.usdc} USDC');
            break;

          case 'withdraw':
            print('  💸 Withdrew ${delta.usdc} USDC');
            if (delta.fee != null) {
              print('  Fee: ${delta.fee} USDC');
            }
            break;

          case 'accountClassTransfer':
            final direction = delta.toPerp == true ? 'Spot → Perp' : 'Perp → Spot';
            print('  🔄 Transferred ${delta.usdc} USDC ($direction)');
            break;

          case 'internalTransfer':
            print('  📤 Sent ${delta.usdc} USDC to ${delta.destination}');
            break;

          case 'subAccountTransfer':
            print('  🔀 Sub-account transfer: ${delta.usdc} USDC');
            break;

          case 'spotTransfer':
            print('  🪙 ${delta.token} transfer: ${delta.amount}');
            if (delta.toPerp != null) {
              final direction = delta.toPerp == true ? 'Spot → Perp' : 'Perp → Spot';
              print('  Direction: $direction');
            }
            break;

          case 'liquidation':
            print('  ⚠️  Liquidation event');
            break;

          default:
            print('  Unknown delta type: ${delta.type}');
        }

        print('  Tx: ${update.hash}\n');
      }
    },
  );

  print('Subscription active. Press Ctrl+C to stop.\n');

  // Keep the program running
  await Future.delayed(const Duration(hours: 1));

  // Cleanup
  await handle.cancel();
  await ws.dispose();
}
