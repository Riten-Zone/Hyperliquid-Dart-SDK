# Hyperliquid Dart SDK - Achievements

Last reviewed against the official Hyperliquid docs on 2026-06-25.

Sources checked:

- Official Info endpoint docs
- Official Exchange endpoint docs
- Official WebSocket subscription docs
- Bridge2 docs
- HIP-1/HIP-2 asset deployment docs
- HIP-3 deployer action docs
- HIP-4 outcome market docs
- `nktkas/hyperliquid` TypeScript SDK public client surface
- `hyperliquid-dex/hyperliquid-python-sdk` public client surface
- `nomeida/hyperliquid` TypeScript SDK public client surface
- Current local SDK source under `lib/src`

---

## Current verified state

The SDK is already a practical direct HyperCore client, not a thin placeholder.
It includes:

- Read-only Info API coverage for core market data, user state, spot metadata,
  HIP-3 DEX metadata, fees, ledger updates, portfolio, vaults, and funding data.
- Exchange API coverage for orders, cancels, order modification, leverage,
  isolated margin, transfers, spot sends, sub-account transfers, vault transfers,
  builder-fee approval, TWAP order lifecycle, and withdrawals.
- WebSocket coverage for 15 typed subscriptions, including L2 books, trades,
  candles, all mids, BBO, notifications, WebData3, user fills, order updates,
  user events, fundings, non-funding ledger updates, and TWAP streams.
- Wallet-agnostic signing via `WalletAdapter`, plus a private-key adapter for
  bots, tests, and CLI usage.
- Correct Keccak-256 action hashing and EIP-712 signing support.
- Live integration tests and examples for the main trading, spot, HIP-3, ledger,
  TWAP, and vault workflows.

Compared with the February 2026 plan, the SDK has moved from a basic trading
client to a broad HyperCore SDK.

---

## What still matches the official docs

### Info API

Implemented and still aligned:

- `allMids`
- `meta`
- `metaAndAssetCtxs`
- `openOrders`
- `frontendOpenOrders`
- `userFills`
- `userFillsByTime`
- `orderStatus`
- `l2Book`
- `candleSnapshot`
- `maxBuilderFee`
- `historicalOrders`
- `subAccounts`
- `vaultDetails`
- `userVaultEquities`
- `portfolio`
- `userFees`
- `userNonFundingLedgerUpdates`
- `spotClearinghouseState`
- `clearinghouseState`
- `spotMeta`
- `spotMetaAndAssetCtxs`
- `tokenDetails`
- `fundingHistory`
- `recentTrades`
- `perpDexs`
- `vaultSummaries`
- `leadingVaults`
- HIP-4 `outcomeMeta`
- HIP-4 `settledOutcome`

### Exchange API

Implemented and still aligned:

- place order
- cancel by order id
- cancel by client order id
- schedule cancel
- modify order
- batch modify
- update leverage
- update isolated margin
- core USDC transfer
- withdrawal through `withdraw3`
- spot/perp USDC class transfer
- core spot transfer
- send asset
- vault transfer
- approve builder fee
- TWAP order
- TWAP cancel
- HIP-4 `userOutcome`
- HIP-4 `splitOutcome`
- HIP-4 `mergeOutcome`
- HIP-4 `mergeQuestion`
- HIP-4 `negateOutcome`

### WebSocket API

Implemented typed subscriptions:

- `allMids`
- `notification`
- `webData3`
- `twapStates`
- `candle`
- `l2Book`
- `trades`
- `orderUpdates`
- `userEvents`
- `userFills`
- `userFundings`
- `userNonFundingLedgerUpdates`
- `userTwapSliceFills`
- `userTwapHistory`
- `bbo`

---

## Gap review vs current official docs

The current docs and the newer TypeScript SDK expose a wider surface than this
SDK currently wraps. The remaining gap is no longer "basic trading"; it is
account administration, staking, abstraction controls, deployment actions,
borrow/lend endpoints, newer network/status endpoints, and documentation for
the newly added HIP-4 outcome-market workflows.

### High-confidence missing Info endpoints

- `userRateLimit`
- `userRole`
- `referral`
- `delegations`
- `delegatorSummary`
- `delegatorHistory`
- `delegatorRewards`
- `userDexAbstraction`
- `userSetAbstraction`
- `userTwapSliceFills`
- `userTwapSliceFillsByTime`
- `twapHistory`
- `activeAssetData`
- `approvedBuilders`
- `allPerpMetas`
- `predictedFundings`
- `exchangeStatus`
- `extraAgents`
- `preTransferCheck`
- `userToMultiSigSigners`
- `userAbstraction`
- `subAccounts2`
- `validatorSummaries`
- `validatorL1Votes`
- `perpsAtOpenInterestCap`
- `perpDexStatus`
- `perpDexLimits`
- `perpAnnotation`
- `perpCategories`
- `perpConciseAnnotations`
- borrow/lend info: `allBorrowLendReserveStates`, `borrowLendReserveState`,
  `borrowLendUserState`, `userBorrowLendInterest`
- network/status info: gossip priority auction status, gossip root IPs,
  margin table, max market order notionals, liquidatable accounts, legal/VIP
  checks
- spot deploy auction status and related HIP-1/HIP-2 deployment info endpoints
- perp deploy auction status and related HIP-3 deployment info endpoints

### High-confidence missing Exchange actions

- `approveAgent`
- `sendToEvmWithData`
- `cDeposit`
- `cWithdraw`
- staking delegate / undelegate action
- `reserveRequestWeight`
- `noop`
- `userSetAbstraction`
- `agentSetAbstraction`
- deprecated but still documented `userDexAbstraction`
- deprecated but still documented `agentEnableDexAbstraction`
- validator risk-free-rate vote
- `claimRewards`
- `setReferrer`
- `registerReferrer`
- `createSubAccount`
- `subAccountModify`
- `createVault`
- `vaultDistribute`
- `vaultModify`
- `convertToMultiSigUser`
- multi-sig action submission and signer lookup support
- `evmUserModify`
- `agentSendAsset`
- `borrowLend`
- `authorizeAqav2Role`
- `linkStakingUser`
- `stakingLinkDisableTradingUser`
- `cSignerAction`
- `cValidatorAction`
- `validatorL1Stream`
- `finalizeEvmContract`
- `gossipPriorityBid`
- `hip3LiquidatorTransfer`
- HIP-1/HIP-2 `spotDeploy` actions
- HIP-3 `perpDeploy` actions
- `topUpIsolatedOnlyMargin` alternate isolated-margin action

### High-confidence missing WebSocket subscriptions

- `clearinghouseState`
- `openOrders`
- `activeAssetCtx`
- `activeAssetData`
- `spotState`
- `allDexsClearinghouseState`
- `allDexsAssetCtxs`
- `activeSpotAssetCtx`
- `assetCtxs`
- `fastAssetCtxs`
- `spotAssetCtxs`
- `userHistoricalOrders`
- `webData2`

The enum includes some of these names, but the high-level client does not yet
expose typed methods and some enum mappings currently route to unrelated
subscription payloads.

### Needs audit before feature work

- `allMids` supports a `dex` parameter in the docs; the SDK currently exposes
  the default source only.
- Many user-scoped Info endpoints now accept optional `dex`; the SDK should
  audit where that parameter is missing.
- Candle docs list more intervals than older examples: `3m`, `30m`, `2h`,
  `8h`, `12h`, `3d`, `1w`, and `1M`.
- WebSocket user streams send snapshot messages with `isSnapshot`; models and
  handlers should preserve this consistently.
- Bridge2 deposit-with-permit is documented but not wrapped.
- Asset deployment and deployer operations are specialized and should be
  isolated from the regular trading client rather than mixed into
  `ExchangeClient`.
- HIP-4 outcome markets add spot-like trading with different asset-id,
  metadata, settlement, and split/merge/negate semantics. These should get
  dedicated models/helpers rather than being treated as ordinary spot tokens.
- `nktkas/hyperliquid` is currently the strongest parity reference. It exposes
  HIP-4, borrow/lend, additional WebSocket channels, multi-sig, request expiry,
  vault creation/modification, referrer actions, and more exchange/admin
  actions that are absent from this Dart SDK.

---

## Cleanup direction

The new plan should clean up the remaining gap in this order:

1. Add HIP-4 docs/examples for outcome asset ids, merged Yes/No books, and
   settlement fractions.
2. Add low-risk Info endpoint parity for rate limits, role, referrals, staking
   read APIs, abstraction state, TWAP slice fills, borrow/lend, and deployer
   status.
3. Add account and admin Exchange actions: API wallet approval, reserve weight,
   nonce invalidation, abstraction controls, reward claim, staking actions, and
   EVM transfer with data.
4. Split advanced deployer functionality into dedicated clients for HIP-1/HIP-2
   spot deployment and HIP-3 perp deployment.
5. Refresh README/API docs and examples so the stated coverage matches the
   current official docs.

---

## Bottom line

As of 2026-06-24, `hyperliquid_dart` is strong for normal trading, account
queries, spot transfers, HIP-3 trading access, TWAP, and vault usage.

The main gap is current official-doc parity around:

- user/account administration
- staking
- unified account / portfolio-margin abstraction controls
- WebSocket subscription completeness
- API wallet approval and operational account actions
- Bridge2 deposit-with-permit
- HIP-1/HIP-2 and HIP-3 deployer workflows
- HIP-4 outcome-market docs and examples
- borrow/lend and newer network/status endpoints
- multi-sig and request-expiry support
