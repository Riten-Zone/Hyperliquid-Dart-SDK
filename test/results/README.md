# Test Results Directory

This directory contains captured outputs from integration test runs against Hyperliquid mainnet API.

## Directory Structure

```
results/
├── README.md                           # This file
├── test_summary.json                   # Overall test suite summary
├── <category>_<test_name>_test.txt     # Full test output
├── <category>_<test_name>_summary.txt  # Key output summary
└── <test_name>_detailed.txt            # Detailed single test output
```

## File Types

### Full Test Outputs (`*_test.txt`)
Complete stdout/stderr from each test run, including:
- Test execution logs
- API responses
- Print statements
- Error messages

### Summary Files (`*_summary.txt`)
Extracted key information:
- Test status (PASSED/FAILED/SKIPPED)
- Category
- Key output lines
- Error details (if failed)

### Detailed Outputs (`*_detailed.txt`)
Verbose output from single test runs using `--reporter expanded`

### JSON Summary (`test_summary.json`)
Machine-readable summary:
```json
{
  "timestamp": "2026-02-10T12:00:00Z",
  "total": 12,
  "passed": 10,
  "failed": 1,
  "skipped": 1,
  "pass_rate": "83%",
  "categories": {
    "info": 3,
    "exchange": 3,
    "websocket": 6
  }
}
```

## Running Tests

### Run All Tests
```bash
HYPERLIQUID_PRIVATE_KEY=0x... ./run_all_tests.sh
```

### Run Single Test
```bash
HYPERLIQUID_PRIVATE_KEY=0x... ./run_single_test.sh order_status
```

## Test Categories

### Info Client Tests (3)
- **order_status** - Look up order by ID
- **portfolio** - Account value and PnL history
- **funding_history** - Historical funding rates

### Exchange Client Tests (3)
- **modify** - Order modification
- **schedule_cancel** - Dead man's switch (requires $1M volume)
- **twap** - TWAP order placement and cancellation

### WebSocket Tests (6)
- **bbo** - Best bid/offer subscription
- **web_data3** - Aggregate user data subscription
- **notification** - Notification subscription
- **twap_states** - TWAP execution states
- **twap_history** - TWAP history events
- **twap_slice_fills** - Individual TWAP fills

## Expected API Responses

### Order Placement Response (Standard)
```json
{
  "status": "ok",
  "response": {
    "type": "default",
    "data": {
      "statuses": [
        {
          "resting": {
            "oid": 317464545205
          }
        }
      ]
    }
  }
}
```

### TWAP Order Response
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

### Portfolio Response
```json
[
  ["day", {
    "accountValueHistory": [[1707580800000, "1000.50"]],
    "pnlHistory": [[1707580800000, "10.25"]],
    "vlm": "5000.00"
  }],
  ["week", {...}],
  ...
]
```

### Order Status Response
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
      ...
    },
    "status": "open",
    "statusTimestamp": 1707580800000
  }
}
```

## Known Limitations

### Schedule Cancel Test
- Requires $1M+ trading volume on mainnet
- Test will be SKIPPED on low-volume accounts
- This is expected behavior

### Insufficient Margin
- Some tests may fail if account has low balance
- Tests use minimal sizes (0.001 BTC)
- Fund account with small USDC amount for testing

## Interpreting Results

### ✓ PASSED
Test completed successfully with expected behavior

### ✗ FAILED
Test encountered unexpected error or assertion failure

### ⚠ SKIPPED
Test skipped due to known account limitations (not a code issue)

## Analyzing Failures

1. Check full output in `*_test.txt`
2. Look for error messages
3. Verify API response format matches expected
4. Check if account meets requirements

## Updating Expected Responses

When API format changes:
1. Run tests to capture new format
2. Update response parsing in SDK
3. Update expected responses in this README
4. Re-run tests to verify
