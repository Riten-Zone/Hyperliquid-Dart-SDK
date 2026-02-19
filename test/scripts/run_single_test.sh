#!/bin/bash

# Run a single integration test and capture detailed output
# RUN FROM PROJECT ROOT: ./test/scripts/run_single_test.sh <test_name>

set -e

if [ -z "$1" ]; then
    echo "Usage: HYPERLIQUID_PRIVATE_KEY=0x... ./test/scripts/run_single_test.sh <test_name>"
    echo ""
    echo "Available tests:"
    echo "  Info Client:"
    echo "    - order_status"
    echo "    - portfolio"
    echo "    - funding_history"
    echo "    - spot_meta"
    echo "    - sub_accounts"
    echo "    - perp_dexs"
    echo "    - user_fees"
    echo "    - ledger_updates"
    echo ""
    echo "  Exchange Client:"
    echo "    - modify"
    echo "    - schedule_cancel"
    echo "    - twap"
    echo "    - usd_operations"
    echo ""
    echo "  WebSocket:"
    echo "    - bbo"
    echo "    - web_data3"
    echo "    - notification"
    echo "    - twap_states"
    echo "    - twap_history"
    echo "    - twap_slice_fills"
    echo "    - ledger_updates"
    echo ""
    echo "Example: ./test/scripts/run_single_test.sh order_status"
    exit 1
fi

if [ -z "$HYPERLIQUID_PRIVATE_KEY" ]; then
    echo "ERROR: HYPERLIQUID_PRIVATE_KEY environment variable not set"
    exit 1
fi

TEST_NAME=$1
mkdir -p test/results

# Map test name to file path
case $TEST_NAME in
    order_status)
        TEST_FILE="test/info/order_status_test.dart"
        ;;
    portfolio)
        TEST_FILE="test/info/portfolio_test.dart"
        ;;
    funding_history)
        TEST_FILE="test/info/funding_history_test.dart"
        ;;
    spot_meta)
        TEST_FILE="test/info/spot_meta_test.dart"
        ;;
    sub_accounts)
        TEST_FILE="test/info/sub_accounts_test.dart"
        ;;
    perp_dexs)
        TEST_FILE="test/info/perp_dexs_test.dart"
        ;;
    user_fees)
        TEST_FILE="test/info/user_fees_test.dart"
        ;;
    ledger_updates)
        TEST_FILE="test/info/ledger_updates_test.dart"
        ;;
    modify)
        TEST_FILE="test/exchange/modify_test.dart"
        ;;
    schedule_cancel)
        TEST_FILE="test/exchange/schedule_cancel_test.dart"
        ;;
    twap)
        TEST_FILE="test/exchange/twap_test.dart"
        ;;
    usd_operations)
        TEST_FILE="test/exchange/usd_operations_test.dart"
        ;;
    bbo)
        TEST_FILE="test/websocket/bbo_test.dart"
        ;;
    web_data3)
        TEST_FILE="test/websocket/web_data3_test.dart"
        ;;
    notification)
        TEST_FILE="test/websocket/notification_test.dart"
        ;;
    twap_states)
        TEST_FILE="test/websocket/twap_states_test.dart"
        ;;
    twap_history)
        TEST_FILE="test/websocket/twap_history_test.dart"
        ;;
    twap_slice_fills)
        TEST_FILE="test/websocket/twap_slice_fills_test.dart"
        ;;
    ledger_updates)
        TEST_FILE="test/websocket/ledger_updates_test.dart"
        ;;
    *)
        echo "Unknown test: $TEST_NAME"
        exit 1
        ;;
esac

OUTPUT_FILE="test/results/${TEST_NAME}_detailed.txt"

echo "=========================================="
echo "Running: $TEST_NAME"
echo "File: $TEST_FILE"
echo "Output: $OUTPUT_FILE"
echo "=========================================="
echo ""

# Run test with verbose output
dart test "$TEST_FILE" --tags integration --reporter expanded 2>&1 | tee "$OUTPUT_FILE"

echo ""
echo "=========================================="
echo "Test output saved to: $OUTPUT_FILE"
echo "=========================================="
