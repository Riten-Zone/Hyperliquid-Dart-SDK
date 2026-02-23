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

  /// Best bid/offer for a coin.
  bbo,

  /// Asset context data (funding, OI, etc.).
  assetCtxs,

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

  /// WebData3 aggregate user info.
  webData3,

  /// User notifications.
  notification,
}

/// Build the subscription message payload for the WebSocket.
Map<String, dynamic> buildSubscriptionMessage(
  SubscriptionType type, {
  String? coin,
  String? interval,
  String? user,
  int? nSigFigs,
  String? mantissa,
}) {
  switch (type) {
    case SubscriptionType.l2Book:
      assert(coin != null, 'l2Book requires coin');
      final sub = <String, dynamic>{'type': 'l2Book', 'coin': coin!};
      if (nSigFigs != null) sub['nSigFigs'] = nSigFigs;
      if (mantissa != null) sub['mantissa'] = int.tryParse(mantissa) ?? mantissa;
      return {'method': 'subscribe', 'subscription': sub};

    case SubscriptionType.candle:
      assert(coin != null && interval != null,
          'candle requires coin and interval');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'candle', 'coin': coin!, 'interval': interval!}
      };

    case SubscriptionType.trades:
      assert(coin != null, 'trades requires coin');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'trades', 'coin': coin!}
      };

    case SubscriptionType.allMids:
      return {
        'method': 'subscribe',
        'subscription': {'type': 'allMids'}
      };

    case SubscriptionType.bbo:
      assert(coin != null, 'bbo requires coin');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'bbo', 'coin': coin!}
      };

    case SubscriptionType.assetCtxs:
      return {
        'method': 'subscribe',
        'subscription': {'type': 'activeAssetCtx', 'coin': coin ?? 'BTC'}
      };

    case SubscriptionType.clearinghouseState:
      assert(user != null, 'clearinghouseState requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userEvents', 'user': user!}
      };

    case SubscriptionType.openOrders:
      assert(user != null, 'openOrders requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'orderUpdates', 'user': user!}
      };

    case SubscriptionType.userFills:
      assert(user != null, 'userFills requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userFills', 'user': user!}
      };

    case SubscriptionType.userFundings:
      assert(user != null, 'userFundings requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userFundings', 'user': user!}
      };

    case SubscriptionType.orderUpdates:
      assert(user != null, 'orderUpdates requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'orderUpdates', 'user': user!}
      };

    case SubscriptionType.activeAssetData:
      assert(user != null && coin != null,
          'activeAssetData requires user and coin');
      return {
        'method': 'subscribe',
        'subscription': {
          'type': 'activeAssetData',
          'user': user!,
          'coin': coin!
        }
      };

    case SubscriptionType.activeAssetCtx:
      assert(coin != null, 'activeAssetCtx requires coin');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'activeAssetCtx', 'coin': coin!}
      };

    case SubscriptionType.userEvents:
      assert(user != null, 'userEvents requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userEvents', 'user': user!}
      };

    case SubscriptionType.userNonFundingLedgerUpdates:
      assert(user != null, 'userNonFundingLedgerUpdates requires user');
      return {
        'method': 'subscribe',
        'subscription': {
          'type': 'userNonFundingLedgerUpdates',
          'user': user!
        }
      };

    case SubscriptionType.twapStates:
      assert(user != null, 'twapStates requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'twapStates', 'user': user!}
      };

    case SubscriptionType.userTwapSliceFills:
      assert(user != null, 'userTwapSliceFills requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userTwapSliceFills', 'user': user!}
      };

    case SubscriptionType.userTwapHistory:
      assert(user != null, 'userTwapHistory requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'userTwapHistory', 'user': user!}
      };

    case SubscriptionType.webData3:
      assert(user != null, 'webData3 requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'webData3', 'user': user!}
      };

    case SubscriptionType.notification:
      assert(user != null, 'notification requires user');
      return {
        'method': 'subscribe',
        'subscription': {'type': 'notification', 'user': user!}
      };
  }
}
