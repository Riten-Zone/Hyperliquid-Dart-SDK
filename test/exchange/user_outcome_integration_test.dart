@Tags(['integration'])
library;

import 'dart:io';

import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];
  final runLive =
      Platform.environment['RUN_HIP4_USER_OUTCOME_LIVE_TEST'] == 'true';

  group(
    'HIP-4 userOutcome live invalid-request integration',
    () {
      late ExchangeClient exchange;

      setUpAll(() {
        if (privateKey == null || privateKey.isEmpty) {
          fail('HYPERLIQUID_PRIVATE_KEY env var not set');
        }

        final wallet = PrivateKeyWalletAdapter(privateKey);
        exchange = ExchangeClient(wallet: wallet);
      });

      tearDownAll(() {
        exchange.close();
      });

      test(
        'signs and submits all userOutcome variants with invalid ids',
        () async {
          final calls = [
            () => exchange.splitOutcome(outcome: 0, amount: '1'),
            () => exchange.mergeOutcome(outcome: 0, amount: '1'),
            () => exchange.mergeOutcome(outcome: 0),
            () => exchange.mergeQuestion(question: 0, amount: '1'),
            () => exchange.mergeQuestion(question: 0),
            () => exchange.negateOutcome(question: 0, outcome: 0, amount: '1'),
          ];

          for (final call in calls) {
            await expectLater(call(), throwsA(isA<HyperliquidApiException>()));
          }
        },
      );
    },
    skip: runLive
        ? null
        : 'Set RUN_HIP4_USER_OUTCOME_LIVE_TEST=true to run signed live invalid-request checks.',
  );
}
