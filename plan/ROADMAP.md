# Hyperliquid Dart SDK - Roadmap

Current roadmap after reviewing the SDK against the official Hyperliquid docs
on 2026-06-24.

---

## Status summary

The SDK already covers the important live-trading base:

- core Info API market and account queries
- signed order placement, cancellation, modification, leverage, margin, TWAP,
  spot transfer, sub-account transfer, vault transfer, and withdrawal actions
- HIP-3 DEX metadata and trading support
- 15 WebSocket subscriptions
- EIP-712 signing and Keccak action hashing
- live integration examples and tests

The next phase should clean up current-doc parity gaps, not rebuild the trading
core.

---

## Completed foundation

Keep these marked complete:

- Core REST transport
- Core WebSocket transport with reconnect/resubscribe behavior
- Wallet adapter abstraction
- Private-key wallet adapter
- Keccak action hash fix
- EIP-712 signing helpers
- Perp and spot order placement
- Order cancellation by oid and cloid
- Order modification and batch modification
- Dead man's switch via `scheduleCancel`
- TWAP order and cancel actions
- Leverage and isolated margin updates
- Core USDC transfer and withdrawal
- Spot/perp class transfer
- Spot token send
- Cross-DEX `sendAsset`
- Sub-account transfers
- Vault queries and vault transfer
- Builder-fee approval and max-fee query
- HIP-3 metadata and DEX-aware asset lookup
- Main market WebSocket streams
- User event, fill, funding, ledger, notification, WebData3, and TWAP streams

---

## P0 - WebSocket parity and correctness cleanup

This is the first cleanup target because the SDK advertises high WebSocket
coverage, but the current official docs list 22 subscriptions and the SDK
currently exposes 15 typed methods.

### Add typed subscriptions

- `subscribeClearinghouseState(user, dex?)`
- `subscribeOpenOrders(user, dex?)`
- `subscribeActiveAssetCtx(coin)`
- `subscribeActiveAssetData(user, coin)`
- `subscribeSpotState(user, isPortfolioMargin?)`
- `subscribeAllDexsClearinghouseState(user)`
- `subscribeAllDexsAssetCtxs()`

### Fix existing subscription builder issues

- Ensure `SubscriptionType.clearinghouseState` emits `{ type: "clearinghouseState", user, dex? }`
- Ensure `SubscriptionType.openOrders` emits `{ type: "openOrders", user, dex? }`
- Add optional `dex` support for `allMids` and `twapStates`
- Add `aggregateByTime` support for `userFills`
- Preserve `isSnapshot` metadata for snapshot-capable user streams

### Tests

- Unit-test subscription payload construction for every enum value.
- Add opt-in live WebSocket tests for the seven newly typed subscriptions.

---

## P0 - low-risk Info API parity

These are request/response wrappers with no new signing surface.

- `userRateLimit(user)`
- `userRole(user)`
- `referral(user)`
- `delegations(user)`
- `delegatorSummary(user)`
- `delegatorHistory(user)`
- `delegatorRewards(user)`
- `userDexAbstraction(user)`
- `userSetAbstraction(user)`
- `userTwapSliceFills(user)`

### Parameter cleanup

- Add optional `dex` to `allMids`
- Audit and add optional `dex` to user-scoped perp endpoints where the docs
  support it, especially `openOrders`, `frontendOpenOrders`, and
  `clearinghouseState`
- Refresh candle interval constants to include all documented intervals:
  `1m`, `3m`, `5m`, `15m`, `30m`, `1h`, `2h`, `4h`, `8h`, `12h`, `1d`, `3d`,
  `1w`, `1M`

---

## P1 - signed account and admin actions

Add signed actions that are documented today but missing from `ExchangeClient`.
These should be implemented with focused request models and tests for exact
wire payload shape before any live-test expansion.

- `approveAgent(agentAddress, agentName?)`
- `reserveRequestWeight(weight)`
- `noop()`
- `claimRewards()`
- `sendToEvmWithData(...)`
- `cDeposit(wei)`
- `cWithdraw(wei)`
- staking delegate / undelegate
- `userSetAbstraction(user, abstraction)`
- `agentSetAbstraction(abstraction)`
- deprecated compatibility wrappers:
  `userDexAbstraction(user, enabled)` and `agentEnableDexAbstraction()`
- `topUpIsolatedOnlyMargin(asset, leverage)`

### Design note

Keep trading actions on `ExchangeClient`, but consider a small
`AccountAdminClient` wrapper if the API starts to feel crowded. The signing
pipeline can stay shared.

---

## P1 - Bridge2 completion

The SDK has `withdraw3`, but the current Bridge2 docs also describe deposit
flows and deposit-with-permit.

- Add Bridge2 constants for mainnet and testnet bridge contracts.
- Add USDC permit typed-data builder for deposit-with-permit.
- Add helper models for permit payloads and signatures.
- Document that normal deposits are Arbitrum transactions, not Hyperliquid
  exchange actions.
- Add tests for typed-data shape and signature splitting.

---

## P2 - deployment and builder-deployer clients

These are specialized workflows and should not be mixed into normal trading
helpers.

### HIP-1/HIP-2 spot deployment

Add a `SpotDeployClient` or `DeployClient` namespace for:

- `registerToken2`
- `userGenesis`
- `genesis`
- `registerSpot`
- `registerHyperliquidity`
- `setDeployerTradingFeeShare`
- `enableQuoteToken`
- `enableAlignedQuoteToken`
- spot deploy auction status query wrappers

### HIP-3 perp deployment

Add a `PerpDeployClient` namespace for:

- `registerAsset2`
- `registerAsset`
- `setOracle`
- `setFundingMultipliers`
- `setFundingInterestRates`
- `haltTrading`
- `setMarginTableIds`
- `setFeeRecipient`
- `setOpenInterestCaps`
- `setSubDeployers`
- `setMarginModes`
- `setFeeScale`
- `setGrowthModes`
- `setPerpAnnotation`
- perp deploy auction status query wrappers

### Tests

- Payload serialization tests are required.
- Live tests should be opt-in only because deployment actions are expensive and
  stateful.

---

## P2 - documentation and examples cleanup

- Replace stale TypeScript SDK percentage claims with a generated coverage
  matrix based on current official docs.
- Add examples for:
  - API wallet approval
  - user rate limits and reserve weight
  - staking read and write flows
  - abstraction state read and update
  - full WebSocket subscription matrix
  - Bridge2 deposit-with-permit typed data
- Regenerate Dart API docs after public API changes.
- Keep live-test prerequisites explicit so users do not confuse account
  eligibility failures with SDK failures.

---

## Explicit non-priorities

These should wait until the current-doc cleanup is done:

- cosmetic refactors that do not improve parity
- app-specific Flutter state management
- broad deployer live tests
- publishing until README coverage claims match the current docs

---

## Short-term milestone proposal

### v0.2.0 - WebSocket and Info cleanup

- Missing typed WebSocket subscriptions
- Subscription payload fixes
- Snapshot metadata preservation
- User role, rate limit, referral, staking read, abstraction read, and TWAP
  slice fill Info wrappers
- Candle interval refresh
- Optional `dex` parameter audit

### v0.3.0 - account actions and staking

- API wallet approval
- reserve request weight
- nonce invalidation
- claim rewards
- staking deposit, withdrawal, delegate, undelegate
- abstraction setters
- send to EVM with data
- alternate isolated-margin top-up

### v0.4.0 - Bridge2 and deployer foundations

- Bridge2 deposit-with-permit helpers
- HIP-1/HIP-2 deploy payload support
- HIP-3 deploy payload support
- deployment info queries
- generated coverage matrix

---

## Bottom line

As of 2026-06-24, the SDK is already usable for normal trading integrations.
The roadmap now is about closing the current official-doc gap cleanly:

- fix WebSocket parity first
- add low-risk Info wrappers
- add signed account/staking/admin actions
- isolate advanced deployer workflows into dedicated clients
- update docs so coverage claims stay true
