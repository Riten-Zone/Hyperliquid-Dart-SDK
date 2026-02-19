#!/bin/bash

# Hyperliquid Dart SDK - Comprehensive Integration Test Runner
# This script runs each integration test individually and captures outputs
# RUN FROM PROJECT ROOT: ./test/scripts/run_all_tests.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Hyperliquid Dart SDK - Test Suite Runner"
echo "=========================================="
echo ""

# Check for private key
if [ -z "$HYPERLIQUID_PRIVATE_KEY" ]; then
    echo -e "${RED}ERROR: HYPERLIQUID_PRIVATE_KEY environment variable not set${NC}"
    echo "Usage: HYPERLIQUID_PRIVATE_KEY=0x... ./test/scripts/run_all_tests.sh"
    exit 1
fi

# Create results directory
mkdir -p test/results
rm -f test/results/*.txt test/results/*.json

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test categories
declare -a INFO_TESTS=(
    "test/info/order_status_test.dart"
    "test/info/portfolio_test.dart"
    "test/info/funding_history_test.dart"
    "test/info/spot_meta_test.dart"
    "test/info/sub_accounts_test.dart"
    "test/info/perp_dexs_test.dart"
    "test/info/user_fees_test.dart"
    "test/info/ledger_updates_test.dart"
)

declare -a EXCHANGE_TESTS=(
    "test/exchange/modify_test.dart"
    "test/exchange/schedule_cancel_test.dart"
    "test/exchange/twap_test.dart"
    "test/exchange/usd_operations_test.dart"
)

declare -a WEBSOCKET_TESTS=(
    "test/websocket/bbo_test.dart"
    "test/websocket/web_data3_test.dart"
    "test/websocket/notification_test.dart"
    "test/websocket/twap_states_test.dart"
    "test/websocket/twap_history_test.dart"
    "test/websocket/twap_slice_fills_test.dart"
    "test/websocket/ledger_updates_test.dart"
)

# Function to run a single test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .dart)
    local category=$(dirname "$test_file" | xargs basename)
    local output_file="test/results/${category}_${test_name}.txt"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo "----------------------------------------"
    echo -e "${YELLOW}Running: $test_name ($category)${NC}"
    echo "----------------------------------------"

    # Run test and capture output
    if dart test "$test_file" --tags integration > "$output_file" 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))

        # Extract key information
        echo "Test: $test_name" > "test/results/${category}_${test_name}_summary.txt"
        echo "Status: PASSED" >> "test/results/${category}_${test_name}_summary.txt"
        echo "Category: $category" >> "test/results/${category}_${test_name}_summary.txt"
        echo "" >> "test/results/${category}_${test_name}_summary.txt"
        echo "Key Output:" >> "test/results/${category}_${test_name}_summary.txt"
        grep -E "(✓|TWAP|Order|Portfolio|Funding|Notification|BBO|WebData3)" "$output_file" | head -20 >> "test/results/${category}_${test_name}_summary.txt" 2>/dev/null || echo "No key output found" >> "test/results/${category}_${test_name}_summary.txt"
    else
        # Check if it's a known limitation
        if grep -q "volume requirement\|insufficient margin\|Insufficient margin" "$output_file"; then
            echo -e "${YELLOW}⚠ SKIPPED (Known limitation)${NC}"
            SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
            echo "Test: $test_name" > "test/results/${category}_${test_name}_summary.txt"
            echo "Status: SKIPPED (Known limitation)" >> "test/results/${category}_${test_name}_summary.txt"
        else
            echo -e "${RED}✗ FAILED${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo "Test: $test_name" > "test/results/${category}_${test_name}_summary.txt"
            echo "Status: FAILED" >> "test/results/${category}_${test_name}_summary.txt"
        fi
        echo "Category: $category" >> "test/results/${category}_${test_name}_summary.txt"
        echo "" >> "test/results/${category}_${test_name}_summary.txt"
        echo "Error Output:" >> "test/results/${category}_${test_name}_summary.txt"
        tail -30 "$output_file" >> "test/results/${category}_${test_name}_summary.txt"
    fi

    echo ""
}

# Run all tests by category
echo -e "${YELLOW}=== INFO CLIENT TESTS ===${NC}"
for test in "${INFO_TESTS[@]}"; do
    run_test "$test"
done

echo -e "${YELLOW}=== EXCHANGE CLIENT TESTS ===${NC}"
for test in "${EXCHANGE_TESTS[@]}"; do
    run_test "$test"
done

echo -e "${YELLOW}=== WEBSOCKET TESTS ===${NC}"
for test in "${WEBSOCKET_TESTS[@]}"; do
    run_test "$test"
done

# Generate summary report
echo "=========================================="
echo "TEST SUITE SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests:   $TOTAL_TESTS"
echo -e "${GREEN}Passed:        $PASSED_TESTS${NC}"
echo -e "${RED}Failed:        $FAILED_TESTS${NC}"
echo -e "${YELLOW}Skipped:       $SKIPPED_TESTS${NC}"
echo ""

# Calculate pass rate
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$((100 * PASSED_TESTS / TOTAL_TESTS))
    echo "Pass Rate: ${PASS_RATE}%"
fi

# Generate JSON summary
cat > test/results/test_summary.json <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "total": $TOTAL_TESTS,
  "passed": $PASSED_TESTS,
  "failed": $FAILED_TESTS,
  "skipped": $SKIPPED_TESTS,
  "pass_rate": "$PASS_RATE%",
  "categories": {
    "info": ${#INFO_TESTS[@]},
    "exchange": ${#EXCHANGE_TESTS[@]},
    "websocket": ${#WEBSOCKET_TESTS[@]}
  }
}
EOF

echo ""
echo "=========================================="
echo "Results saved to test/results/ directory"
echo "  - Full outputs: test/results/*_test.txt"
echo "  - Summaries: test/results/*_summary.txt"
echo "  - JSON report: test/results/test_summary.json"
echo "=========================================="

# Exit with error if any tests failed (excluding skipped)
if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
fi
