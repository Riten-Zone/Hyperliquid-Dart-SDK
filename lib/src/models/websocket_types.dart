/// Types for Hyperliquid WebSocket subscriptions.
library;

/// WebSocket subscription types.
enum SubscriptionType {
  /// L2 orderbook updates.
  l2Book,

  /// Candlestick data.
  candle,

  /// Recent trades for a coin.
  trades,

  /// All mid prices.
  allMids,

  /// Context data for all perpetual assets.
  assetCtxs,

  /// Fast mark/mid price context updates for all assets.
  fastAssetCtxs,

  /// Best bid/offer for a coin.
  bbo,

  /// User's clearinghouse state.
  clearinghouseState,

  /// User's open orders.
  openOrders,

  /// User's trade fills.
  userFills,

  /// User's funding payments.
  userFundings,

  /// Real-time order updates.
  orderUpdates,

  /// Active asset data for a user.
  activeAssetData,

  /// Active asset context for a user.
  activeAssetCtx,

  /// Active spot asset context for a spot asset.
  activeSpotAssetCtx,

  /// User spot balances/state.
  spotState,

  /// Context data for all spot assets.
  spotAssetCtxs,

  /// Clearinghouse state across all DEXs.
  allDexsClearinghouseState,

  /// Asset contexts across all DEXs.
  allDexsAssetCtxs,

  /// User events.
  userEvents,

  /// User non-funding ledger updates.
  userNonFundingLedgerUpdates,

  /// Current TWAP execution states.
  twapStates,

  /// User TWAP slice fills.
  userTwapSliceFills,

  /// User TWAP history.
  userTwapHistory,

  /// User historical orders.
  userHistoricalOrders,

  /// WebData2 aggregate user info.
  webData2,

  /// WebData3 aggregate user info.
  webData3,

  /// User notifications.
  notification,

  /// HIP-4 outcome metadata updates.
  outcomeMetaUpdates,
}

/// Build the subscription message payload for the WebSocket.
Map<String, dynamic> buildSubscriptionMessage(
  SubscriptionType type, {
  String? coin,
  String? interval,
  String? user,
  String? dex,
  int? nSigFigs,
  String? mantissa,
  bool? aggregateByTime,
  bool? ignorePortfolioMargin,
}) {
  switch (type) {
    case SubscriptionType.l2Book:
      assert(coin != null, 'l2Book requires coin');
      final sub = <String, dynamic>{'type': 'l2Book', 'coin': coin!};
      if (nSigFigs != null) sub['nSigFigs'] = nSigFigs;
      if (mantissa != null) {
        sub['mantissa'] = int.tryParse(mantissa) ?? mantissa;
      }
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.candle:
      assert(
        coin != null && interval != null,
        'candle requires coin and interval',
      );
      return {
        'method': 'subscribe',
        'subscription': {
          'type': 'candle',
          'coin': coin!,
          'interval': interval!,
        },
      };

    case SubscriptionType.trades:
      assert(coin != null, 'trades requires coin');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'trades', 'coin': coin!},
      };

    case SubscriptionType.allMids:
      final sub = <String, dynamic>{'type': 'allMids'};
      if (dex != null) sub['dex'] = dex;
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.assetCtxs:
      final sub = <String, dynamic>{'type': 'assetCtxs'};
      if (dex != null) sub['dex'] = dex;
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.fastAssetCtxs:
      return {
        'method': 'subscribe',
        'subscription': {'type': 'fastAssetCtxs'},
      };

    case SubscriptionType.bbo:
      assert(coin != null, 'bbo requires coin');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'bbo', 'coin': coin!},
      };

    case SubscriptionType.clearinghouseState:
      assert(user != null, 'clearinghouseState requires user');
      final sub = <String, dynamic>{
        'type': 'clearinghouseState',
        'user': user!,
      };
      if (dex != null) sub['dex'] = dex;
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.openOrders:
      assert(user != null, 'openOrders requires user');
      final sub = <String, dynamic>{'type': 'openOrders', 'user': user!};
      if (dex != null) sub['dex'] = dex;
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.userFills:
      assert(user != null, 'userFills requires user');
      final sub = <String, dynamic>{'type': 'userFills', 'user': user!};
      if (aggregateByTime != null) sub['aggregateByTime'] = aggregateByTime;
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.userFundings:
      assert(user != null, 'userFundings requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userFundings', 'user': user!},
      };

    case SubscriptionType.orderUpdates:
      assert(user != null, 'orderUpdates requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'orderUpdates', 'user': user!},
      };

    case SubscriptionType.activeAssetData:
      assert(
        user != null && coin != null,
        'activeAssetData requires user and coin',
      );
      return {
        'method': 'subscribe',
        'subscription': {
          'type': 'activeAssetData',
          'user': user!,
          'coin': coin!,
        },
      };

    case SubscriptionType.activeAssetCtx:
      assert(coin != null, 'activeAssetCtx requires coin');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'activeAssetCtx', 'coin': coin!},
      };

    case SubscriptionType.activeSpotAssetCtx:
      assert(coin != null, 'activeSpotAssetCtx requires coin');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'activeAssetCtx', 'coin': coin!},
      };

    case SubscriptionType.spotState:
      assert(user != null, 'spotState requires user');
      final sub = <String, dynamic>{'type': 'spotState', 'user': user!};
      if (ignorePortfolioMargin != null) {
        sub['ignorePortfolioMargin'] = ignorePortfolioMargin;
      }
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.spotAssetCtxs:
      return {
        'method': 'subscribe',
        'subscription': {'type': 'spotAssetCtxs'},
      };

    case SubscriptionType.allDexsClearinghouseState:
      assert(user != null, 'allDexsClearinghouseState requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'allDexsClearinghouseState', 'user': user!},
      };

    case SubscriptionType.allDexsAssetCtxs:
      return {
        'method': 'subscribe',
        'subscription': {'type': 'allDexsAssetCtxs'},
      };

    case SubscriptionType.userEvents:
      assert(user != null, 'userEvents requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userEvents', 'user': user!},
      };

    case SubscriptionType.userNonFundingLedgerUpdates:
      assert(user != null, 'userNonFundingLedgerUpdates requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userNonFundingLedgerUpdates', 'user': user!},
      };

    case SubscriptionType.twapStates:
      assert(user != null, 'twapStates requires user');
      final sub = <String, dynamic>{'type': 'twapStates', 'user': user!};
      if (dex != null) sub['dex'] = dex;
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.userTwapSliceFills:
      assert(user != null, 'userTwapSliceFills requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userTwapSliceFills', 'user': user!},
      };

    case SubscriptionType.userTwapHistory:
      assert(user != null, 'userTwapHistory requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userTwapHistory', 'user': user!},
      };

    case SubscriptionType.userHistoricalOrders:
      assert(user != null, 'userHistoricalOrders requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userHistoricalOrders', 'user': user!},
      };

    case SubscriptionType.webData2:
      assert(user != null, 'webData2 requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'webData2', 'user': user!},
      };

    case SubscriptionType.webData3:
      assert(user != null, 'webData3 requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'webData3', 'user': user!},
      };

    case SubscriptionType.notification:
      assert(user != null, 'notification requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'notification', 'user': user!},
      };

    case SubscriptionType.outcomeMetaUpdates:
      return {
        'method': 'subscribe',
        'subscription': {'type': 'outcomeMetaUpdates'},
      };
  }
}
