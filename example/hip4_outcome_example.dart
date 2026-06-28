import 'dart:io';

import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Example: HIP-4 outcome markets.
///
/// This demonstrates how to:
/// 1. Read live outcome metadata.
/// 2. Calculate HIP-4 outcome spot coins, token names, and asset IDs.
/// 3. Inspect spot balances for outcome token rows.
/// 4. Optionally run a tiny split/merge roundtrip.
/// 5. Optionally place a post-only outcome order.
///
/// By default this example is read-only. To run signed actions, set:
/// - HYPERLIQUID_PRIVATE_KEY=0x...
/// - RUN_HIP4_SPLIT_MERGE=true for the split/merge roundtrip
/// - RUN_HIP4_ORDER=true for the order example
void main() async {
  final info = InfoClient();

  try {
    print('=== HIP-4 outcome markets ===\n');

    final outcomeMeta = await info.outcomeMeta();
    print(
      'Loaded ${outcomeMeta.outcomes.length} outcomes and '
      '${outcomeMeta.questions.length} questions',
    );

    if (outcomeMeta.questions.isEmpty) {
      print('No HIP-4 questions are currently available.');
      return;
    }

    final question = outcomeMeta.questions.firstWhere(
      (q) => q.namedOutcomes.isNotEmpty,
    );
    final outcomeId = question.namedOutcomes.first;
    final outcome = outcomeMeta.outcomes.firstWhere(
      (o) => o.outcome == outcomeId,
    );

    print('Question: ${question.question} ${question.name}');
    print('Outcome: ${outcome.outcome} ${outcome.name}');
    print('Quote token: ${outcome.quoteToken}');
    print('Sides: ${outcome.sideSpecs.map((s) => s.name).join(' / ')}\n');

    print('Asset representations:');
    for (var side = 0; side <= 1; side++) {
      final encoding = getOutcomeEncoding(outcome: outcome.outcome, side: side);
      print('  side $side');
      print('    encoding: $encoding');
      print(
        '    spot coin: ${getOutcomeSpotCoin(outcome: outcome.outcome, side: side)}',
      );
      print(
        '    token name: ${getOutcomeTokenName(outcome: outcome.outcome, side: side)}',
      );
      print(
        '    asset id: ${getOutcomeAssetId(outcome: outcome.outcome, side: side)}',
      );
    }

    print('\nMerged-book note:');
    print(
      '  The Yes and No order books for the same outcome share liquidity. '
      'Buying Yes at price p is equivalent to selling No at price 1-p.',
    );
    print(
      '  On settlement, Yes converts to settleFraction quote tokens and '
      'No converts to 1 - settleFraction.',
    );

    final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];
    if (privateKey == null || privateKey.isEmpty) {
      print('\nSet HYPERLIQUID_PRIVATE_KEY to run signed examples.');
      return;
    }

    final wallet = PrivateKeyWalletAdapter(privateKey);
    final user = await wallet.getAddress();
    final exchange = ExchangeClient(wallet: wallet);

    try {
      final spotState = await info.spotClearinghouseState(user);
      print('\nSpot balances for $user:');
      for (final balance in spotState.balances) {
        print(
          '  ${balance.coin}: total=${balance.total}, '
          'hold=${balance.hold}, token=${balance.token ?? 'n/a'}',
        );
      }

      if (Platform.environment['RUN_HIP4_SPLIT_MERGE'] == 'true') {
        const amount = '1.0';
        print(
          '\nRunning split/merge roundtrip for $amount ${outcome.quoteToken}',
        );

        final split = await exchange.splitOutcome(
          outcome: outcome.outcome,
          amount: amount,
        );
        print(
          'splitOutcome status: ${split.status}, response=${split.response}',
        );

        await Future<void>.delayed(const Duration(seconds: 2));

        final merge = await exchange.mergeOutcome(
          outcome: outcome.outcome,
          amount: amount,
        );
        print(
          'mergeOutcome status: ${merge.status}, response=${merge.response}',
        );
      }

      if (Platform.environment['RUN_HIP4_ORDER'] == 'true') {
        final yesAsset = getOutcomeAssetId(outcome: outcome.outcome, side: 0);
        print('\nPlacing post-only Yes order on asset $yesAsset');

        final order = await exchange.placeOrder(
          orders: [
            OrderWire.limit(
              asset: yesAsset,
              isBuy: true,
              limitPx: '0.01',
              sz: '1.0',
              tif: TimeInForce.alo,
            ),
          ],
        );
        print('placeOrder status: ${order.status}, response=${order.response}');
      }
    } finally {
      exchange.close();
    }
  } finally {
    info.close();
  }
}
