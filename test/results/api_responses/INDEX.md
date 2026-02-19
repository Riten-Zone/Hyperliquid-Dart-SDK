# API Response Documentation

This directory contains extracted API responses from integration test runs.

## Files

- [exchange_modify](./exchange_modify_responses.md)
- [exchange_schedule_cancel](./exchange_schedule_cancel_responses.md)
- [exchange_twap](./exchange_twap_responses.md)
- [info_funding_history](./info_funding_history_responses.md)
- [info_order_status](./info_order_status_responses.md)
- [info_portfolio](./info_portfolio_responses.md)
- [websocket_bbo](./websocket_bbo_responses.md)
- [websocket_notification](./websocket_notification_responses.md)
- [websocket_twap_history](./websocket_twap_history_responses.md)
- [websocket_twap_slice_fills](./websocket_twap_slice_fills_responses.md)
- [websocket_twap_states](./websocket_twap_states_responses.md)
- [websocket_web_data3](./websocket_web_data3_responses.md)

## Usage

Each file contains:
- Test file path
- Extracted API responses (JSON)
- Key data points (IDs, counts, etc.)
- WebSocket updates (if applicable)
- Test status

## Regenerating

Run `./test/scripts/extract_responses.sh` after `./test/scripts/run_all_tests.sh` to refresh these files.

---
*Generated automatically from test outputs*
