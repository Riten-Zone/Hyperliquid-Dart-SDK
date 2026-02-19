#!/bin/bash

# Convenience wrapper for test scripts
# RUN FROM PROJECT ROOT: ./test/scripts/test.sh <command>

if [ "$1" = "all" ]; then
    exec ./test/scripts/run_all_tests.sh
elif [ "$1" = "doc" ]; then
    exec ./test/scripts/test_and_document.sh
elif [ -n "$1" ]; then
    exec ./test/scripts/run_single_test.sh "$1"
else
    echo "Hyperliquid Dart SDK - Test Runner"
    echo ""
    echo "Usage:"
    echo "  ./test/scripts/test.sh all              - Run all tests"
    echo "  ./test/scripts/test.sh doc              - Run tests + generate docs"
    echo "  ./test/scripts/test.sh <test_name>      - Run single test"
    echo ""
    echo "Examples:"
    echo "  ./test/scripts/test.sh all"
    echo "  ./test/scripts/test.sh doc"
    echo "  ./test/scripts/test.sh twap"
    echo "  ./test/scripts/test.sh order_status"
    echo ""
    echo "Available tests:"
    echo "  Info: order_status, portfolio, funding_history"
    echo "  Exchange: modify, schedule_cancel, twap"
    echo "  WebSocket: bbo, web_data3, notification, twap_states, twap_history, twap_slice_fills"
    echo ""
    echo "Don't forget to set: HYPERLIQUID_PRIVATE_KEY=0x..."
fi
