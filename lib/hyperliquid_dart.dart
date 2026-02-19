/// Dart SDK for the Hyperliquid DEX.
///
/// Provides REST API, WebSocket subscriptions, EIP-712 signing, and
/// order management for the Hyperliquid perpetual futures exchange.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:hyperliquid_dart/hyperliquid_dart.dart';
///
/// // Read-only queries (no wallet needed):
/// final info = InfoClient();
/// final candles = await info.candleSnapshot(
///   coin: 'BTC',
///   interval: '1h',
///   startTime: DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
///   endTime: DateTime.now().millisecondsSinceEpoch,
/// );
/// final mids = await info.allMids();
/// info.close();
///
/// // Trading (requires a WalletAdapter):
/// final exchange = ExchangeClient(wallet: myWalletAdapter);
/// await exchange.placeOrder(
///   orders: [OrderWire.limit(asset: 0, isBuy: true, limitPx: '50000', sz: '0.001')],
/// );
/// exchange.close();
///
/// // Real-time data:
/// final ws = WebSocketClient();
/// await ws.connect();
/// final handle = ws.subscribeL2Book('BTC', (book) => print(book.bids.length));
/// // ... later:
/// await handle.cancel();
/// await ws.dispose();
/// ```
library;

// Clients
export 'src/clients/info_client.dart';
export 'src/clients/exchange_client.dart';
export 'src/clients/websocket_client.dart';

// Models
export 'src/models/common_types.dart';
export 'src/models/info_types.dart';
export 'src/models/exchange_types.dart';
export 'src/models/websocket_types.dart';

// Signing
export 'src/signing/wallet_adapter.dart';
export 'src/signing/private_key_wallet_adapter.dart';
export 'src/signing/signer.dart';
export 'src/signing/action_hash.dart';
export 'src/signing/eip712.dart';

// Transport
export 'src/transport/http_transport.dart';
export 'src/transport/websocket_transport.dart';

// Utilities
export 'src/utils/constants.dart';
export 'src/utils/asset_utils.dart';
