# Testing Guide - Hyperliquid Dart SDK

Complete guide for running integration tests against Hyperliquid mainnet API.

## Quick Start

### Prerequisites
1. Export your Hyperliquid private key:
   ```bash
   export HYPERLIQUID_PRIVATE_KEY=0x...
   ```

2. Ensure account has small USDC balance for test orders (~$1 minimum)

### Run All Tests
```bash
./test/run_all_tests.sh
```

### Run Single Test
```bash
./test/run_single_test.sh order_status
```

## Test Scripts

### `run_all_tests.sh`
Runs all 12 integration tests sequentially and generates comprehensive reports.

**Features:**
- Runs each test category (Info, Exchange, WebSocket)
- Captures full output for each test
- Generates summary files
- Creates JSON report
- Color-coded results (✓ PASSED, ✗ FAILED, ⚠ SKIPPED)

**Usage:**
```bash
HYPERLIQUID_PRIVATE_KEY=0x... ./test/run_all_tests.sh
```

**Output Files:**
- `test/results/info_order_status_test.txt` - Full test output
- `test/results/info_order_status_summary.txt` - Key results
- `test/results/test_summary.json` - Overall report

**Example Output:**
```
==========================================
Hyperliquid Dart SDK - Test Suite Runner
==========================================

=== INFO CLIENT TESTS ===
----------------------------------------
Running: order_status_test (info)
----------------------------------------
✓ PASSED

----------------------------------------
Running: portfolio_test (info)
----------------------------------------
✓ PASSED

... (continued)

==========================================
TEST SUITE SUMMARY
==========================================

Total Tests:   12
Passed:        10
Failed:        0
Skipped:       2

Pass Rate: 83%
==========================================
```

### `run_single_test.sh`
Runs a specific test with verbose output for debugging.

**Usage:**
```bash
./test/run_single_test.sh <test_name>
```

**Available Tests:**
- Info Client: `order_status`, `portfolio`, `funding_history`
- Exchange Client: `modify`, `schedule_cancel`, `twap`
- WebSocket: `bbo`, `web_data3`, `notification`, `twap_states`, `twap_history`, `twap_slice_fills`

**Example:**
```bash
HYPERLIQUID_PRIVATE_KEY=0x... ./test/run_single_test.sh twap
```

**Output:**
- Displays results in terminal (color-coded)
- Saves to `test/results/<test_name>_detailed.txt`

## Test Categories

### Info Client Tests (3 tests)

#### 1. Order Status Test
**File:** `test/info/order_status_test.dart`

**What it tests:**
- Look up non-existent order (returns `unknownOid`)
- Place order, check status (should be `open`)
- Cancel order, verify status changed to `canceled`

**Expected Response Format:**
```json
{
  "status": "order",
  "order": {
    "order": {
      "coin": "BTC",
      "side": "B",
      "limitPx": "34319.0",
      "sz": "0.001",
      "oid": 317464545205,
      "timestamp": 1707580800000
    },
    "status": "open",
    "statusTimestamp": 1707580800000
  }
}
```

#### 2. Portfolio Test
**File:** `test/info/portfolio_test.dart`

**What it tests:**
- Fetch portfolio data for all time periods
- Validate data structure (accountValueHistory, pnlHistory, vlm)
- Check all expected periods exist (day, week, month, allTime, perp variants)

**Expected Response Format:**
```json
[
  ["day", {
    "accountValueHistory": [[1707580800000, "1000.50"], ...],
    "pnlHistory": [[1707580800000, "10.25"], ...],
    "vlm": "5000.00"
  }],
  ["week", {...}],
  ["month", {...}],
  ["allTime", {...}],
  ["perpDay", {...}],
  ["perpWeek", {...}],
  ["perpMonth", {...}],
  ["perpAllTime", {...}]
]
```

#### 3. Funding History Test
**File:** `test/info/funding_history_test.dart`

**What it tests:**
- Fetch BTC funding history for last 24 hours
- Validate data structure (coin, fundingRate, premium, time)
- Test with different time ranges

**Expected Response Format:**
```json
[
  {
    "coin": "BTC",
    "fundingRate": "0.0001",
    "premium": "0.00005",
    "time": 1707580800000
  },
  ...
]
```

### Exchange Client Tests (3 tests)

#### 4. Modify Test
**File:** `test/exchange/modify_test.dart`

**What it tests:**
- Place order, modify price and size
- Batch modify multiple orders
- Verify modifications via openOrders

**Expected Response Format:**
```json
{
  "status": "ok",
  "response": {
    "type": "default",
    "data": {
      "statuses": [
        {"resting": {"oid": 317464545205}}
      ]
    }
  }
}
```

**Note:** `resting` may be null if order fills immediately (test skips gracefully)

#### 5. Schedule Cancel Test
**File:** `test/exchange/schedule_cancel_test.dart`

**What it tests:**
- Set schedule cancel time (10 minutes in future)
- Update existing schedule (20 minutes)

**Expected Response Format:**
```json
{
  "status": "ok",
  "response": {
    "type": "default",
    "data": {
      "status": "success"
    }
  }
}
```

**Known Limitation:** Requires $1M+ trading volume on mainnet
- Test will FAIL on low-volume accounts
- This is expected and documented

#### 6. TWAP Test
**File:** `test/exchange/twap_test.dart`

**What it tests:**
- Place TWAP order (0.001 BTC over 5 minutes)
- Extract TWAP ID from response
- Cancel TWAP order
- Test duration constraints (1 minute minimum)
- Test randomized execution flag

**Expected Response Format:**
```json
{
  "status": "ok",
  "response": {
    "type": "default",
    "data": {
      "status": {
        "running": {
          "twapId": 1592161
        }
      }
    }
  }
}
```

**TWAP Cancel Response:**
```json
{
  "status": "ok",
  "response": {
    "type": "default",
    "data": {
      "status": "success"
    }
  }
}
```

### WebSocket Tests (6 tests)

#### 7. BBO Test
**File:** `test/websocket/bbo_test.dart`

**What it tests:**
- Subscribe to BTC BBO (best bid/offer)
- Verify high-frequency updates (~1/sec)
- Validate bid/ask price structure

**Expected WebSocket Message:**
```json
{
  "channel": "bbo",
  "data": {
    "coin": "BTC",
    "bid": {"px": "68638.0", "sz": "1.5"},
    "ask": {"px": "68639.0", "sz": "2.0"},
    "time": 1707580800000
  }
}
```

#### 8. WebData3 Test
**File:** `test/websocket/web_data3_test.dart`

**What it tests:**
- Subscribe to aggregate user data stream
- Verify userState, perpDexStates structure
- Multiple subscription handling

**Expected WebSocket Message:**
```json
{
  "channel": "webData3",
  "data": {
    "userState": {
      "accountValue": "1000.50",
      "marginUsed": "100.00"
    },
    "perpDexStates": [...],
    "vaultsInfo": [...]
  }
}
```

#### 9. Notification Test
**File:** `test/websocket/notification_test.dart`

**What it tests:**
- Subscribe to notifications channel
- Handle empty notifications (inactive account)
- Multiple subscription handlers

**Expected WebSocket Message:**
```json
{
  "channel": "notification",
  "data": {
    "user": "0x...",
    "message": "Order filled: BTC 0.001 @ $68638"
  }
}
```

#### 10. TWAP States Test
**File:** `test/websocket/twap_states_test.dart`

**What it tests:**
- Subscribe to TWAP execution states
- Place TWAP order and receive state update
- Verify TWAP lifecycle (running → canceled)

**Expected WebSocket Message (Initial):**
```json
{
  "channel": "twapStates",
  "data": {}
}
```

**Expected WebSocket Message (Update):**
```json
{
  "channel": "twapStates",
  "data": [
    {
      "twapId": 1592161,
      "coin": "BTC",
      "isBuy": true,
      "sz": "0.001",
      "szFilled": "0.0003",
      "limitPx": "0.0",
      "durationMins": 5,
      "status": "running"
    }
  ]
}
```

#### 11. TWAP History Test
**File:** `test/websocket/twap_history_test.dart`

**What it tests:**
- Subscribe to TWAP history events
- Verify event structure (start, cancel, complete)

**Expected WebSocket Message:**
```json
{
  "channel": "userTwapHistory",
  "data": [
    {
      "twapId": 1592161,
      "event": "started",
      "time": 1707580800000
    }
  ]
}
```

#### 12. TWAP Slice Fills Test
**File:** `test/websocket/twap_slice_fills_test.dart`

**What it tests:**
- Subscribe to individual TWAP fill events
- Verify fill structure (price, size, timestamp)

**Expected WebSocket Message:**
```json
{
  "channel": "userTwapSliceFills",
  "data": [
    {
      "twapId": 1592161,
      "px": "68638.0",
      "sz": "0.0001",
      "time": 1707580800000,
      "oid": 317464545205
    }
  ]
}
```

## Understanding Test Results

### Test Status Codes

- **✓ PASSED** - Test completed successfully, all assertions passed
- **✗ FAILED** - Test failed unexpectedly, needs investigation
- **⚠ SKIPPED** - Test skipped due to known limitation (not a bug)

### Common Failure Reasons

1. **Insufficient Margin**
   - Error: "Insufficient margin for order"
   - Solution: Fund account with small USDC amount

2. **Volume Requirement**
   - Error: "User does not meet volume requirement"
   - Affected: `schedule_cancel` test
   - Solution: Test on high-volume account or accept skip

3. **Order Didn't Rest**
   - Warning: "No resting order in response"
   - Reason: Order filled immediately
   - Behavior: Test skips gracefully (not a failure)

4. **WebSocket Timeout**
   - Error: "No updates received in 30 seconds"
   - Reason: Account inactive, no events to stream
   - Behavior: Test may timeout (expected for inactive accounts)

## Analyzing Test Output

### Full Output Files
Located at `test/results/<category>_<test>_test.txt`

**Contains:**
- Complete test execution log
- API request/response details
- Print statements
- Error stack traces

**Use for:**
- Debugging failures
- Understanding API response format
- Verifying SDK behavior

### Summary Files
Located at `test/results/<category>_<test>_summary.txt`

**Contains:**
- Test status (1-line)
- Category
- Key output (top 20 lines)
- Error details (if failed)

**Use for:**
- Quick status check
- Identifying which tests failed
- Getting error messages without full log

### JSON Report
Located at `test/results/test_summary.json`

**Contains:**
```json
{
  "timestamp": "2026-02-10T12:00:00Z",
  "total": 12,
  "passed": 10,
  "failed": 0,
  "skipped": 2,
  "pass_rate": "83%",
  "categories": {
    "info": 3,
    "exchange": 3,
    "websocket": 6
  }
}
```

**Use for:**
- CI/CD integration
- Automated reporting
- Historical tracking

## Continuous Integration

### GitHub Actions Example
```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - name: Run Tests
        env:
          HYPERLIQUID_PRIVATE_KEY: ${{ secrets.HYPERLIQUID_PRIVATE_KEY }}
        run: ./test/run_all_tests.sh
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test/results/
```

## Best Practices

1. **Run tests on testnet first** (if available)
2. **Use minimal order sizes** to reduce cost
3. **Check account balance** before running
4. **Review full output** for unexpected behavior
5. **Document API changes** when response format changes
6. **Keep test account active** for WebSocket tests

## Troubleshooting

### Tests hang indefinitely
- Check network connection
- Verify private key is correct
- Ensure API endpoints are accessible

### All tests fail with "401 Unauthorized"
- Private key is invalid or incorrectly formatted
- Should be hex string starting with "0x"

### "Connection refused" errors
- Hyperliquid API may be down
- Check status at status.hyperliquid.xyz

### WebSocket tests timeout
- Normal for inactive accounts
- Tests expect activity within 30 seconds
- Run order placement first to generate events

## Support

For issues or questions:
- GitHub Issues: https://github.com/Riten-Zone/Hyperliquid-Dart-SDK/issues
- Documentation: See `documentations/` directory
- API Reference: https://hyperliquid.gitbook.io
