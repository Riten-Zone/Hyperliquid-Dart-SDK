/// High-level WebSocket client for Hyperliquid real-time data.
library;

import 'dart:async';

import '../models/info_types.dart';
import '../models/websocket_types.dart';
import '../transport/websocket_transport.dart';

/// Callback type for subscription handlers.
typedef SubscriptionHandler<T> = void Function(T data);

/// A handle returned when subscribing, used to unsubscribe later.
class SubscriptionHandle {
  final String _key;
  final StreamSubscription _subscription;
  final Map<String, dynamic> _subMessage;
  final WebSocketClient _client;

  SubscriptionHandle._(
      this._key, this._subscription, this._subMessage, this._client);

  /// Unsubscribe and stop receiving updates.
  Future<void> cancel() async {
    await _subscription.cancel();
    _client._removeSubscription(_key, _subMessage);
  }
}

/// High-level WebSocket client for subscribing to Hyperliquid real-time data.
///
/// Wraps [WebSocketTransport] with typed subscription methods and automatic
/// reconnection with re-subscription.
///
/// ```dart
/// final ws = WebSocketClient();
/// await ws.connect();
///
/// final handle = ws.subscribeL2Book('BTC', (book) {
///   print('BTC bids: ${book.bids.length}');
/// });
///
/// // Later:
/// await handle.cancel();
/// await ws.disconnect();
/// ```
class WebSocketClient {
  final WebSocketTransport _transport;
  final Map<String, Set<Map<String, dynamic>>> _activeSubscriptions = {};

  /// Stream of connection state changes.
  Stream<WsConnectionState> get stateChanges => _transport.stateChanges;

  /// Current connection state.
  WsConnectionState get state => _transport.state;

  /// Whether the WebSocket is connected.
  bool get isConnected => _transport.isConnected;

  /// Create a WebSocketClient.
  WebSocketClient({
    bool isTestnet = false,
    Duration pingInterval = const Duration(seconds: 30),
    int maxReconnectAttempts = 10,
  }) : _transport = WebSocketTransport(
          isTestnet: isTestnet,
          pingInterval: pingInterval,
          maxReconnectAttempts: maxReconnectAttempts,
        ) {
    // Re-subscribe on reconnection.
    _transport.stateChanges.listen((state) {
      if (state == WsConnectionState.connected) {
        _resubscribeAll();
      }
    });
  }

  /// Connect to the Hyperliquid WebSocket.
  Future<void> connect() => _transport.connect();

  /// Disconnect from the WebSocket.
  Future<void> disconnect() => _transport.disconnect();

  // ---------------------------------------------------------------------------
  // Typed subscription methods
  // ---------------------------------------------------------------------------

  /// Subscribe to real-time Level 2 orderbook updates.
  ///
  /// Receives full orderbook snapshots whenever the orderbook changes.
  /// Updates are sent at ~1Hz (once per block on Hyperliquid).
  ///
  /// **Parameters:**
  /// - [coin] - Asset name (e.g., 'BTC', 'ETH')
  /// - [handler] - Callback function receiving L2Book updates
  /// - [nSigFigs] - Optional significant figures for price aggregation
  /// - [mantissa] - Optional price aggregation level
  ///
  /// **Returns:** SubscriptionHandle to cancel the subscription later
  ///
  /// **Example:**
  /// ```dart
  /// final ws = WebSocketClient();
  /// await ws.connect();
  ///
  /// final handle = ws.subscribeL2Book('BTC', (book) {
  ///   final bestBid = book.levels[0][0];
  ///   final bestAsk = book.levels[1][0];
  ///   print('BTC | Bid: \$${bestBid.px} | Ask: \$${bestAsk.px}');
  /// });
  ///
  /// // Later: await handle.cancel();
  /// ```
  SubscriptionHandle subscribeL2Book(
    String coin,
    SubscriptionHandler<L2Book> handler, {
    int? nSigFigs,
    String? mantissa,
  }) {
    final msg = buildSubscriptionMessage(
      SubscriptionType.l2Book,
      coin: coin,
      nSigFigs: nSigFigs,
      mantissa: mantissa,
    );

    return _subscribe('l2Book:$coin', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'l2Book') {
        final bookData = data['data'] as Map<String, dynamic>?;
        if (bookData != null) {
          handler(L2Book.fromJson(bookData));
        }
      }
    });
  }

  /// Subscribe to real-time candlestick updates.
  ///
  /// Receives candle updates when the current candle closes or updates.
  /// Useful for live charting and technical analysis.
  ///
  /// **Parameters:**
  /// - [coin] - Asset name (e.g., 'BTC', 'ETH')
  /// - [interval] - Candle interval ('1m', '5m', '15m', '1h', '4h', '1d')
  /// - [handler] - Callback function receiving Candle updates
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeCandle('BTC', '1m', (candle) {
  ///   print('BTC 1m | O:\${candle.open} H:\${candle.high} L:\${candle.low} C:\${candle.close}');
  ///   print('  Volume: ${candle.volume}');
  /// });
  /// ```
  SubscriptionHandle subscribeCandle(
    String coin,
    String interval,
    SubscriptionHandler<Candle> handler,
  ) {
    final msg = buildSubscriptionMessage(
      SubscriptionType.candle,
      coin: coin,
      interval: interval,
    );

    return _subscribe('candle:$coin:$interval', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'candle') {
        final candleData = data['data'] as Map<String, dynamic>?;
        if (candleData != null) {
          handler(Candle.fromJson(candleData));
        }
      }
    });
  }

  /// Subscribe to real-time trade feed (market tape).
  ///
  /// Receives updates of recent trades as they execute.
  /// Shows all public trades from all users.
  ///
  /// **Parameters:**
  /// - [coin] - Asset name (e.g., 'BTC', 'ETH')
  /// - [handler] - Callback function receiving list of Trade updates
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeTrades('BTC', (trades) {
  ///   for (final trade in trades) {
  ///     final side = trade.side == 'A' ? 'BUY ' : 'SELL';
  ///     print('$side ${trade.sz} BTC @ \$${trade.px}');
  ///   }
  /// });
  /// ```
  SubscriptionHandle subscribeTrades(
    String coin,
    SubscriptionHandler<List<Trade>> handler,
  ) {
    final msg = buildSubscriptionMessage(SubscriptionType.trades, coin: coin);

    return _subscribe('trades:$coin', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'trades') {
        final tradeList = data['data'] as List<dynamic>?;
        if (tradeList != null) {
          handler(tradeList
              .map((e) => Trade.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      }
    });
  }

  /// Subscribe to best bid-offer updates for a coin.
  ///
  /// Updates are sent only when BBO changes on a block.
  SubscriptionHandle subscribeBbo(
    String coin,
    SubscriptionHandler<BboUpdate> handler,
  ) {
    final msg = buildSubscriptionMessage(SubscriptionType.bbo, coin: coin);

    return _subscribe('bbo:$coin', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'bbo') {
        final bboData = data['data'] as Map<String, dynamic>?;
        if (bboData != null) {
          handler(BboUpdate.fromJson(bboData));
        }
      }
    });
  }

  /// Subscribe to webData3 aggregate user information.
  ///
  /// Provides comprehensive account data including positions, state, and vaults.
  SubscriptionHandle subscribeWebData3(
    String user,
    SubscriptionHandler<WebData3> handler,
  ) {
    final msg = buildSubscriptionMessage(SubscriptionType.webData3, user: user);

    return _subscribe('webData3:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'webData3') {
        final webData = data['data'] as Map<String, dynamic>?;
        if (webData != null) {
          handler(WebData3.fromJson(webData));
        }
      }
    });
  }

  /// Subscribe to user notifications.
  ///
  /// Receives system messages and alerts for the user's account.
  SubscriptionHandle subscribeNotification(
    String user,
    SubscriptionHandler<NotificationMessage> handler,
  ) {
    final msg =
        buildSubscriptionMessage(SubscriptionType.notification, user: user);

    return _subscribe('notification:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'notification') {
        final notifData = data['data'] as Map<String, dynamic>?;
        if (notifData != null) {
          handler(NotificationMessage.fromJson(notifData));
        }
      }
    });
  }

  /// Subscribe to current TWAP execution states for a user.
  ///
  /// Returns real-time updates on all active TWAP orders.
  SubscriptionHandle subscribeTwapStates(
    String user,
    SubscriptionHandler<List<TwapState>> handler,
  ) {
    final msg =
        buildSubscriptionMessage(SubscriptionType.twapStates, user: user);

    return _subscribe('twapStates:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'twapStates') {
        final rawData = data['data'];

        // Handle both List (updates) and Map (initial snapshot) formats
        if (rawData is List) {
          handler(
            rawData
                .map((e) => TwapState.fromJson(e as Map<String, dynamic>))
                .toList(),
          );
        } else if (rawData is Map) {
          // Initial snapshot may be empty or contain data
          // If it's an empty map, pass empty list
          handler([]);
        }
      }
    });
  }

  /// Subscribe to user's TWAP execution history.
  ///
  /// Returns historical TWAP order events (started, finished, canceled).
  SubscriptionHandle subscribeUserTwapHistory(
    String user,
    SubscriptionHandler<List<TwapHistoryEvent>> handler,
  ) {
    final msg =
        buildSubscriptionMessage(SubscriptionType.userTwapHistory, user: user);

    return _subscribe('userTwapHistory:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'userTwapHistory') {
        final rawData = data['data'];

        // Handle both List (updates) and Map (initial snapshot) formats
        if (rawData is List) {
          handler(
            rawData
                .map((e) => TwapHistoryEvent.fromJson(e as Map<String, dynamic>))
                .toList(),
          );
        } else if (rawData is Map) {
          // Initial snapshot may be empty or contain data
          handler([]);
        }
      }
    });
  }

  /// Subscribe to individual TWAP slice fills for a user.
  ///
  /// Returns real-time notifications when TWAP child orders fill.
  /// Note: TWAP fills have hash="0x000...000".
  SubscriptionHandle subscribeUserTwapSliceFills(
    String user,
    SubscriptionHandler<List<TwapSliceFill>> handler,
  ) {
    final msg = buildSubscriptionMessage(SubscriptionType.userTwapSliceFills,
        user: user);

    return _subscribe('userTwapSliceFills:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'userTwapSliceFills') {
        final rawData = data['data'];

        // Handle both List (updates) and Map (initial snapshot) formats
        if (rawData is List) {
          handler(
            rawData
                .map((e) => TwapSliceFill.fromJson(e as Map<String, dynamic>))
                .toList(),
          );
        } else if (rawData is Map) {
          // Initial snapshot may be empty or contain data
          handler([]);
        }
      }
    });
  }

  /// Subscribe to real-time mid prices for all assets.
  ///
  /// Receives updates for all perpetual asset mid prices in a single stream.
  /// Most efficient way to track multiple asset prices.
  ///
  /// **Parameters:**
  /// - [handler] - Callback function receiving map of coin names to mid prices
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeAllMids((mids) {
  ///   print('BTC: \$${mids['BTC']} | ETH: \$${mids['ETH']} | SOL: \$${mids['SOL']}');
  /// });
  /// ```
  SubscriptionHandle subscribeAllMids(
    SubscriptionHandler<Map<String, String>> handler,
  ) {
    final msg = buildSubscriptionMessage(SubscriptionType.allMids);

    return _subscribe('allMids', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'allMids') {
        final mids = data['data'] as Map<String, dynamic>?;
        if (mids != null) {
          final midMap = mids['mids'] as Map<String, dynamic>?;
          if (midMap != null) {
            handler(midMap.map((k, v) => MapEntry(k, v as String)));
          }
        }
      }
    });
  }

  /// Subscribe to real-time user trade fills.
  ///
  /// Receives immediate notifications when your orders execute.
  /// Shows all fills with prices, sizes, fees, and timestamps.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  /// - [handler] - Callback function receiving list of UserFill updates
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeUserFills('0x...', (fills) {
  ///   for (final fill in fills) {
  ///     print('Filled ${fill.sz} ${fill.coin} @ \$${fill.px}');
  ///     print('  Fee: \$${fill.feeUsd}');
  ///   }
  /// });
  /// ```
  SubscriptionHandle subscribeUserFills(
    String user,
    SubscriptionHandler<List<UserFill>> handler,
  ) {
    final msg =
        buildSubscriptionMessage(SubscriptionType.userFills, user: user);

    return _subscribe('userFills:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'userFills') {
        final fills = data['data'] as List<dynamic>?;
        if (fills != null) {
          handler(fills
              .map((e) => UserFill.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      }
    });
  }

  /// Subscribe to real-time order status updates.
  ///
  /// Receives updates when orders are placed, filled, cancelled, or rejected.
  /// Essential for tracking order lifecycle in real-time.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  /// - [handler] - Callback function receiving list of order update events
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeOrderUpdates('0x...', (updates) {
  ///   for (final update in updates) {
  ///     final status = update['status'] as String?;
  ///     print('Order update: $status');
  ///   }
  /// });
  /// ```
  SubscriptionHandle subscribeOrderUpdates(
    String user,
    SubscriptionHandler<List<Map<String, dynamic>>> handler,
  ) {
    final msg =
        buildSubscriptionMessage(SubscriptionType.orderUpdates, user: user);

    return _subscribe('orderUpdates:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'orderUpdates') {
        final updates = data['data'] as List<dynamic>?;
        if (updates != null) {
          handler(updates.cast<Map<String, dynamic>>());
        }
      }
    });
  }

  /// Subscribe to user account event stream.
  ///
  /// Receives notifications for account-level changes including
  /// clearinghouse state updates, leverage changes, and margin adjustments.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  /// - [handler] - Callback function receiving event data maps
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeUserEvents('0x...', (event) {
  ///   print('User event: ${event['channel']}');
  ///   print('Data: ${event['data']}');
  /// });
  /// ```
  SubscriptionHandle subscribeUserEvents(
    String user,
    SubscriptionHandler<Map<String, dynamic>> handler,
  ) {
    final msg =
        buildSubscriptionMessage(SubscriptionType.userEvents, user: user);

    return _subscribe('userEvents:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'userEvents') {
        handler(data);
      }
    });
  }

  /// Subscribe to real-time funding payment updates.
  ///
  /// Receives funding payment notifications (paid or received) every hour.
  /// Funding payments occur in perpetual futures contracts.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  /// - [handler] - Callback function receiving funding event data
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeUserFundings('0x...', (funding) {
  ///   final data = funding['data'] as Map?;
  ///   if (data != null) {
  ///     print('Funding payment: ${data['delta']}');
  ///   }
  /// });
  /// ```
  SubscriptionHandle subscribeUserFundings(
    String user,
    SubscriptionHandler<Map<String, dynamic>> handler,
  ) {
    final msg =
        buildSubscriptionMessage(SubscriptionType.userFundings, user: user);

    return _subscribe('userFundings:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'userFundings') {
        handler(data);
      }
    });
  }

  /// Subscribe to user non-funding ledger updates (deposits, withdrawals, transfers).
  ///
  /// Returns real-time ledger events excluding funding payments.
  /// Each update contains timestamp, transaction hash, and delta details.
  ///
  /// Common delta types:
  /// - deposit - USDC deposits
  /// - withdraw - USDC withdrawals
  /// - accountClassTransfer - USDC between spot and perp
  /// - internalTransfer - USDC to other users
  /// - subAccountTransfer - Sub-account transfers
  /// - spotTransfer - Spot token transfers
  /// - liquidation - Liquidation events
  ///
  /// Example:
  /// ```dart
  /// final handle = ws.subscribeUserNonFundingLedgerUpdates(
  ///   '0x...',
  ///   (updates) {
  ///     for (final update in updates) {
  ///       print('${update.delta.type}: ${update.delta.usdc} USDC');
  ///     }
  ///   },
  /// );
  /// ```
  SubscriptionHandle subscribeUserNonFundingLedgerUpdates(
    String user,
    SubscriptionHandler<List<LedgerUpdate>> handler,
  ) {
    final msg = buildSubscriptionMessage(
      SubscriptionType.userNonFundingLedgerUpdates,
      user: user,
    );

    return _subscribe('userNonFundingLedgerUpdates:$user', msg, (data) {
      final channel = data['channel'] as String?;
      if (channel == 'userNonFundingLedgerUpdates') {
        final dataMap = data['data'] as Map<String, dynamic>?;
        if (dataMap != null) {
          final updates = dataMap['nonFundingLedgerUpdates'] as List<dynamic>?;
          if (updates != null) {
            handler(updates
                .map((e) => LedgerUpdate.fromJson(e as Map<String, dynamic>))
                .toList());
          }
        }
      }
    });
  }

  /// Generic raw subscription for any subscription type.
  ///
  /// Use this for subscription types that don't have a typed method yet,
  /// or for advanced use cases requiring custom subscription messages.
  ///
  /// **Parameters:**
  /// - [key] - Unique subscription key for tracking
  /// - [subscriptionMessage] - Raw subscription message map
  /// - [handler] - Callback function receiving raw message data
  ///
  /// **Example:**
  /// ```dart
  /// final handle = ws.subscribeRaw(
  ///   'customSub',
  ///   {'method': 'subscribe', 'subscription': {'type': 'customType'}},
  ///   (data) {
  ///     print('Raw data: $data');
  ///   },
  /// );
  /// ```
  SubscriptionHandle subscribeRaw(
    String key,
    Map<String, dynamic> subscriptionMessage,
    SubscriptionHandler<Map<String, dynamic>> handler,
  ) {
    return _subscribe(key, subscriptionMessage, handler);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  SubscriptionHandle _subscribe(
    String key,
    Map<String, dynamic> subMessage,
    void Function(Map<String, dynamic>) handler,
  ) {
    // Track the subscription for reconnection.
    _activeSubscriptions.putIfAbsent(key, () => {});
    _activeSubscriptions[key]!.add(subMessage);

    // Send the subscription message if connected.
    if (_transport.isConnected) {
      _transport.subscribe(subMessage);
    }

    // Listen to the message stream and filter.
    final subscription = _transport.messages.listen(handler);

    return SubscriptionHandle._(key, subscription, subMessage, this);
  }

  void _removeSubscription(String key, Map<String, dynamic> subMessage) {
    final subs = _activeSubscriptions[key];
    if (subs != null) {
      subs.remove(subMessage);
      if (subs.isEmpty) {
        _activeSubscriptions.remove(key);
      }
    }

    // Send unsubscribe if still connected.
    if (_transport.isConnected) {
      try {
        _transport.unsubscribe(subMessage);
      } catch (_) {
        // Connection may have closed.
      }
    }
  }

  void _resubscribeAll() {
    for (final subs in _activeSubscriptions.values) {
      for (final msg in subs) {
        try {
          _transport.subscribe(msg);
        } catch (_) {
          // Will retry on next reconnect.
        }
      }
    }
  }

  /// Dispose of all resources.
  Future<void> dispose() async {
    _activeSubscriptions.clear();
    await _transport.dispose();
  }
}
