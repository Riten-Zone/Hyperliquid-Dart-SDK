# hyperliquid_dart

A Dart SDK for the [Hyperliquid](https://hyperliquid.xyz) decentralized exchange (DEX). Trade perpetual futures with REST API, WebSocket streams, and EIP-712 signing.

[![Dart](https://img.shields.io/badge/dart-%3E%3D3.10.0-blue.svg)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **REST API** — 52 methods across InfoClient (31) and ExchangeClient (21) for market data, account info, trading, and vault operations
- **Spot & Perpetual Trading** — Full support for both spot markets and perpetual futures
- **Vault Operations** — Query vaults, check positions, deposit/withdraw funds
- **WebSocket** — 15 real-time subscriptions for orderbook, trades, fills, funding, TWAP, and ledger updates
- **EIP-712 Signing** — Full signing support with wallet-agnostic interface
- **Wallet Adapters** — Built-in support for raw private keys; bring your own wallet (Privy, Web3Auth, etc.)
- **Type-Safe** — Comprehensive Dart models for all API responses
- **HIP-3 DEX Support** — Query and trade on builder-deployed perpetual DEXs
- **Minimal Dependencies** — Only 4 runtime dependencies, no bloat
- **Production-Ready** — 21 integration tests passing (95%), verified against live mainnet
- **TypeScript SDK Parity** — 56% InfoClient, 42% ExchangeClient, 79% WebSocketClient coverage (actively expanding)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  hyperliquid_dart:
    git:
      url: https://github.com/Riten-Zone/Hyperliquid-Dart-SDK.git
      ref: main
```

Or use a local path during development:

```yaml
dependencies:
  hyperliquid_dart:
    path: ../Hyperliquid-Dart-SDK
```

Then run:

```bash
dart pub get  # or flutter pub get
```

## Quick Start

### Read-Only API (No Wallet Needed)

```dart
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

void main() async {
  // Create an InfoClient for read-only queries
  final info = InfoClient();

  // Fetch current prices
  final mids = await info.allMids();
  print('BTC: \$${mids['BTC']}');

  // Fetch candlestick data
  final candles = await info.candleSnapshot(
    coin: 'BTC',
    interval: '1h',
    startTime: DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
    endTime: DateTime.now().millisecondsSinceEpoch,
  );
  print('Fetched ${candles.length} candles');

  // Fetch orderbook
  final book = await info.l2Book('BTC');
  print('Best bid: ${book.bids.first.price}');
  print('Best ask: ${book.asks.first.price}');

  info.close();
}
```

### Trading (Requires Wallet)

```dart
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

void main() async {
  // Create a wallet adapter (this example uses raw private key)
  final wallet = PrivateKeyWalletAdapter('0xYOUR_PRIVATE_KEY');

  // Create an ExchangeClient for trading
  final exchange = ExchangeClient(wallet: wallet);

  // Set leverage
  await exchange.updateLeverage(
    asset: 0,  // BTC
    leverage: 10,
    isCross: true,
  );

  // Place a limit order
  final result = await exchange.placeOrder(
    orders: [
      OrderWire.limit(
        asset: 0,  // BTC
        isBuy: true,
        limitPx: '50000',  // $50,000
        sz: '0.001',       // 0.001 BTC
        tif: TimeInForce.gtc,
      ),
    ],
  );
  print('Order placed: ${result.status}');

  exchange.close();
}
```

### Real-Time WebSocket Streams

```dart
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

void main() async {
  final ws = WebSocketClient();
  await ws.connect();

  // Subscribe to live prices
  final midsHandle = ws.subscribeAllMids((mids) {
    print('BTC: \$${mids['BTC']}');
  });

  // Subscribe to orderbook updates
  final bookHandle = ws.subscribeL2Book('BTC', (book) {
    print('Bid: ${book.bids.first.price}, Ask: ${book.asks.first.price}');
  });

  // Keep running for 10 seconds
  await Future.delayed(Duration(seconds: 10));

  // Cleanup
  await midsHandle.cancel();
  await bookHandle.cancel();
  await ws.dispose();
}
```

## Wallet Integration

The SDK uses a `WalletAdapter` interface, allowing you to integrate any wallet provider.

### Using Raw Private Key (Built-in)

```dart
final wallet = PrivateKeyWalletAdapter('0xYOUR_PRIVATE_KEY');
```

**⚠️ Security:** Never hardcode private keys in production. Use environment variables or secure storage.

### Custom Wallet Integration (e.g., Privy)

```dart
class PrivyWalletAdapter implements WalletAdapter {
  final PrivyClient _privy;

  PrivyWalletAdapter(this._privy);

  @override
  Future<String> getAddress() async {
    return await _privy.getAddress();
  }

  @override
  Future<String> signTypedData(Map<String, dynamic> typedData) async {
    return await _privy.eth_signTypedData_v4(typedData);
  }
}

// Use it
final wallet = PrivyWalletAdapter(myPrivyClient);
final exchange = ExchangeClient(wallet: wallet);
```

## API Reference

### InfoClient (Read-Only) - 31 Methods Available

**Coverage: 56% (31/55)** compared to TypeScript SDK

**Perpetual Futures Market Data**
| Method | Description |
|--------|-------------|
| `allMids()` | Get current mid prices for all perpetual assets |
| `candleSnapshot(coin, interval, startTime, endTime)` | Get OHLCV candles for a coin |
| `candleSnapshotPaginated(coin, interval, startTime, endTime)` | Auto-paginated candle queries for large time ranges |
| `l2Book(coin)` | Get orderbook snapshot |
| `metaAndAssetCtxs(dex?)` | Get perpetual futures metadata and contexts (supports HIP-3 DEXs) |
| `meta(dex?)` | Get perpetual futures metadata only (supports HIP-3 DEXs) |
| `universeNames()` | Get asset universe names (convenience method) |
| `recentTrades(coin)` | Get recent trades for a coin |

**Spot Market Data**
| Method | Description |
|--------|-------------|
| `spotMeta()` | Get all spot tokens metadata (tokens, universes) |
| `spotMetaAndAssetCtxs()` | Get spot metadata + market data (prices, volumes) |
| `tokenDetails(tokenId)` | Get detailed token information by token ID |
| `spotClearinghouseState(address)` | Get user's spot token balances |

**Account & Order Data**
| Method | Description |
|--------|-------------|
| `clearinghouseState(address)` | Get perpetual account state (balance, positions) |
| `openOrders(address)` | Get user's open orders |
| `frontendOpenOrders(address)` | Get user's open orders including trigger orders |
| `historicalOrders(address)` | Get up to 2000 most recent orders |
| `userFills(address)` | Get user's trade fills history |
| `userFillsByTime(user, startTime, endTime?)` | Get user's fills filtered by time range |
| `userFunding(user, startTime, endTime?)` | Get user's funding payments |
| `fundingHistory(coin, startTime, endTime?)` | Get historical funding rates for a coin |
| `orderStatus(user, oid)` | Get order status by order ID |
| `portfolio(user)` | Get portfolio with historical account value and PnL |

**Sub-Accounts & HIP-3 DEXs**
| Method | Description |
|--------|-------------|
| `subAccounts(user)` | Get user's sub-accounts with balances and positions |
| `perpDexs()` | Get all HIP-3 builder-deployed perpetual DEXs |
| `maxBuilderFee(user, builder)` | Get max approved builder fee |

**Vault Operations** 🆕
| Method | Description |
|--------|-------------|
| `vaultDetails(vaultAddress, user?)` | Get detailed vault information including performance, followers, and portfolio history |
| `vaultSummaries()` | Get summaries for all vaults (may return empty - known API issue) |
| `leadingVaults(user)` | Get all vaults managed by a specific vault leader |
| `userVaultEquities(user)` | Get user's vault deposits and equity across all vaults |

[Full API docs →](https://pub.dev/documentation/hyperliquid_dart/latest/)

### ExchangeClient (Trading) - 21 Methods Available

**Coverage: 42% (21/50)** compared to TypeScript SDK

**Order Management**
| Method | Description |
|--------|-------------|
| `placeOrder(orders, grouping, builder, vaultAddress?)` | Place limit/market/trigger orders |
| `cancelOrders(cancels, vaultAddress?)` | Cancel orders by order ID |
| `cancelOrdersByCloid(asset, cloids, vaultAddress?)` | Cancel orders by client order ID |
| `modify(oid, order, vaultAddress?)` | Modify an existing order (price, size) |
| `batchModify(modifies, vaultAddress?)` | Modify multiple orders in a single atomic request |
| `scheduleCancel(time)` | Schedule all orders to cancel at a specific time |

**TWAP Orders**
| Method | Description |
|--------|-------------|
| `twapOrder(twap, vaultAddress?)` | Place TWAP (time-weighted average price) order |
| `twapCancel(cancel, vaultAddress?)` | Cancel an active TWAP order |

**Account Management**
| Method | Description |
|--------|-------------|
| `updateLeverage(asset, leverage, isCross, vaultAddress?)` | Set leverage for a perpetual asset |
| `updateIsolatedMargin(asset, isBuy, ntli, vaultAddress?)` | Add/remove isolated margin |
| `usdTransfer(destination, amount)` | Transfer USDC between accounts/sub-accounts |
| `usdClassTransfer(amount, toPerp)` | Transfer USDC between spot and perp accounts |
| `withdraw(destination, amount)` | Withdraw USDC to another address |
| `approveBuilderFee(builder, maxFeeRate)` | Approve a builder fee for HIP-3 DEXs |

**Spot Token Operations**
| Method | Description |
|--------|-------------|
| `spotUser(action)` | Toggle spot dusting settings |
| `spotSend(destination, token, amount)` | Send spot tokens to another address |
| `sendAsset(destination, token, amount, dex?, subAccount?)` | Transfer assets between DEXs/addresses/sub-accounts |
| `subAccountTransfer(amount, subAccount, isDeposit)` | Transfer USDC to/from sub-accounts (perp DEX) |
| `subAccountSpotTransfer(token, amount, subAccount, isDeposit)` | Transfer spot tokens to/from sub-accounts |

**Vault Operations** 🆕
| Method | Description |
|--------|-------------|
| `vaultTransfer(vaultAddress, isDeposit, usd)` | Deposit/withdraw USDC to/from vaults ($5 minimum, 24h lockup) |

### WebSocketClient (Real-Time) - 15 Subscriptions Available

**Market Data Streams**
| Method | Description |
|--------|-------------|
| `subscribeAllMids(callback)` | Live mid prices for all perpetual assets |
| `subscribeL2Book(coin, callback)` | Live orderbook updates for a coin |
| `subscribeCandle(coin, interval, callback)` | Live OHLCV candle updates |
| `subscribeTrades(coin, callback)` | Live trades stream for a coin |
| `subscribeBbo(coin, callback)` | Best bid/offer updates |

**Account Streams**
| Method | Description |
|--------|-------------|
| `subscribeUserFills(address, callback)` | Live trade fills for user |
| `subscribeOrderUpdates(address, callback)` | Order status updates for user |
| `subscribeUserFundings(address, callback)` | Live funding payments for user |
| `subscribeUserEvents(address, callback)` | User event stream (clearinghouse state changes, etc.) |
| `subscribeNotification(address, callback)` | Account notifications |
| `subscribeWebData3(address, callback)` | Aggregated account data stream |

**TWAP Streams**
| Method | Description |
|--------|-------------|
| `subscribeTwapStates(address, callback)` | Active TWAP orders status |
| `subscribeUserTwapHistory(address, callback)` | TWAP order history events |
| `subscribeUserTwapSliceFills(address, callback)` | Individual TWAP slice fill notifications |

**Other**
| Method | Description |
|--------|-------------|
| `subscribeRaw(key, message, callback)` | Generic raw subscription for any type |

**Planned Future Subscriptions**
- Spot market real-time data streams
- Vault performance updates

## Examples

See the [`example/`](example/) directory for more examples:
- [`hyperliquid_dart_example.dart`](example/hyperliquid_dart_example.dart) — Comprehensive demo

## Testing

```bash
# Unit tests (no wallet needed)
dart test --exclude-tags integration

# Integration tests (requires HYPERLIQUID_PRIVATE_KEY env var)
HYPERLIQUID_PRIVATE_KEY=0x... dart test --tags integration
```

## Architecture

- **Minimal Dependencies**: `http`, `web_socket_channel`, `pointycastle`, `msgpack_dart`
- **Wallet-Agnostic**: Abstract `WalletAdapter` interface
- **Type-Safe**: Comprehensive models for all API responses
- **Memory-Efficient**: Designed for long-running applications

## Roadmap

**Completed**
- [x] REST API — InfoClient (31 methods) + ExchangeClient (21 methods)
- [x] WebSocket subscriptions (15 real-time streams)
- [x] EIP-712 signing with wallet-agnostic interface
- [x] PrivateKeyWalletAdapter for raw private keys
- [x] Perpetual futures trading (orders, leverage, positions)
- [x] TWAP orders (place, cancel, monitor via WebSocket)
- [x] Spot market metadata and price queries
- [x] **Spot token trading** (buy/sell, send, dust settings, sub-account transfers)
- [x] HIP-3 DEX support (query DEXs, metadata, trade on builder-deployed perps)
- [x] Sub-account queries and USDC transfers
- [x] **Vault operations** (query vaults, deposit/withdraw, check positions)
- [x] Order modification (single and batch)
- [x] Builder fee approval
- [x] Paginated candle queries for large time ranges
- [x] Portfolio and funding history endpoints
- [x] **Published to pub.dev** 🎉
- [x] **Comprehensive dartdoc documentation** (67 methods with examples and API docs)

**Future**
- [ ] Referral system integration
- [ ] Comprehensive API documentation expansion
- [ ] Additional WebSocket streams (spot markets, vault updates)

## Contributing

Contributions welcome! Please open an issue or PR on [GitHub](https://github.com/Riten-Zone/Hyperliquid-Dart-SDK).

## License

MIT License - see [LICENSE](LICENSE) for details.

## Disclaimer

This SDK is provided as-is. Trading crypto involves risk. The authors are not responsible for any losses incurred.

## Links

- [Hyperliquid Documentation](https://hyperliquid.gitbook.io/hyperliquid-docs)
- [Hyperliquid DEX](https://app.hyperliquid.xyz/)
- [GitHub Repository](https://github.com/Riten-Zone/Hyperliquid-Dart-SDK)

---

Built with ❤️ for the Hyperliquid community
