# Hyperliquid Dart SDK - Roadmap

## SDK Expansion Phases (In Progress)

### ✅ Completed Phases (1-16)

**Phase 1-3: InfoClient Methods** ✅ Complete
- orderStatus() - Look up order by ID
- portfolio() - Account value and PnL history
- fundingHistory() - Historical funding rates

**Phase 4-5: ExchangeClient Methods** ✅ Complete
- modify() / batchModify() - Order modification
- scheduleCancel() - Dead man's switch

**Phase 6-8: WebSocket Subscriptions** ✅ Complete
- subscribeBbo() - Best bid/offer
- subscribeWebData3() - Aggregate account data
- subscribeNotification() - System notifications

**Phase 9: TWAP Orders** ✅ Complete
- twapOrder() / twapCancel() - TWAP order placement and cancellation
- subscribeTwapStates() - TWAP execution states
- subscribeUserTwapSliceFills() - Individual TWAP fills
- subscribeUserTwapHistory() - Historical TWAP events

**Results:**
- API Coverage: 31 → 45 methods (+45%)
- Test Files: 5 → 17 (+240%)
- Static Analysis: ✅ Zero issues
- ExchangeClient: 11 → 13 methods
- WebSocketClient: 11 → 14 subscriptions

---

**Phase 10: Spot Market Support** ✅ Complete
- InfoClient.spotMeta() - Get all spot tokens metadata
- InfoClient.spotMetaAndAssetCtxs() - Get spot metadata + market data
- InfoClient.tokenDetails() - Get detailed token information by token ID

**Phase 11: Sub-Account Management** ✅ Complete
- InfoClient.subAccounts() - Query user's sub-accounts ✅
- ExchangeClient vaultAddress support - Trade on behalf of sub-accounts ✅
- Note: Sub-account creation/deletion done via web UI, not API

**Results (Phase 10-11):**
- InfoClient: 21 → 22 methods (+5%)
- Enhanced all 9 ExchangeClient action methods with vaultAddress parameter
- Test Coverage: 12 → 13 passing tests (93% pass rate)

---

**Phase 12: HIP-3 Builder-Deployed Perpetuals** ✅ Complete
- InfoClient.perpDexs() - Get list of all HIP-3 DEXs ✅
- InfoClient.meta(dex) - NEW: Fetch metadata for specific DEX ✅
- InfoClient.metaAndAssetCtxs(dex) - Enhanced with optional dex parameter ✅
- Complete HIP-3 trading support (asset ID calculation + API queries) ✅

**Results (Phase 12):**
- InfoClient: 22 → 24 methods (+9% - added perpDexs() and meta())
- Enhanced 1 existing method (metaAndAssetCtxs) with dex parameter
- Test Coverage: 13 → 14 passing tests (93% pass rate)
- Full HIP-3 support: Can query DEXs, get metadata, calculate asset IDs, place orders
- Example file: hip3_trading_example.dart demonstrates complete workflow

---

**Phase 13: Additional Utilities** ✅ Complete
- InfoClient.userFees() - Get user's fee structure and trading costs ✅
- InfoClient.userNonFundingLedgerUpdates() - Get deposits, withdrawals, transfers ✅
- ExchangeClient.usdClassTransfer() - Transfer USDC between spot and perp ✅
- ExchangeClient.usdSend() - Send USDC to another address ✅

**Results (Phase 13):**
- InfoClient: 24 → 26 methods (+8% increase)
- ExchangeClient: 13 → 15 methods (+15% increase)
- Test Coverage: 14 → 17 tests (3 new test files with comprehensive coverage)
- New models: UserFees, LedgerUpdate, LedgerDelta, DailyUserVolume, ActiveStakingDiscount, FeeTrial
- Full account management: Can query fees, track ledger history, transfer funds

---

**Phase 14: WebSocket Ledger Subscriptions** ✅ Complete
- WebSocketClient.subscribeUserNonFundingLedgerUpdates() - Real-time ledger events ✅

**Results (Phase 14):**
- WebSocketClient: 14 → 15 subscriptions (+7% increase)
- Test Coverage: 17 → 18 passing tests (94% pass rate)
- New capability: Real-time monitoring of deposits, withdrawals, USD transfers
- Example file: ledger_monitor_example.dart demonstrates event monitoring

**Target Coverage After Phase 14:**
- InfoClient: 26 methods (47% of TypeScript SDK)
- ExchangeClient: 15 methods (30% of TypeScript SDK)
- WebSocketClient: 15 subscriptions (~79% of TypeScript SDK)
- **Overall: ~52% coverage** of commonly-used methods

---

**Phase 15: Spot Token Trading & Order Placement** ✅ Complete
- InfoClient.getSpotAssetId() - Helper to calculate spot asset IDs ✅
- ExchangeClient.spotUser() - Toggle spot dusting settings ✅
- ExchangeClient.spotSend() - Send spot tokens to another address ✅
- ExchangeClient.sendAsset() - Transfer assets between DEXs/addresses/sub-accounts ✅
- ExchangeClient.subAccountTransfer() - Transfer USDC to/from sub-accounts ✅
- ExchangeClient.subAccountSpotTransfer() - Transfer spot tokens to/from sub-accounts ✅

**Results (Phase 15):**
- InfoClient: 26 → 27 methods (+4% increase)
- ExchangeClient: 15 → 20 methods (+33% increase)
- Test Coverage: 18 → 19 passing tests (95% pass rate)
- New models: Multiple spot-related models
- Full spot trading: Can place orders, transfer tokens, manage sub-accounts
- Example files: spot_trading_example.dart, spot_order_trading_example.dart

---

**Phase 16: Vault Operations** ✅ Complete
- InfoClient.vaultDetails() - Get detailed vault information ✅
- InfoClient.vaultSummaries() - Get all vault summaries ✅
- InfoClient.leadingVaults() - Get vaults by specific leader ✅
- InfoClient.userVaultEquities() - Get user's vault positions ✅
- ExchangeClient.vaultTransfer() - Deposit/withdraw USDC to/from vaults ✅

**Results (Phase 16):**
- InfoClient: 27 → 31 methods (+15% increase)
- ExchangeClient: 20 → 21 methods (+5% increase)
- Test Coverage: 19 → 21 passing tests (95% pass rate)
- New models: VaultDetails, VaultSummary, LeadingVault, UserVaultEquity, VaultPortfolio, PortfolioPeriod, VaultFollower, VaultRelationship
- Complete vault management: Can query vaults, check positions, deposit/withdraw funds
- Example file: vault_example.dart demonstrates full vault operations
- Known issue: vaultSummaries may return empty (use leadingVaults instead)

**Target Coverage After Phase 16:**
- InfoClient: 31 methods (56% of TypeScript SDK)
- ExchangeClient: 21 methods (42% of TypeScript SDK)
- WebSocketClient: 15 subscriptions (~79% of TypeScript SDK)
- **Overall: ~56% coverage** of commonly-used methods

---

### 📋 Upcoming Phases

## Immediate (Optional SDK Polish)
**Time:** 1-2 days

1. **Write README.md** ✅ Complete
   - Installation instructions
   - Quick start examples (REST, WebSocket, trading)
   - Link to full API docs
   - License and contribution guidelines

2. **Add dartdoc comments**
   - Document all public APIs
   - Add code examples to doc comments
   - Run `dart doc` to generate HTML docs

3. **Publish to pub.dev**
   - Create CHANGELOG.md with v0.1.0 entry ✅ Complete
   - Choose license (MIT recommended) ✅ Complete
   - Run `dart pub publish --dry-run` to verify
   - Publish as `hyperliquid_dart` v0.1.0

---

## Phase 1: Riten-Flutter App Setup (1-2 weeks)
**Goal:** Basic app with Privy auth + SDK integration

**Week 1: Dependencies & Config**
1. Add SDK dependency to `pubspec.yaml`:
   ```yaml
   dependencies:
     hyperliquid_dart:
       path: ../Hyperliquid-Dart-SDK
   ```

2. Lock orientation to landscape:
   - `android/app/src/main/AndroidManifest.xml`: Add `android:screenOrientation="sensorLandscape"`
   - `ios/Runner/Info.plist`: Remove portrait orientations
   - `lib/main.dart`: Add `SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])`

3. Install routing & state packages:
   ```yaml
   dependencies:
     go_router: ^14.0.0
     riverpod: ^2.6.1
     flutter_riverpod: ^2.6.1
     privy_flutter: ^0.6.0
     flutter_dotenv: ^5.2.1
   ```

**Week 2: Auth & Basic Navigation**
1. Set up `go_router` with 3 routes:
   - `/login` — Privy email login screen
   - `/trading` — Main trading screen (protected)
   - `/portfolio` — Portfolio screen (protected)

2. Build `PrivyWalletAdapter`:
   ```dart
   class PrivyWalletAdapter implements WalletAdapter {
     final PrivyClient _privy;

     @override
     Future<String> getAddress() async {
       return await _privy.getAddress();
     }

     @override
     Future<String> signTypedData(Map<String, dynamic> typedData) async {
       return await _privy.eth_signTypedData_v4(typedData);
     }
   }
   ```

3. Create Riverpod providers:
   - `hyperliquidProvider` — InfoClient + ExchangeClient + WebSocketClient
   - `walletProvider` — PrivyWalletAdapter
   - `authProvider` — Login state

4. Test end-to-end:
   - Login with Privy → Get address → Place test order → Cancel

**Gate:** Can login with Privy, sign EIP-712, and place/cancel order on mainnet

---

## Phase 2: Real-Time Data Layer (1 week)
**Goal:** Stream live market data into Riverpod state

1. Create WebSocket providers:
   - `allMidsProvider` — Stream<Map<String, String>>
   - `l2BookProvider(coin)` — Stream<L2Book>
   - `candleProvider(coin, interval)` — Stream<List<Candle>>

2. Auto-reconnect handling:
   - Listen to connection state
   - Show "reconnecting" indicator
   - Re-fetch initial state after reconnect

3. Memory management:
   - Bound candles to last 500
   - Bound L2 book to top 20 levels
   - Dispose streams on route change

**Gate:** Live BTC price updates at ~1/sec with <100MB memory after 1 hour

---

## Phase 3: Core Trading UI (2-3 weeks)
**Goal:** Orderbook, chart, and order placement

1. **Orderbook widget** (3-4 days)
   - Bid/ask split view
   - Price, size, total columns
   - Click-to-fill order form
   - Highlight user orders

2. **Candlestick chart** (3-4 days)
   - Use Syncfusion Charts or Deriv flutter-chart
   - 1m/5m/15m/1h/4h interval selector
   - Volume bars
   - Current price line

3. **Order placement UI** (3-4 days)
   - Market/limit/trigger tabs
   - Size input with max/25%/50%/75% buttons
   - Price input for limit orders
   - Leverage selector
   - Confirm modal with summary

4. **Order notification system** (2-3 days)
   - Listen to `orderUpdates` stream
   - Show toast on fill/cancel/rejection
   - Haptic feedback on order actions

**Gate:** Can view live BTC orderbook, place and cancel orders from UI at 60fps

---

## Phase 4: Position Management (1-2 weeks)
1. Positions tab with PNL/ROE calculation
2. Open orders tab with cancel buttons
3. Close position modal
4. Account summary header

---

## Phase 5-7: Advanced Features (4-6 weeks)
- Portfolio screens
- TWAP orders
- Funding history
- Settings & preferences
- iOS + Android testing

---

## Estimated Timeline

| Phase | Duration | Milestone |
|-------|----------|-----------|
| SDK Polish | 1-2 days | pub.dev published |
| App Setup | 1-2 weeks | Login + test order |
| Data Layer | 1 week | Live streaming works |
| Core UI | 2-3 weeks | Trade from UI |
| Position Mgmt | 1-2 weeks | Full trading flow |
| Advanced | 4-6 weeks | Feature parity with RN app |
| **Total** | **10-14 weeks** | Production-ready Flutter app |
