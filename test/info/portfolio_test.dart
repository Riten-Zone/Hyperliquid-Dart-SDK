@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('portfolio integration', () {
    late InfoClient info;
    late String address;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }
      final wallet = PrivateKeyWalletAdapter(privateKey);
      address = await wallet.getAddress();
      info = InfoClient(isTestnet: false);
    });

    tearDownAll(() {
      info.close();
    });

    test('fetches portfolio data with all time periods', () async {
      final portfolio = await info.portfolio(address);

      // Check all expected periods exist
      expect(portfolio.periods.containsKey('day'), isTrue);
      expect(portfolio.periods.containsKey('week'), isTrue);
      expect(portfolio.periods.containsKey('month'), isTrue);
      expect(portfolio.periods.containsKey('allTime'), isTrue);

      // Perp-specific periods
      expect(portfolio.periods.containsKey('perpDay'), isTrue);
      expect(portfolio.periods.containsKey('perpWeek'), isTrue);
      expect(portfolio.periods.containsKey('perpMonth'), isTrue);
      expect(portfolio.periods.containsKey('perpAllTime'), isTrue);

      print('Portfolio periods: ${portfolio.periods.keys.toList()}');
    });

    test('portfolio period data structure is valid', () async {
      final portfolio = await info.portfolio(address);
      final dayPeriod = portfolio.periods['day']!;

      // Check data types
      expect(dayPeriod.accountValueHistory, isA<List<List<dynamic>>>());
      expect(dayPeriod.pnlHistory, isA<List<List<dynamic>>>());
      expect(dayPeriod.vlm, isA<String>());

      print('Day period - Account value points: ${dayPeriod.accountValueHistory.length}');
      print('Day period - PnL points: ${dayPeriod.pnlHistory.length}');
      print('Day period - Total volume: ${dayPeriod.vlm}');

      // If history exists, check structure
      if (dayPeriod.accountValueHistory.isNotEmpty) {
        final firstPoint = dayPeriod.accountValueHistory[0];
        expect(firstPoint.length, 2);
        expect(firstPoint[0], isA<int>()); // timestamp
        expect(firstPoint[1], isA<String>()); // value

        print('Sample account value point: timestamp=${firstPoint[0]}, value=${firstPoint[1]}');
      }

      if (dayPeriod.pnlHistory.isNotEmpty) {
        final firstPnl = dayPeriod.pnlHistory[0];
        expect(firstPnl.length, 2);
        expect(firstPnl[0], isA<int>()); // timestamp
        expect(firstPnl[1], isA<String>()); // pnl

        print('Sample PnL point: timestamp=${firstPnl[0]}, pnl=${firstPnl[1]}');
      }
    });

    test('all time period contains complete data', () async {
      final portfolio = await info.portfolio(address);
      final allTimePeriod = portfolio.periods['allTime']!;

      expect(allTimePeriod.accountValueHistory, isA<List<List<dynamic>>>());
      expect(allTimePeriod.pnlHistory, isA<List<List<dynamic>>>());
      expect(allTimePeriod.vlm, isA<String>());

      print('All-time - Account value points: ${allTimePeriod.accountValueHistory.length}');
      print('All-time - PnL points: ${allTimePeriod.pnlHistory.length}');
      print('All-time - Total volume: ${allTimePeriod.vlm}');
    });
  });
}
