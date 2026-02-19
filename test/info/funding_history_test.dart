@Tags(['integration'])
library;

import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('fundingHistory integration', () {
    late InfoClient info;

    setUpAll(() {
      info = InfoClient(isTestnet: false);
    });

    tearDownAll() {
      info.close();
    }

    test('fetches funding history for BTC', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final dayAgo = now - (24 * 60 * 60 * 1000);

      final history = await info.fundingHistory(
        coin: 'BTC',
        startTime: dayAgo,
        endTime: now,
      );

      expect(history, isA<List<FundingHistoryEntry>>());
      print('Fetched ${history.length} funding records for BTC in last 24h');

      if (history.isNotEmpty) {
        final entry = history.first;
        expect(entry.coin, 'BTC');
        expect(entry.fundingRate, isNotEmpty);
        expect(entry.premium, isNotEmpty);
        expect(entry.time, greaterThan(dayAgo));
        expect(entry.time, lessThanOrEqualTo(now));

        print('First entry:');
        print('  Time: ${DateTime.fromMillisecondsSinceEpoch(entry.time)}');
        print('  Funding rate: ${entry.fundingRate}');
        print('  Premium: ${entry.premium}');
      } else {
        print('No funding events in the last 24 hours');
      }
    });

    test('fetches funding history for ETH', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final weekAgo = now - (7 * 24 * 60 * 60 * 1000);

      final history = await info.fundingHistory(
        coin: 'ETH',
        startTime: weekAgo,
        endTime: now,
      );

      expect(history, isA<List<FundingHistoryEntry>>());
      print('Fetched ${history.length} funding records for ETH in last 7 days');

      if (history.isNotEmpty) {
        final lastEntry = history.last;
        expect(lastEntry.coin, 'ETH');

        print('Last entry:');
        print('  Time: ${DateTime.fromMillisecondsSinceEpoch(lastEntry.time)}');
        print('  Funding rate: ${lastEntry.fundingRate}');
        print('  Premium: ${lastEntry.premium}');
      }
    });

    test('handles empty time range', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneHourAgo = now - (60 * 60 * 1000);

      final history = await info.fundingHistory(
        coin: 'SOL',
        startTime: oneHourAgo,
        endTime: now,
      );

      // May be empty if no funding events in 1 hour
      expect(history, isA<List<FundingHistoryEntry>>());
      print('Funding records for SOL in last 1h: ${history.length}');
    });

    test('funding history entries have valid timestamps', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final threeDaysAgo = now - (3 * 24 * 60 * 60 * 1000);

      final history = await info.fundingHistory(
        coin: 'BTC',
        startTime: threeDaysAgo,
        endTime: now,
      );

      if (history.isNotEmpty) {
        // Check that timestamps are within range and sorted
        for (final entry in history) {
          expect(entry.time, greaterThanOrEqualTo(threeDaysAgo));
          expect(entry.time, lessThanOrEqualTo(now));
        }

        // Check that funding entries are chronologically ordered
        for (int i = 1; i < history.length; i++) {
          expect(history[i].time, greaterThanOrEqualTo(history[i - 1].time));
        }

        print('✓ All ${history.length} entries have valid, sorted timestamps');
      }
    });
  });
}
