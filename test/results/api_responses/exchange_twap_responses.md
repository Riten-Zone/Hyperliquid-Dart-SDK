# API Responses - exchange_twap

## Test File
`test/results/exchange_twap_test.txt`

## Extracted Responses

### Raw Responses
```json
Response: {type: twapOrder, data: {status: {running: {twapId: 1592257}}}}
TWAP ID: 1592257
Canceling TWAP order 1592257
✓ TWAP order canceled: ok
00:04 +1: TWAP integration validates TWAP duration constraints
✓ 1-minute TWAP accepted
00:05 +2: TWAP integration TWAP with randomized execution
✓ Randomized TWAP accepted
00:07 +3: TWAP integration (tearDownAll)
00:07 +3: All tests passed!
```

### TWAP Order Details
```
Response: {type: twapOrder, data: {status: {running: {twapId: 1592257}}}}
TWAP ID: 1592257
```

### Test Status
✅ **PASSED** - All assertions passed

---
*Extracted on: Wed Feb 11 00:16:00 GMT 2026*
