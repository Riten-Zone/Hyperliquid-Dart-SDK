#!/bin/bash

# Master script: Run all tests and generate comprehensive documentation
# RUN FROM PROJECT ROOT: ./test/scripts/test_and_document.sh

set -e

echo "=========================================="
echo "Hyperliquid Dart SDK"
echo "Complete Test & Documentation Pipeline"
echo "=========================================="
echo ""

# Check for private key
if [ -z "$HYPERLIQUID_PRIVATE_KEY" ]; then
    echo "ERROR: HYPERLIQUID_PRIVATE_KEY environment variable not set"
    echo ""
    echo "Usage: HYPERLIQUID_PRIVATE_KEY=0x... ./test/scripts/test_and_document.sh"
    exit 1
fi

# Step 1: Run all integration tests
echo "Step 1/3: Running integration tests..."
echo "----------------------------------------"
./test/scripts/run_all_tests.sh
echo ""

# Step 2: Extract API responses
echo "Step 2/3: Extracting API responses..."
echo "----------------------------------------"
./test/scripts/extract_responses.sh
echo ""

# Step 3: Generate summary report
echo "Step 3/3: Generating summary report..."
echo "----------------------------------------"

cat > test/results/COMPLETE_REPORT.md <<EOF
# Hyperliquid Dart SDK - Complete Test Report

**Generated:** $(date)

## Test Summary

EOF

# Add JSON summary if it exists
if [ -f "test/results/test_summary.json" ]; then
    echo "### Results" >> test/results/COMPLETE_REPORT.md
    echo '```json' >> test/results/COMPLETE_REPORT.md
    cat test/results/test_summary.json >> test/results/COMPLETE_REPORT.md
    echo '```' >> test/results/COMPLETE_REPORT.md
    echo "" >> test/results/COMPLETE_REPORT.md
fi

cat >> test/results/COMPLETE_REPORT.md <<EOF

## Test Categories

### Info Client Tests
- [Order Status](./api_responses/info_order_status_responses.md)
- [Portfolio](./api_responses/info_portfolio_responses.md)
- [Funding History](./api_responses/info_funding_history_responses.md)

### Exchange Client Tests
- [Modify Orders](./api_responses/exchange_modify_responses.md)
- [Schedule Cancel](./api_responses/exchange_schedule_cancel_responses.md)
- [TWAP Orders](./api_responses/exchange_twap_responses.md)

### WebSocket Tests
- [BBO Subscription](./api_responses/websocket_bbo_responses.md)
- [WebData3 Subscription](./api_responses/websocket_web_data3_responses.md)
- [Notification Subscription](./api_responses/websocket_notification_responses.md)
- [TWAP States Subscription](./api_responses/websocket_twap_states_responses.md)
- [TWAP History Subscription](./api_responses/websocket_twap_history_responses.md)
- [TWAP Slice Fills Subscription](./api_responses/websocket_twap_slice_fills_responses.md)

## Directory Structure

\`\`\`
test/results/
├── COMPLETE_REPORT.md              # This file
├── test_summary.json               # Machine-readable summary
├── *_test.txt                      # Full test outputs
├── *_summary.txt                   # Quick summaries
└── api_responses/
    ├── INDEX.md                    # Response index
    └── *_responses.md              # Extracted API responses
\`\`\`

## Files Generated

EOF

# List all generated files
echo "### Test Outputs" >> test/results/COMPLETE_REPORT.md
for file in test/results/*_test.txt; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "- \`$filename\`" >> test/results/COMPLETE_REPORT.md
    fi
done

echo "" >> test/results/COMPLETE_REPORT.md
echo "### API Response Documentation" >> test/results/COMPLETE_REPORT.md
for file in test/results/api_responses/*_responses.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "- [\`$filename\`](./api_responses/$filename)" >> test/results/COMPLETE_REPORT.md
    fi
done

cat >> test/results/COMPLETE_REPORT.md <<EOF

## Next Steps

1. **Review Failed Tests**
   - Check \`*_summary.txt\` files for errors
   - See full output in \`*_test.txt\` files

2. **Verify API Responses**
   - Review extracted responses in \`api_responses/\`
   - Compare with expected formats in TESTING.md

3. **Update Documentation**
   - If API format changed, update model classes
   - Update expected responses in TESTING.md
   - Document breaking changes in CHANGELOG.md

4. **Re-run Failed Tests**
   - For specific test: \`./test/scripts/run_single_test.sh <test_name>\`
   - For all tests: \`./test/scripts/run_all_tests.sh\`

## Known Limitations

- **Schedule Cancel**: Requires \$1M+ trading volume
- **WebSocket Tests**: May timeout on inactive accounts
- **Order Tests**: May skip if order fills immediately

See [test/TESTING.md](../TESTING.md) for details.

---
*This report was generated automatically by test_and_document.sh*
EOF

echo "Complete report generated: test/results/COMPLETE_REPORT.md"
echo ""

# Display summary
echo "=========================================="
echo "PIPELINE COMPLETE"
echo "=========================================="
echo ""
echo "Generated Documentation:"
echo "  📊 Test Summary:     test/results/test_summary.json"
echo "  📝 Complete Report:  test/results/COMPLETE_REPORT.md"
echo "  🔍 API Responses:    test/results/api_responses/"
echo "  📋 Full Outputs:     test/results/*_test.txt"
echo ""
echo "Quick Links:"
echo "  • View report:       cat test/results/COMPLETE_REPORT.md"
echo "  • View summary:      cat test/results/test_summary.json"
echo "  • Browse responses:  ls test/results/api_responses/"
echo ""
echo "=========================================="
