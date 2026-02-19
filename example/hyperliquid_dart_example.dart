import 'package:hyperliquid_dart/hyperliquid_dart.dart';

void main() async {
  // --- Read-only queries (no wallet needed) ---

  final info = InfoClient();

  // Fetch all mid prices.
  final mids = await info.allMids();
  print('BTC mid: ${mids['BTC']}');
  print('ETH mid: ${mids['ETH']}');

  // Fetch candles for BTC.
  final now = DateTime.now().millisecondsSinceEpoch;
  final oneDayAgo = now - (24 * 60 * 60 * 1000);
  final candles = await info.candleSnapshot(
    coin: 'BTC',
    interval: '1h',
    startTime: oneDayAgo,
    endTime: now,
  );
  print('Fetched ${candles.length} candles');

  // Fetch L2 orderbook.
  final book = await info.l2Book(coin: 'BTC');
  print('BTC bids: ${book.bids.length}, asks: ${book.asks.length}');

  // Fetch asset metadata.
  final meta = await info.metaAndAssetCtxs();
  print('Universe size: ${meta.universe.length}');
  print('First asset: ${meta.universe.first.name}');

  info.close();

  // --- WebSocket real-time data ---

  final ws = WebSocketClient();
  await ws.connect();

  // Subscribe to BTC orderbook updates.
  final bookHandle = ws.subscribeL2Book('BTC', (book) {
    print('L2 update — bids: ${book.bids.length}, asks: ${book.asks.length}');
  });

  // Subscribe to all mid prices.
  final midsHandle = ws.subscribeAllMids((mids) {
    print('Mid update — BTC: ${mids['BTC']}');
  });

  // Keep running for 10 seconds then clean up.
  await Future<void>.delayed(const Duration(seconds: 10));

  await bookHandle.cancel();
  await midsHandle.cancel();
  await ws.dispose();

  print('Done!');
}
