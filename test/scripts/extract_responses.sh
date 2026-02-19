#!/bin/bash

# Extract API responses from test outputs for documentation
# RUN FROM PROJECT ROOT: ./test/scripts/extract_responses.sh

echo "=========================================="
echo "Extracting API Responses from Test Results"
echo "=========================================="
echo ""

if [ ! -d "test/results" ]; then
    echo "ERROR: test/results/ directory not found"
    echo "Run ./test/scripts/run_all_tests.sh first to generate test outputs"
    exit 1
fi

mkdir -p test/results/api_responses

# Function to extract response from test output
extract_response() {
    local test_file=$1
    local test_name=$(basename "$test_file" _test.txt)
    local output_file="test/results/api_responses/${test_name}_responses.md"

    echo "Extracting: $test_name"

    cat > "$output_file" <<EOF
# API Responses - $test_name

## Test File
\`$test_file\`

## Extracted Responses

EOF

    # Extract lines between "Response:" and next print statement
    if grep -q "Response:" "$test_file" 2>/dev/null; then
        echo "### Raw Responses" >> "$output_file"
        echo '```json' >> "$output_file"
        grep -A 10 "Response:" "$test_file" | head -50 >> "$output_file" 2>/dev/null
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
    fi

    # Extract TWAP ID if present
    if grep -q "TWAP ID:" "$test_file" 2>/dev/null; then
        echo "### TWAP Order Details" >> "$output_file"
        echo '```' >> "$output_file"
        grep "TWAP ID:\|twapId" "$test_file" >> "$output_file" 2>/dev/null
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
    fi

    # Extract Order ID if present
    if grep -q "Order placed with ID:" "$test_file" 2>/dev/null; then
        echo "### Order Details" >> "$output_file"
        echo '```' >> "$output_file"
        grep "Order placed with ID:\|oid:" "$test_file" >> "$output_file" 2>/dev/null
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
    fi

    # Extract portfolio data if present
    if grep -q "Portfolio periods:" "$test_file" 2>/dev/null; then
        echo "### Portfolio Data" >> "$output_file"
        echo '```' >> "$output_file"
        grep "Portfolio periods:\|Account value points:\|PnL points:\|Total volume:" "$test_file" >> "$output_file" 2>/dev/null
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
    fi

    # Extract WebSocket updates if present
    if grep -q "update #\|received:" "$test_file" 2>/dev/null; then
        echo "### WebSocket Updates" >> "$output_file"
        echo '```' >> "$output_file"
        grep -E "update #|received:|BBO|TWAP|Notification" "$test_file" | head -20 >> "$output_file" 2>/dev/null
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
    fi

    # Add test status
    echo "### Test Status" >> "$output_file"
    if grep -q "All tests passed" "$test_file" 2>/dev/null; then
        echo "✅ **PASSED** - All assertions passed" >> "$output_file"
    elif grep -q "Some tests failed" "$test_file" 2>/dev/null; then
        echo "❌ **FAILED** - See errors below" >> "$output_file"
        echo '```' >> "$output_file"
        grep "Error:\|Exception:" "$test_file" | head -10 >> "$output_file" 2>/dev/null
        echo '```' >> "$output_file"
    else
        echo "⚠️  **Status unclear** - Check full output" >> "$output_file"
    fi

    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "*Extracted on: $(date)*" >> "$output_file"
}

# Extract from all test output files
for test_file in test/results/*_test.txt; do
    if [ -f "$test_file" ]; then
        extract_response "$test_file"
    fi
done

# Create index file
cat > test/results/api_responses/INDEX.md <<EOF
# API Response Documentation

This directory contains extracted API responses from integration test runs.

## Files

EOF

for response_file in test/results/api_responses/*_responses.md; do
    if [ -f "$response_file" ]; then
        filename=$(basename "$response_file")
        testname=$(basename "$response_file" _responses.md)
        echo "- [$testname](./$filename)" >> test/results/api_responses/INDEX.md
    fi
done

cat >> test/results/api_responses/INDEX.md <<EOF

## Usage

Each file contains:
- Test file path
- Extracted API responses (JSON)
- Key data points (IDs, counts, etc.)
- WebSocket updates (if applicable)
- Test status

## Regenerating

Run \`./test/scripts/extract_responses.sh\` after \`./test/scripts/run_all_tests.sh\` to refresh these files.

---
*Generated automatically from test outputs*
EOF

echo ""
echo "=========================================="
echo "Extraction complete!"
echo "Results saved to: test/results/api_responses/"
echo "See INDEX.md for list of files"
echo "=========================================="
