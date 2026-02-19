import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Example: Spot Market Trading on Hyperliquid
///
/// This demonstrates how to place buy/sell orders on spot markets.
/// Note: Spot orders use the same placeOrder() method as perpetuals,
/// but with a different asset ID format: 10000 + spotIndex
void main() async {
  final wallet = PrivateKeyWalletAdapter('0xYOUR_PRIVATE_KEY');
  final exchange = ExchangeClient(wallet: wallet, isTestnet: false);
  final info = InfoClient(isTestnet: false);

  print('=== Spot Market Trading Example ===\n');

  // Example 1: View all spot markets
  print('1. Fetching all spot markets...');
  final spotMeta = await info.spotMeta();
  print('Available spot pairs:');
  for (var i = 0; i < spotMeta.universe.length && i < 5; i++) {
    final pair = spotMeta.universe[i];
    print('  ${pair.name} (asset ID: ${10000 + i})');
  }
  print('  ... and ${spotMeta.universe.length - 5} more\n');

  // Example 2: Get asset ID for a specific spot pair
  print('2. Getting asset ID for PURR/USDC...');
  final purrAssetId = await info.getSpotAssetId('PURR/USDC');
  if (purrAssetId == null) {
    print('Error: PURR/USDC not found');
    return;
  }
  print('PURR/USDC asset ID: $purrAssetId\n');

  // Example 3: Check spot market prices
  print('3. Checking current PURR/USDC market...');
  final combined = await info.spotMetaAndAssetCtxs();
  final purrCtx = combined.assetCtxs.firstWhere(
    (ctx) => ctx.coin == 'PURR/USDC',
    orElse: () => throw Exception('PURR/USDC not found'),
  );
  print('Current price: \$${purrCtx.markPx}');
  print('24h volume: \$${purrCtx.dayNtlVlm}\n');

  // Example 4: Place a spot limit buy order
  print('4. Placing spot limit buy order...');
  final buyPrice = (double.parse(purrCtx.markPx) * 0.95).toStringAsFixed(6); // 5% below market
  final buyResult = await exchange.placeOrder(
    orders: [
      OrderWire.limit(
        asset: purrAssetId,
        isBuy: true,
        limitPx: buyPrice,
        sz: '100', // Buy 100 PURR
        tif: TimeInForce.gtc,
      ),
    ],
  );
  print('Buy order status: ${buyResult.status}');
  print('Response: ${buyResult.response}\n');

  // Example 5: Place a spot limit sell order
  print('5. Placing spot limit sell order...');
  final sellPrice = (double.parse(purrCtx.markPx) * 1.05).toStringAsFixed(6); // 5% above market
  final sellResult = await exchange.placeOrder(
    orders: [
      OrderWire.limit(
        asset: purrAssetId,
        isBuy: false,
        limitPx: sellPrice,
        sz: '100', // Sell 100 PURR
        tif: TimeInForce.gtc,
      ),
    ],
  );
  print('Sell order status: ${sellResult.status}');
  print('Response: ${sellResult.response}\n');

  // Example 6: Place a spot market order (immediate execution)
  print('6. Placing spot market buy order...');
  final marketBuyResult = await exchange.placeOrder(
    orders: [
      OrderWire.market(
        asset: purrAssetId,
        isBuy: true,
        sz: '10', // Buy 10 PURR at market price
        tpsl: null,
      ),
    ],
  );
  print('Market order status: ${marketBuyResult.status}');
  print('Response: ${marketBuyResult.response}\n');

  // Example 7: Check open spot orders
  print('7. Checking open spot orders...');
  await Future.delayed(Duration(seconds: 1)); // Wait for orders to settle
  final userAddress = await wallet.getAddress();
  final openOrders = await info.openOrders(userAddress);
  final spotOrders = openOrders.where((o) => o.coin.contains('/')).toList();
  print('Open spot orders: ${spotOrders.length}');
  for (final order in spotOrders) {
    print('  ${order.coin}: ${order.side} ${order.sz} @ \$${order.limitPx}');
    print('    Order ID: ${order.oid}');
  }
  print('');

  // Example 8: Cancel a spot order
  if (spotOrders.isNotEmpty) {
    print('8. Canceling first spot order...');
    final orderToCancel = spotOrders.first;
    final cancelResult = await exchange.cancelOrders(
      cancels: [
        CancelWire(
          asset: purrAssetId,
          oid: orderToCancel.oid,
        ),
      ],
    );
    print('Cancel status: ${cancelResult.status}');
    print('Response: ${cancelResult.response}\n');
  }

  // Example 9: Check spot balance
  print('9. Checking spot balance...');
  final spotState = await info.spotClearinghouseState(userAddress);
  print('Spot balances:');
  for (final balance in spotState.balances) {
    if (double.parse(balance.total) > 0) {
      print('  ${balance.coin}: ${balance.total}');
    }
  }

  exchange.close();
  info.close();

  print('\n✓ Spot trading example complete!');
  print('\nKey Takeaways:');
  print('- Spot orders use asset ID = 10000 + spot index');
  print('- Use info.getSpotAssetId(tokenName) for convenience');
  print('- Same placeOrder() method as perpetuals');
  print('- Check spot balances with spotClearinghouseState()');
}
