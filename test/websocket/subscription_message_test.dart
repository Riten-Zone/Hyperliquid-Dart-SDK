import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('buildSubscriptionMessage', () {
    const user = '0x0000000000000000000000000000000000000000';

    Map<String, dynamic> sub(Map<String, dynamic> message) =>
        message['subscription'] as Map<String, dynamic>;

    test('builds corrected user state subscriptions', () {
      expect(
        buildSubscriptionMessage(
          SubscriptionType.clearinghouseState,
          user: user,
          dex: 'dex1',
        ),
        {
          'method': 'subscribe',
          'subscription': {
            'type': 'clearinghouseState',
            'user': user,
            'dex': 'dex1',
          },
        },
      );

      expect(
        buildSubscriptionMessage(
          SubscriptionType.openOrders,
          user: user,
          dex: 'dex1',
        ),
        {
          'method': 'subscribe',
          'subscription': {'type': 'openOrders', 'user': user, 'dex': 'dex1'},
        },
      );
    });

    test('builds market subscriptions with optional parameters', () {
      expect(buildSubscriptionMessage(SubscriptionType.allMids, dex: 'dex1'), {
        'method': 'subscribe',
        'subscription': {'type': 'allMids', 'dex': 'dex1'},
      });

      expect(
        buildSubscriptionMessage(SubscriptionType.assetCtxs, dex: 'dex1'),
        {
          'method': 'subscribe',
          'subscription': {'type': 'assetCtxs', 'dex': 'dex1'},
        },
      );

      expect(
        buildSubscriptionMessage(
          SubscriptionType.l2Book,
          coin: 'BTC',
          nSigFigs: 5,
          mantissa: '2',
        ),
        {
          'method': 'subscribe',
          'subscription': {
            'type': 'l2Book',
            'coin': 'BTC',
            'nSigFigs': 5,
            'mantissa': 2,
          },
        },
      );
    });

    test('builds user subscriptions with new supported options', () {
      expect(
        buildSubscriptionMessage(
          SubscriptionType.userFills,
          user: user,
          aggregateByTime: true,
        ),
        {
          'method': 'subscribe',
          'subscription': {
            'type': 'userFills',
            'user': user,
            'aggregateByTime': true,
          },
        },
      );

      expect(
        buildSubscriptionMessage(
          SubscriptionType.twapStates,
          user: user,
          dex: 'dex1',
        ),
        {
          'method': 'subscribe',
          'subscription': {'type': 'twapStates', 'user': user, 'dex': 'dex1'},
        },
      );

      expect(
        buildSubscriptionMessage(
          SubscriptionType.spotState,
          user: user,
          ignorePortfolioMargin: true,
        ),
        {
          'method': 'subscribe',
          'subscription': {
            'type': 'spotState',
            'user': user,
            'ignorePortfolioMargin': true,
          },
        },
      );
    });

    test('builds all current parity subscription payloads', () {
      final cases = <SubscriptionType, Map<String, dynamic>>{
        SubscriptionType.l2Book: {'type': 'l2Book', 'coin': 'BTC'},
        SubscriptionType.candle: {
          'type': 'candle',
          'coin': 'BTC',
          'interval': '1h',
        },
        SubscriptionType.trades: {'type': 'trades', 'coin': 'BTC'},
        SubscriptionType.allMids: {'type': 'allMids'},
        SubscriptionType.assetCtxs: {'type': 'assetCtxs'},
        SubscriptionType.fastAssetCtxs: {'type': 'fastAssetCtxs'},
        SubscriptionType.bbo: {'type': 'bbo', 'coin': 'BTC'},
        SubscriptionType.clearinghouseState: {
          'type': 'clearinghouseState',
          'user': user,
        },
        SubscriptionType.openOrders: {'type': 'openOrders', 'user': user},
        SubscriptionType.userFills: {'type': 'userFills', 'user': user},
        SubscriptionType.userFundings: {'type': 'userFundings', 'user': user},
        SubscriptionType.orderUpdates: {'type': 'orderUpdates', 'user': user},
        SubscriptionType.activeAssetData: {
          'type': 'activeAssetData',
          'user': user,
          'coin': 'BTC',
        },
        SubscriptionType.activeAssetCtx: {
          'type': 'activeAssetCtx',
          'coin': 'BTC',
        },
        SubscriptionType.activeSpotAssetCtx: {
          'type': 'activeAssetCtx',
          'coin': '@1',
        },
        SubscriptionType.spotState: {'type': 'spotState', 'user': user},
        SubscriptionType.spotAssetCtxs: {'type': 'spotAssetCtxs'},
        SubscriptionType.allDexsClearinghouseState: {
          'type': 'allDexsClearinghouseState',
          'user': user,
        },
        SubscriptionType.allDexsAssetCtxs: {'type': 'allDexsAssetCtxs'},
        SubscriptionType.userEvents: {'type': 'userEvents', 'user': user},
        SubscriptionType.userNonFundingLedgerUpdates: {
          'type': 'userNonFundingLedgerUpdates',
          'user': user,
        },
        SubscriptionType.twapStates: {'type': 'twapStates', 'user': user},
        SubscriptionType.userTwapSliceFills: {
          'type': 'userTwapSliceFills',
          'user': user,
        },
        SubscriptionType.userTwapHistory: {
          'type': 'userTwapHistory',
          'user': user,
        },
        SubscriptionType.userHistoricalOrders: {
          'type': 'userHistoricalOrders',
          'user': user,
        },
        SubscriptionType.webData2: {'type': 'webData2', 'user': user},
        SubscriptionType.webData3: {'type': 'webData3', 'user': user},
        SubscriptionType.notification: {'type': 'notification', 'user': user},
        SubscriptionType.outcomeMetaUpdates: {'type': 'outcomeMetaUpdates'},
      };

      for (final entry in cases.entries) {
        final message = buildSubscriptionMessage(
          entry.key,
          coin: entry.key == SubscriptionType.activeSpotAssetCtx ? '@1' : 'BTC',
          interval: '1h',
          user: user,
        );

        expect(
          sub(message),
          entry.value,
          reason: '${entry.key} should build the documented payload',
        );
      }
    });
  });
}
