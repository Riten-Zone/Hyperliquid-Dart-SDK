# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.16.3] - 2026-02-23

### Fixed
- `subscribeL2Book`: mantissa parameter now sent as JSON integer (`2`, `5`) instead of string (`"2"`, `"5"`), fixing ×2/×5 aggregation levels that were silently ignored by the Hyperliquid server

## [0.16.2] - 2026-02-19

### Fixed
- Updated repository and issue tracker URLs to `https://github.com/Riten-Zone/Hyperliquid-Dart-SDK`
- Updated dependencies to latest versions:
  - `http`: `^1.3.0` → `^1.6.0`
  - `web_socket_channel`: `^3.0.2` → `^3.0.3`
  - `pointycastle`: `^3.9.1` → `^4.0.0`

## [0.16.1] - 2026-02-15

### Changed - Documentation Enhancement
- **Comprehensive dartdoc comments** added to all 67 public API methods
  - **InfoClient** (32 methods): Enhanced 15 methods with detailed descriptions and code examples
    - `candleSnapshot`, `candleSnapshotPaginated`, `universeNames`, `l2Book`, `allMids`
    - `clearinghouseState`, `openOrders`, `frontendOpenOrders`, `historicalOrders`
    - `userFills`, `userFillsByTime`, `userFunding`, `spotClearinghouseState`
    - `recentTrades`, `maxBuilderFee`
  - **ExchangeClient** (22 methods): Enhanced 6 methods with comprehensive docs
    - `cancelOrders`, `cancelOrdersByCloid`, `updateLeverage`
    - `updateIsolatedMargin`, `usdTransfer`, `withdraw`
  - **WebSocketClient** (15 subscriptions): Enhanced 9 subscription methods
    - `subscribeL2Book`, `subscribeCandle`, `subscribeTrades`, `subscribeAllMids`
    - `subscribeUserFills`, `subscribeOrderUpdates`, `subscribeUserEvents`
    - `subscribeUserFundings`, `subscribeRaw`
- All methods now include:
  - Clear parameter explanations
  - Return value descriptions
  - Practical, runnable code examples
  - Important notes and caveats
- Generated HTML documentation (22KB) with 0 errors, 11 minor warnings
- **Browse API docs:** https://pub.dev/documentation/hyperliquid_dart/latest/

## [0.16.0] - 2026-02-15

### Added - Phase 16: Vault Operations
- **InfoClient** - 4 new vault query methods:
  - `vaultDetails(vaultAddress, user?)` - Get detailed vault information including performance, followers, and portfolio history
  - `vaultSummaries()` - Get summaries for all vaults on Hyperliquid
  - `leadingVaults(user)` - Get all vaults managed by a specific vault leader
  - `userVaultEquities(user)` - Get user's vault deposits and equity across all vaults
- **ExchangeClient** - 1 new vault transfer method:
  - `vaultTransfer(vaultAddress, isDeposit, usd)` - Deposit/withdraw USDC to/from vaults
- **New Models**:
  - `VaultDetails` - Complete vault information with portfolio metrics
  - `VaultPortfolio` - Historical TVL and PnL across time periods (day/week/month/allTime)
  - `PortfolioPeriod` - Account value history, PnL history, and trading volume
  - `VaultFollower` - Follower information with equity, PnL, and lockup details
  - `VaultSummary` - Lightweight vault listing
  - `LeadingVault` - Vault performance metrics by leader
  - `UserVaultEquity` - User's vault position
  - `VaultRelationship` - Parent/child vault hierarchy
- **Helper Scripts** (6 total):
  - `explore_vault.dart` - Generalized vault explorer using env vars
  - `test_vault_deposit.dart` - Test vault deposits with confirmation
  - `check_vault_balance.dart` - Check user's vault positions
  - `check_vault_holdings.dart` - View vault's current trading positions
  - `test_spot_perp_transfer.dart` - Transfer USDC between spot and perp accounts
  - `test_hlp_vault.dart` - HLP vault specific explorer
- **Documentation**:
  - `VAULT_REFERENCES.md` - Complete vault operations guide with known vault addresses

### Changed
- InfoClient coverage: 27 → 31 methods (+15% increase)
- ExchangeClient coverage: 20 → 21 methods (+5% increase)
- Test coverage: 19 → 21 passing tests (95% pass rate)
- Overall SDK coverage: 52% → 56% of TypeScript SDK

### Fixed
- Documented $5 minimum deposit requirement for vaults (protocol-enforced)
- Clarified vault deposits use PERP account balance (not spot)
- Fixed VaultPortfolio parsing to handle array-of-tuples format from API
- Simplified LeadingVault model to match actual API response

### Notes
- Vault deposits subject to 24-hour lockup period
- Vault leaders must maintain at least 5% of total vault equity
- `vaultSummaries()` may return empty (known API issue - use `leadingVaults()` instead)
- Successfully tested on mainnet with real deposits

## [0.1.0] - 2026-02-10

### Added
- Initial release of Hyperliquid Dart SDK
- `InfoClient` with 15+ read-only endpoints
  - `allMids()` - Current prices for all assets
  - `candleSnapshot()` - OHLCV candlestick data
  - `l2Book()` - Orderbook snapshots
  - `metaAndAssetCtxs()` - Asset metadata and contexts
  - `clearinghouseState()` - Account state (balance, positions)
  - `openOrders()` - Open orders for an account
  - `userFills()` - Trade fills for an account
  - `userFunding()` - Funding payments for an account
  - And more...
- `ExchangeClient` with 8 trading endpoints
  - `placeOrder()` - Place limit/market/trigger orders
  - `cancelOrders()` - Cancel orders by order ID
  - `cancelOrdersByCloid()` - Cancel by client order ID
  - `updateLeverage()` - Set leverage for an asset
  - `updateIsolatedMargin()` - Add/remove isolated margin
  - `withdraw()` - Withdraw USDC
  - `approveBuilderFee()` - Approve builder fee
- `WebSocketClient` with 8 real-time subscriptions
  - `subscribeAllMids()` - Live prices for all assets
  - `subscribeL2Book()` - Live orderbook updates
  - `subscribeCandle()` - Live candle updates
  - `subscribeTrades()` - Recent trades stream
  - `subscribeUserFills()` - Live trade fills
  - `subscribeOrderUpdates()` - Order status updates
  - Auto-reconnection with exponential backoff
- Full EIP-712 signing support
  - `WalletAdapter` interface for wallet-agnostic integration
  - `PrivateKeyWalletAdapter` for raw private key signing
  - Keccak-256 hashing (fixed from SHA-3)
  - secp256k1 ECDSA signatures with recovery ID
- Comprehensive type-safe models
  - `Candle`, `L2Book`, `AssetMetadata`, `AssetContext`
  - `ClearinghouseState`, `OpenOrder`, `UserFill`, `UserFunding`
  - `OrderWire` (limit/market/trigger factories)
  - `SignatureComponents`, `BuilderFee`, and more
- 37 passing tests
  - 32 unit tests (keccak256, action hashing, signing, adapter)
  - 5 live integration tests (verified against mainnet)
- Minimal dependencies (only 4 runtime deps)
  - `http` for REST transport
  - `web_socket_channel` for WebSocket transport
  - `pointycastle` for keccak256 + secp256k1
  - `msgpack_dart` for action serialization

### Fixed
- Critical Keccak-256 bug (was using SHA-3 instead of Keccak)
- Signature recovery ID computation for Ethereum compatibility

### Documentation
- Comprehensive README with installation and usage examples
- MIT License
- Example application demonstrating all features
