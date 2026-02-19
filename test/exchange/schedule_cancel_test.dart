@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('scheduleCancel integration', () {
    late ExchangeClient exchange;

    setUpAll(() {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }
      final wallet = PrivateKeyWalletAdapter(privateKey);
      exchange = ExchangeClient(wallet: wallet, isTestnet: false);
    });

    tearDownAll() {
      exchange.close();
    }

    test('sets schedule cancel time', () async {
      // Set cancel time 10 minutes in future
      final futureTime = DateTime.now()
          .add(Duration(minutes: 10))
          .millisecondsSinceEpoch;

      print('Setting schedule cancel time to ${DateTime.fromMillisecondsSinceEpoch(futureTime)}');
      final result = await exchange.scheduleCancel(time: futureTime);

      expect(result.isOk, isTrue);
      expect(result.response, isA<Map>());

      final data = (result.response as Map)['data'];
      print('✓ Schedule cancel response: $data');
    });

    test('updates existing schedule', () async {
      // First schedule at 15 minutes
      final time1 = DateTime.now()
          .add(Duration(minutes: 15))
          .millisecondsSinceEpoch;

      print('Setting initial schedule to ${DateTime.fromMillisecondsSinceEpoch(time1)}');
      final result1 = await exchange.scheduleCancel(time: time1);
      expect(result1.isOk, isTrue);
      print('✓ Initial schedule set');

      // Update schedule to 20 minutes
      final time2 = DateTime.now()
          .add(Duration(minutes: 20))
          .millisecondsSinceEpoch;

      print('Updating schedule to ${DateTime.fromMillisecondsSinceEpoch(time2)}');
      final result2 = await exchange.scheduleCancel(time: time2);
      expect(result2.isOk, isTrue);
      print('✓ Schedule updated successfully');
    });

    test('schedule cancel with different time intervals', () async {
      // Test with 5 minutes
      final time5min = DateTime.now()
          .add(Duration(minutes: 5))
          .millisecondsSinceEpoch;

      final result5 = await exchange.scheduleCancel(time: time5min);
      expect(result5.isOk, isTrue);
      print('✓ 5-minute schedule set');

      // Update to 30 minutes
      final time30min = DateTime.now()
          .add(Duration(minutes: 30))
          .millisecondsSinceEpoch;

      final result30 = await exchange.scheduleCancel(time: time30min);
      expect(result30.isOk, isTrue);
      print('✓ 30-minute schedule set');

      // Update to 1 hour
      final time1hour = DateTime.now()
          .add(Duration(hours: 1))
          .millisecondsSinceEpoch;

      final result60 = await exchange.scheduleCancel(time: time1hour);
      expect(result60.isOk, isTrue);
      print('✓ 1-hour schedule set');
    });
  });
}
