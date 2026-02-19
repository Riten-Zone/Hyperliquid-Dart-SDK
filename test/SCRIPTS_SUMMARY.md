# Test Scripts Summary

## Available Scripts

### 🚀 Master Script (Recommended)
```bash
HYPERLIQUID_PRIVATE_KEY=0x... ./test/test_and_document.sh
```
Runs all tests + extracts responses + generates complete report

### 📋 Run All Tests
```bash
HYPERLIQUID_PRIVATE_KEY=0x... ./test/run_all_tests.sh
```
Runs all 12 integration tests sequentially

### 🔍 Run Single Test
```bash
HYPERLIQUID_PRIVATE_KEY=0x... ./test/run_single_test.sh <test_name>
```
Examples:
- `./test/run_single_test.sh order_status`
- `./test/run_single_test.sh twap`
- `./test/run_single_test.sh bbo`

### 📊 Extract Responses
```bash
./test/extract_responses.sh
```
Extracts API responses from test outputs (run after tests)

## Output Files

All outputs are saved to `test/results/` directory:

| File Pattern | Description |
|--------------|-------------|
| `test_summary.json` | Machine-readable test results |
| `COMPLETE_REPORT.md` | Full test report with links |
| `*_test.txt` | Complete test output for each test |
| `*_summary.txt` | Quick summary for each test |
| `api_responses/*.md` | Extracted API responses |

## Quick Start

**Option 1: Run everything**
```bash
export HYPERLIQUID_PRIVATE_KEY=0x...
./test/test_and_document.sh
```

**Option 2: Run specific test**
```bash
export HYPERLIQUID_PRIVATE_KEY=0x...
./test/run_single_test.sh twap
```

**Option 3: Run all tests only**
```bash
export HYPERLIQUID_PRIVATE_KEY=0x...
./test/run_all_tests.sh
```

## Documentation

- **TESTING.md** - Complete testing guide
- **test/results/README.md** - Results directory documentation
- **test/results/COMPLETE_REPORT.md** - Generated after test run
- **plan/TEST_NOTES.md** - Known limitations and fixes

## Example Workflow

```bash
# 1. Set private key
export HYPERLIQUID_PRIVATE_KEY=0x1234...

# 2. Run all tests and document results
./test/test_and_document.sh

# 3. Check summary
cat test/results/test_summary.json

# 4. Review specific test
cat test/results/exchange_twap_test.txt

# 5. Check API responses
cat test/results/api_responses/exchange_twap_responses.md
```

## Files Created

- ✅ `run_all_tests.sh` - Run all tests with summaries
- ✅ `run_single_test.sh` - Run one test with verbose output
- ✅ `extract_responses.sh` - Extract API responses
- ✅ `test_and_document.sh` - Master pipeline script
- ✅ `TESTING.md` - Complete testing guide
- ✅ `test/results/README.md` - Results documentation
- ✅ `plan/TEST_NOTES.md` - Known issues and fixes
- ✅ `.gitignore` - Updated to exclude test outputs
