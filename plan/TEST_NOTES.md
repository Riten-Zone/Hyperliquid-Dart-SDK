# Integration Test Notes

## Account Requirements

Certain Hyperliquid API endpoints have account-level requirements that may cause tests to fail or skip on accounts that don't meet the criteria.

### Schedule Cancel (Dead Man's Switch)

**Endpoint:** `ExchangeClient.scheduleCancel()`

**Requirement:** Account must have **$1,000,000+ in trading volume** on mainnet

**Test Behavior:**
- Test file: `test/exchange/schedule_cancel_test.dart`
- If account doesn't meet volume requirement, API returns error
- Test expects success but will fail on low-volume accounts

**Workaround:** Tests pass on high-volume accounts. For development testing, verify the request format is correct even if response is an error.

---

## Margin and Account Balance

**Issue:** Some integration tests require sufficient margin/balance to place orders

**Affected Tests:**
- Tests that place orders may fail if account has insufficient margin
- Signing integration tests that attempt actual trades

**Test Behavior:**
- Order placement tests use prices far from market (50% of mid) to avoid fills
- Tests cancel orders immediately after placement
- Minimal sizes used (0.001 BTC)

**Workaround:** Fund test account with small amount of USDC for testing. Tests designed to be non-destructive and use minimal capital.

---

## Response Format Variations

**Issue:** Some API responses have variable formats depending on order state

**Example - Order Placement:**
```dart
// Standard response when order rests in book
{
  "data": {
    "statuses": [
      {"resting": {"oid": 123456}}
    ]
  }
}

// Response when order fills immediately
{
  "data": {
    "statuses": [
      {"filled": {...}}
    ]
  }
}
```

**Test Handling:**
- Tests now check if `resting` field exists before accessing
- Tests skip gracefully if order doesn't rest (e.g., immediate fill)
- Added null safety checks throughout response parsing

**Fixed in:**
- `test/exchange/modify_test.dart` (lines 49-65)
- `test/info/order_status_test.dart` (lines 67-84)

---

## WebSocket Subscription Format

**Issue:** WebSocket subscriptions return different formats for initial snapshot vs updates

**Pattern:**
```dart
// Initial snapshot
{"channel": "twapStates", "data": {}}  // Empty Map

// Subsequent updates
{"channel": "twapStates", "data": [...]}  // List of states
```

**Test Handling:**
- All WebSocket handlers check data type before casting
- Handle both `Map` (initial) and `List` (updates) formats
- Empty snapshots don't cause errors

**Fixed in:**
- `lib/src/clients/websocket_client.dart` (lines 217-291)
- All TWAP WebSocket subscriptions (states, history, slice fills)

---

## Test Execution Tips

### Run All Integration Tests
```bash
HYPERLIQUID_PRIVATE_KEY=0x... dart test --tags integration
```

### Run Specific Test File
```bash
HYPERLIQUID_PRIVATE_KEY=0x... dart test test/exchange/twap_test.dart --tags integration
```

### Skip Tests That Require High Volume
```bash
# Schedule cancel test will fail on low-volume accounts - this is expected
dart test --exclude-tags integration  # Run unit tests only
```

### Verify Test Account
Before running integration tests, verify your account:
1. Check balance: `info.clearinghouseState(user)`
2. Check positions: Should be empty for clean tests
3. Check open orders: Cancel all before running full suite

---

## Test Coverage Summary

| Category | Files | Status | Notes |
|----------|-------|--------|-------|
| Unit Tests | 4 files | ✅ All pass | No API key needed |
| Info Client | 3 files | ✅ All pass | orderStatus, portfolio, fundingHistory |
| Exchange Client | 3 files | ⚠️ Mostly pass | scheduleCancel requires high volume |
| WebSocket | 6 files | ✅ All pass | All subscription types validated |
| TWAP Orders | 4 files | ✅ All pass | Full TWAP lifecycle tested |

**Total:** 17 integration test files, ~50+ individual test cases

---

## Recent Fixes (2026-02-10)

### Phase 9 TWAP Implementation
- **Issue:** Wrong wire format for TWAP orders (included price field, wrong randomize type)
- **Fix:** Corrected to `{a, b, s, r, m, t}` format per official docs
- **Result:** All 10 TWAP tests now pass

### Response Parsing Errors
- **Issue:** Type cast errors when extracting order IDs from responses
- **Fix:** Added null checks for `resting` field, graceful skip if not present
- **Files:** modify_test.dart, order_status_test.dart

### Test Setup Errors
- **Issue:** `LateInitializationError` in portfolio and notification tests
- **Fix:** Changed `setUpAll() async {}` to `setUpAll(() async {})`
- **Files:** portfolio_test.dart, notification_test.dart

### WebSocket Type Errors
- **Issue:** Casting errors for TWAP WebSocket subscriptions
- **Fix:** Handle both Map and List data formats
- **Files:** websocket_client.dart (all TWAP subscriptions)
