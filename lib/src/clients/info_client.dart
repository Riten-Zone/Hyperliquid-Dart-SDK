/// Read-only client for the Hyperliquid Info API.
library;

import '../models/info_types.dart';
import '../transport/http_transport.dart';

/// Client for querying Hyperliquid's Info endpoint (read-only).
///
/// All methods are unauthenticated — no wallet or signing required.
///
/// ```dart
/// final info = InfoClient();
/// final meta = await info.metaAndAssetCtxs();
/// final candles = await info.candleSnapshot(coin: 'BTC', interval: '1h');
/// info.close();
/// ```
class InfoClient {
  final HttpTransport _transport;

  /// Create an InfoClient.
  ///
  /// Pass [isTestnet] to use the testnet API.
  /// Pass a custom [transport] for testing.
  InfoClient({bool isTestnet = false, HttpTransport? transport})
      : _transport = transport ?? HttpTransport(isTestnet: isTestnet);

  /// Fetch OHLCV candle snapshot for a specific time range.
  ///
  /// Returns historical candle data for technical analysis and charting.
  /// Each candle contains open, high, low, close prices and volume.
  ///
  /// **Parameters:**
  /// - [coin] - Asset name (e.g., 'BTC', 'ETH')
  /// - [interval] - Candle interval ('1m', '5m', '15m', '1h', '4h', '1d')
  /// - [startTime] - Start time in **milliseconds** since Unix epoch
  /// - [endTime] - End time in **milliseconds** since Unix epoch
  ///
  /// **Returns:** Up to 500 candles per request (protocol limit)
  ///
  /// **Example:**
  /// ```dart
  /// final now = DateTime.now().millisecondsSinceEpoch;
  /// final hourAgo = now - (60 * 60 * 1000);
  /// final candles = await info.candleSnapshot(
  ///   coin: 'BTC',
  ///   interval: '1m',
  ///   startTime: hourAgo,
  ///   endTime: now,
  /// );
  /// for (final c in candles) {
  ///   print('${c.startTime}: O:\${c.open} H:\${c.high} L:\${c.low} C:\${c.close}');
  /// }
  /// ```
  ///
  /// **Note:** For ranges larger than 500 candles, use [candleSnapshotPaginated]
  Future<List<Candle>> candleSnapshot({
    required String coin,
    required String interval,
    required int startTime,
    required int endTime,
  }) async {
    final data = await _transport.postInfo({
      'type': 'candleSnapshot',
      'req': {
        'coin': coin,
        'interval': interval,
        'startTime': startTime,
        'endTime': endTime,
      },
    });

    if (data is! List) return [];
    return data
        .map((e) => Candle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch candle data with automatic pagination for large time ranges.
  ///
  /// Handles time ranges larger than 500 candles by making multiple API calls
  /// and combining the results. Useful for fetching days or weeks of minute data.
  ///
  /// **Parameters:**
  /// - [coin] - Asset name (e.g., 'BTC', 'ETH')
  /// - [interval] - Candle interval ('1m', '5m', '15m', '1h', '4h', '1d')
  /// - [startTime] - Start time in **milliseconds** since Unix epoch
  /// - [endTime] - End time in **milliseconds** since Unix epoch
  /// - [maxPages] - Max API calls to make (default 10 = ~5000 candles max)
  ///
  /// **Returns:** All candles in the range, sorted by startTime
  ///
  /// **Example:**
  /// ```dart
  /// final now = DateTime.now().millisecondsSinceEpoch;
  /// final weekAgo = now - (7 * 24 * 60 * 60 * 1000);
  /// final candles = await info.candleSnapshotPaginated(
  ///   coin: 'BTC',
  ///   interval: '1h',
  ///   startTime: weekAgo,
  ///   endTime: now,
  ///   maxPages: 5, // Fetch up to 2500 candles
  /// );
  /// print('Fetched ${candles.length} hourly candles');
  /// ```
  Future<List<Candle>> candleSnapshotPaginated({
    required String coin,
    required String interval,
    required int startTime,
    required int endTime,
    int maxPages = 10,
  }) async {
    final allCandles = <Candle>[];
    final seenTimestamps = <int>{};
    var currentStart = startTime;

    for (var page = 0; page < maxPages; page++) {
      final candles = await candleSnapshot(
        coin: coin,
        interval: interval,
        startTime: currentStart,
        endTime: endTime,
      );

      if (candles.isEmpty) break;

      for (final c in candles) {
        if (seenTimestamps.add(c.startTime)) {
          allCandles.add(c);
        }
      }

      // Less than 500 means we've fetched everything.
      if (candles.length < 500) break;

      // Advance start time past the last candle.
      final lastCandle = candles.last;
      currentStart = lastCandle.endTime + 1;

      if (currentStart >= endTime) break;
    }

    allCandles.sort((a, b) => a.startTime.compareTo(b.startTime));
    return allCandles;
  }

  /// Fetch asset metadata.
  ///
  /// [dex] - Optional HIP-3 DEX name (e.g., "xyz"). If provided, returns
  /// metadata for that specific builder-deployed DEX (including collateralToken).
  /// If omitted, returns metadata for regular Hyperliquid perpetuals.
  ///
  /// Returns [Meta] object containing:
  /// - `universe`: List of asset metadata
  /// - `collateralToken`: Spot token ID used as collateral (HIP-3 only, null for regular perps)
  ///
  /// Example:
  /// ```dart
  /// // Regular perpetuals
  /// final regularMeta = await info.meta();
  /// print('Assets: ${regularMeta.universe.length}');
  ///
  /// // HIP-3 DEX (includes collateralToken)
  /// final xyzMeta = await info.meta(dex: 'xyz');
  /// print('Collateral token: ${xyzMeta.collateralToken}'); // e.g., 0 for USDC
  /// ```
  Future<Meta> meta({String? dex}) async {
    final payload = <String, dynamic>{'type': 'meta'};
    if (dex != null && dex.isNotEmpty) {
      payload['dex'] = dex;
    }

    final data = await _transport.postInfo(payload);

    if (data is Map) {
      return Meta.fromJson(data as Map<String, dynamic>);
    }

    // Fallback for unexpected format
    return const Meta(universe: [], collateralToken: null);
  }

  /// Fetch perpetuals metadata and asset contexts.
  ///
  /// Returns the universe of assets and their live context data
  /// (funding, OI, mark price, etc.).
  ///
  /// [dex] - Optional HIP-3 DEX name (e.g., "xyz"). If provided, returns
  /// metadata and contexts for that specific builder-deployed DEX. If omitted,
  /// returns data for regular Hyperliquid perpetuals.
  ///
  /// Example:
  /// ```dart
  /// // Regular perpetuals
  /// final regular = await info.metaAndAssetCtxs();
  ///
  /// // HIP-3 DEX
  /// final xyz = await info.metaAndAssetCtxs(dex: 'xyz');
  /// ```
  Future<MetaAndAssetCtxs> metaAndAssetCtxs({String? dex}) async {
    final payload = <String, dynamic>{'type': 'metaAndAssetCtxs'};
    if (dex != null && dex.isNotEmpty) {
      payload['dex'] = dex;
    }

    final data = await _transport.postInfo(payload);

    // Response format: [{ universe: [...], ... }, [assetCtx, ...]]
    if (data is List && data.length >= 2) {
      final first = data[0] as Map<String, dynamic>;
      final universeList = (first['universe'] as List<dynamic>?) ?? [];
      final ctxList = data[1] as List<dynamic>? ?? [];

      return MetaAndAssetCtxs(
        universe: universeList
            .map((e) => AssetMetadata.fromJson(e as Map<String, dynamic>))
            .toList(),
        assetCtxs: ctxList
            .map((e) => AssetContext.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    // Fallback for unexpected format.
    return const MetaAndAssetCtxs(universe: [], assetCtxs: []);
  }

  /// Fetch the asset universe names (convenience method).
  ///
  /// Returns a simple list of asset names like ['BTC', 'ETH', 'SOL', ...].
  /// Useful for populating dropdowns or autocomplete fields.
  ///
  /// **Example:**
  /// ```dart
  /// final assets = await info.universeNames();
  /// print('Available assets: ${assets.join(', ')}');
  /// ```
  Future<List<String>> universeNames() async {
    final meta = await metaAndAssetCtxs();
    return meta.universe.map((a) => a.name).toList();
  }

  /// Fetch Level 2 orderbook snapshot for a coin.
  ///
  /// Returns the full orderbook with bid and ask levels, including
  /// prices, sizes, and number of orders at each level.
  ///
  /// **Parameters:**
  /// - [coin] - Asset name (e.g., 'BTC', 'ETH')
  /// - [nSigFigs] - Significant figures for price aggregation (optional)
  /// - [mantissa] - Price aggregation level as string (optional)
  ///
  /// **Example:**
  /// ```dart
  /// final book = await info.l2Book(coin: 'BTC');
  /// print('Best bid: \$${book.levels[0][0].px} (${book.levels[0][0].sz} BTC)');
  /// print('Best ask: \$${book.levels[1][0].px} (${book.levels[1][0].sz} BTC)');
  /// print('Spread: ${(double.parse(book.levels[1][0].px) - double.parse(book.levels[0][0].px)).toStringAsFixed(2)}');
  /// ```
  Future<L2Book> l2Book({
    required String coin,
    int? nSigFigs,
    String? mantissa,
  }) async {
    final payload = <String, dynamic>{'type': 'l2Book', 'coin': coin};
    if (nSigFigs != null) payload['nSigFigs'] = nSigFigs;
    if (mantissa != null) payload['mantissa'] = mantissa;

    final data = await _transport.postInfo(payload);
    return L2Book.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch current mid prices for all perpetual assets.
  ///
  /// Returns a map of asset names to their mid prices (average of best bid and ask).
  /// This is the most efficient way to get current prices for all assets in one call.
  ///
  /// **Returns:** Map where keys are asset names ('BTC', 'ETH', etc.) and values are price strings
  ///
  /// **Example:**
  /// ```dart
  /// final prices = await info.allMids();
  /// print('BTC: \$${prices['BTC']}');
  /// print('ETH: \$${prices['ETH']}');
  /// print('SOL: \$${prices['SOL']}');
  ///
  /// // Calculate total portfolio value
  /// final btcPrice = double.parse(prices['BTC']!);
  /// final portfolioValue = btcPrice * 0.5; // 0.5 BTC
  /// ```
  Future<Map<String, String>> allMids() async {
    final data = await _transport.postInfo({'type': 'allMids'});
    if (data is Map) {
      return data.map((k, v) => MapEntry(k as String, v as String));
    }
    return {};
  }

  /// Fetch a user's perpetuals clearinghouse state.
  ///
  /// Returns complete account information including balance, margin usage,
  /// open positions, and leverage settings.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address (e.g., '0x...')
  ///
  /// **Example:**
  /// ```dart
  /// final state = await info.clearinghouseState('0x...');
  /// print('Account Value: \$${state.marginSummary.accountValue}');
  /// print('Total Raw USD: \$${state.marginSummary.totalRawUsd}');
  /// print('Positions: ${state.assetPositions.length}');
  ///
  /// for (final pos in state.assetPositions) {
  ///   print('${pos.position.coin}: ${pos.position.szi} @ \$${pos.position.entryPx}');
  ///   print('  Unrealized PnL: \$${pos.position.unrealizedPnl}');
  /// }
  /// ```
  Future<ClearinghouseState> clearinghouseState(String user) async {
    final data = await _transport.postInfo({
      'type': 'clearinghouseState',
      'user': user.toLowerCase(),
    });
    return ClearinghouseState.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch a user's open limit orders.
  ///
  /// Returns all currently active limit orders (does not include trigger/stop orders).
  /// For trigger orders, use [frontendOpenOrders] instead.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  ///
  /// **Example:**
  /// ```dart
  /// final orders = await info.openOrders('0x...');
  /// print('You have ${orders.length} open orders');
  ///
  /// for (final order in orders) {
  ///   print('${order.coin} ${order.side} ${order.sz} @ \$${order.limitPx}');
  ///   print('  Order ID: ${order.oid}');
  /// }
  /// ```
  Future<List<OpenOrder>> openOrders(String user) async {
    final data = await _transport.postInfo({
      'type': 'openOrders',
      'user': user.toLowerCase(),
    });
    if (data is! List) return [];
    return data
        .map((e) => OpenOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a user's open orders including trigger/stop orders.
  ///
  /// Unlike [openOrders], this includes trigger orders (stop-loss, take-profit).
  /// Use this for displaying a complete view of all pending orders.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  ///
  /// **Example:**
  /// ```dart
  /// final allOrders = await info.frontendOpenOrders('0x...');
  /// final limitOrders = allOrders.where((o) => o.orderType == 'Limit');
  /// final triggerOrders = allOrders.where((o) => o.orderType.contains('Trigger'));
  ///
  /// print('Limit orders: ${limitOrders.length}');
  /// print('Trigger orders: ${triggerOrders.length}');
  /// ```
  Future<List<OpenOrder>> frontendOpenOrders(String user) async {
    final data = await _transport.postInfo({
      'type': 'frontendOpenOrders',
      'user': user.toLowerCase(),
    });
    if (data is! List) return [];
    return data
        .map((e) => OpenOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a user's historical orders (completed, cancelled, failed).
  ///
  /// Returns order history with status, fill information, and timestamps.
  /// Useful for building order history tables and analyzing trading patterns.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  ///
  /// **Returns:** Up to 2000 most recent orders (protocol limit)
  ///
  /// **Example:**
  /// ```dart
  /// final history = await info.historicalOrders('0x...');
  /// final filled = history.where((o) => o.status == 'filled');
  /// final cancelled = history.where((o) => o.status == 'cancelled');
  ///
  /// print('Total orders: ${history.length}');
  /// print('Filled: ${filled.length}');
  /// print('Cancelled: ${cancelled.length}');
  /// ```
  Future<List<HistoricalOrder>> historicalOrders(String user) async {
    final data = await _transport.postInfo({
      'type': 'historicalOrders',
      'user': user.toLowerCase(),
    });
    if (data is! List) return [];
    return data
        .map((e) => HistoricalOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a user's recent trade fills (executions).
  ///
  /// Returns executed trades with prices, sizes, fees, and timestamps.
  /// Shows both maker and taker fills.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  ///
  /// **Example:**
  /// ```dart
  /// final fills = await info.userFills('0x...');
  /// for (final fill in fills) {
  ///   final side = fill.side == 'A' ? 'BUY' : 'SELL';
  ///   print('$side ${fill.sz} ${fill.coin} @ \$${fill.px}');
  ///   print('  Fee: \$${fill.feeUsd} | Time: ${DateTime.fromMillisecondsSinceEpoch(fill.time)}');
  /// }
  /// ```
  Future<List<UserFill>> userFills(String user) async {
    final data = await _transport.postInfo({
      'type': 'userFills',
      'user': user.toLowerCase(),
    });
    if (data is! List) return [];
    return data
        .map((e) => UserFill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a user's trade fills filtered by time range.
  ///
  /// More flexible than [userFills] - allows querying specific time periods.
  /// Useful for generating daily/weekly/monthly trade reports.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  /// - [startTime] - Start time in **milliseconds** since Unix epoch
  /// - [endTime] - End time in **milliseconds** (optional, defaults to now)
  ///
  /// **Example:**
  /// ```dart
  /// final now = DateTime.now().millisecondsSinceEpoch;
  /// final dayAgo = now - (24 * 60 * 60 * 1000);
  /// final todayFills = await info.userFillsByTime(
  ///   user: '0x...',
  ///   startTime: dayAgo,
  ///   endTime: now,
  /// );
  ///
  /// final totalVolume = todayFills.fold<double>(
  ///   0, (sum, fill) => sum + double.parse(fill.sz) * double.parse(fill.px)
  /// );
  /// print('24h volume: \$${totalVolume.toStringAsFixed(2)}');
  /// ```
  Future<List<UserFill>> userFillsByTime({
    required String user,
    required int startTime,
    int? endTime,
  }) async {
    final payload = <String, dynamic>{
      'type': 'userFillsByTime',
      'user': user.toLowerCase(),
      'startTime': startTime,
    };
    if (endTime != null) payload['endTime'] = endTime;

    final data = await _transport.postInfo(payload);
    if (data is! List) return [];
    return data
        .map((e) => UserFill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a user's funding payment history.
  ///
  /// Returns funding payments (positive = received, negative = paid).
  /// Funding occurs every hour in perpetual futures.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  /// - [startTime] - Start time in **milliseconds** since Unix epoch
  /// - [endTime] - End time in **milliseconds** (optional, defaults to now)
  ///
  /// **Example:**
  /// ```dart
  /// final now = DateTime.now().millisecondsSinceEpoch;
  /// final weekAgo = now - (7 * 24 * 60 * 60 * 1000);
  /// final funding = await info.userFunding(
  ///   user: '0x...',
  ///   startTime: weekAgo,
  ///   endTime: now,
  /// );
  ///
  /// final totalFunding = funding.fold<double>(
  ///   0, (sum, f) => sum + double.parse(f.delta)
  /// );
  /// print('7-day funding: \$${totalFunding.toStringAsFixed(4)}');
  /// ```
  Future<List<UserFunding>> userFunding({
    required String user,
    required int startTime,
    int? endTime,
  }) async {
    final payload = <String, dynamic>{
      'type': 'userFunding',
      'user': user.toLowerCase(),
      'startTime': startTime,
    };
    if (endTime != null) payload['endTime'] = endTime;

    final data = await _transport.postInfo(payload);
    if (data is! List) return [];
    return data
        .map((e) => UserFunding.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a user's spot token balances.
  ///
  /// Returns all spot token holdings with amounts and current values.
  /// Separate from perpetual account state.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  ///
  /// **Example:**
  /// ```dart
  /// final spotState = await info.spotClearinghouseState('0x...');
  /// for (final balance in spotState.balances) {
  ///   final token = balance.token;
  ///   final amount = balance.total;
  ///   print('$token: $amount');
  /// }
  /// ```
  Future<SpotClearinghouseState> spotClearinghouseState(String user) async {
    final data = await _transport.postInfo({
      'type': 'spotClearinghouseState',
      'user': user.toLowerCase(),
    });
    return SpotClearinghouseState.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch spot market metadata.
  ///
  /// Returns all spot universes and tokens available for trading.
  /// Includes token decimals, contract addresses, and canonical flags.
  ///
  /// Example:
  /// ```dart
  /// final spotMeta = await info.spotMeta();
  /// for (final token in spotMeta.tokens) {
  ///   print('${token.name}: ${token.tokenId}');
  /// }
  /// ```
  Future<SpotMeta> spotMeta() async {
    final data = await _transport.postInfo({'type': 'spotMeta'});
    return SpotMeta.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch spot metadata combined with asset contexts.
  ///
  /// Returns both token metadata and current market data (prices, volumes)
  /// in a single API call. More efficient than calling spotMeta() and
  /// separate price queries.
  ///
  /// Example:
  /// ```dart
  /// final combined = await info.spotMetaAndAssetCtxs();
  /// for (final ctx in combined.assetCtxs) {
  ///   print('${ctx.coin}: \$${ctx.markPx}');
  /// }
  /// ```
  Future<SpotMetaAndAssetCtxs> spotMetaAndAssetCtxs() async {
    final data = await _transport.postInfo({'type': 'spotMetaAndAssetCtxs'});
    return SpotMetaAndAssetCtxs.fromJson(data as List<dynamic>);
  }

  /// Get the asset ID for placing spot orders.
  ///
  /// Spot orders use `10000 + index` as the asset ID, where index is the
  /// position in the spot universe. This helper fetches spot metadata and
  /// returns the correct asset ID for the given token name.
  ///
  /// [tokenName] is the spot pair name (e.g., 'PURR/USDC', 'HYPE/USDC')
  ///
  /// Returns null if the token is not found.
  ///
  /// Example:
  /// ```dart
  /// final purrAssetId = await info.getSpotAssetId('PURR/USDC');
  /// // Returns 10000 for the first spot pair
  ///
  /// // Use it to place a spot order
  /// await exchange.placeOrder(
  ///   orders: [OrderWire.limit(
  ///     asset: purrAssetId!,
  ///     isBuy: true,
  ///     limitPx: '0.0001',
  ///     sz: '1000',
  ///   )],
  /// );
  /// ```
  Future<int?> getSpotAssetId(String tokenName) async {
    final meta = await spotMeta();
    final index = meta.universe.indexWhere((u) => u.name == tokenName);
    if (index == -1) return null;
    return 10000 + index;
  }

  /// Fetch detailed information for a specific token.
  ///
  /// Returns comprehensive token data including supply, prices, deployer info,
  /// and emission schedules.
  ///
  /// [tokenId] must be in 0x format (34 characters: "0x" + 32 hex chars)
  ///
  /// Example:
  /// ```dart
  /// final details = await info.tokenDetails('0x...');
  /// print('${details.name}: ${details.circulatingSupply}/${details.maxSupply}');
  /// print('Mark Price: \$${details.markPx}');
  /// ```
  Future<TokenDetails> tokenDetails(String tokenId) async {
    final data = await _transport.postInfo({
      'type': 'tokenDetails',
      'tokenId': tokenId,
    });
    return TokenDetails.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch a user's sub-accounts.
  ///
  /// Returns all sub-accounts for the given master account address,
  /// including their balances, positions, and margin states.
  ///
  /// [user] must be the master account address in 42-character hex format
  ///
  /// Example:
  /// ```dart
  /// final subs = await info.subAccounts('0x...');
  /// for (final sub in subs) {
  ///   print('${sub.name}: ${sub.clearinghouseState.marginSummary.accountValue}');
  /// }
  /// ```
  Future<List<SubAccount>> subAccounts(String user) async {
    final data = await _transport.postInfo({
      'type': 'subAccounts',
      'user': user.toLowerCase(),
    });
    if (data is! List) return [];
    return data
        .map((e) => SubAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get list of all HIP-3 builder-deployed perpetual DEXs.
  ///
  /// Returns an array of DEXs with their names, deployers, and configurations.
  ///
  /// Example:
  /// ```dart
  /// final dexs = await info.perpDexs();
  /// for (final dex in dexs) {
  ///   print('${dex.name} (${dex.fullName}) - Deployer: ${dex.deployer}');
  /// }
  /// ```
  Future<List<PerpDex>> perpDexs() async {
    final data = await _transport.postInfo({'type': 'perpDexs'});
    if (data is! List) return [];
    return data
        .where((e) => e != null) // Filter out null elements
        .map((e) => PerpDex.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get user's fee structure and trading costs.
  ///
  /// Returns detailed fee information including:
  /// - Current taker/maker rates (perp and spot)
  /// - Daily trading volume history
  /// - Active referral and staking discounts
  /// - Fee trial status (if applicable)
  ///
  /// Example:
  /// ```dart
  /// final fees = await info.userFees('0x...');
  /// print('Taker fee: ${fees.userCrossRate}');
  /// print('Maker rebate: ${fees.userAddRate}');
  /// if (fees.activeReferralDiscount != null) {
  ///   print('Referral discount: ${fees.activeReferralDiscount}');
  /// }
  /// ```
  Future<UserFees> userFees(String user) async {
    final data = await _transport.postInfo({
      'type': 'userFees',
      'user': user.toLowerCase(),
    });

    if (data is Map<String, dynamic>) {
      return UserFees.fromJson(data);
    }

    // Fallback for unexpected format
    return const UserFees(
      dailyUserVlm: [],
      userCrossRate: '0',
      userAddRate: '0',
      userSpotCrossRate: '0',
      userSpotAddRate: '0',
    );
  }

  /// Get user's non-funding ledger updates (deposits, withdrawals, transfers).
  ///
  /// Returns an array of ledger events within the specified time range.
  /// Excludes funding payments (use userFunding() for those).
  ///
  /// [startTime] and [endTime] are in milliseconds (Hyperliquid convention).
  /// If [endTime] is null, defaults to current time.
  ///
  /// Ledger update types include:
  /// - deposit: USDC deposits from bridge
  /// - withdraw: USDC withdrawals to bridge
  /// - accountClassTransfer: USDC transfers between spot and perp
  /// - internalTransfer: USDC transfers to other users
  /// - subAccountTransfer: Transfers to/from sub-accounts
  /// - spotTransfer: Spot token transfers
  /// - liquidation: Liquidation events
  ///
  /// Example:
  /// ```dart
  /// final now = DateTime.now().millisecondsSinceEpoch;
  /// final dayAgo = now - 86400000;
  /// final updates = await info.userNonFundingLedgerUpdates(
  ///   user: '0x...',
  ///   startTime: dayAgo,
  ///   endTime: now,
  /// );
  /// for (final update in updates) {
  ///   print('${update.delta.type}: ${update.delta.usdc ?? update.delta.amount}');
  /// }
  /// ```
  Future<List<LedgerUpdate>> userNonFundingLedgerUpdates({
    required String user,
    required int startTime,
    int? endTime,
  }) async {
    final payload = <String, dynamic>{
      'type': 'userNonFundingLedgerUpdates',
      'user': user.toLowerCase(),
      'startTime': startTime,
    };

    if (endTime != null) {
      payload['endTime'] = endTime;
    }

    final data = await _transport.postInfo(payload);

    if (data is! List) return [];
    return data
        .map((e) => LedgerUpdate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch recent trades for a coin (market tape).
  ///
  /// Returns the most recent public trades from all users.
  /// Useful for showing real-time market activity and price discovery.
  ///
  /// **Parameters:**
  /// - [coin] - Asset name (e.g., 'BTC', 'ETH')
  ///
  /// **Example:**
  /// ```dart
  /// final trades = await info.recentTrades('BTC');
  /// print('Last ${trades.length} BTC trades:');
  /// for (final trade in trades.take(10)) {
  ///   final side = trade.side == 'A' ? 'BUY ' : 'SELL';
  ///   print('$side ${trade.sz} @ \$${trade.px} | Time: ${DateTime.fromMillisecondsSinceEpoch(trade.time)}');
  /// }
  /// ```
  Future<List<Trade>> recentTrades(String coin) async {
    final data = await _transport.postInfo({
      'type': 'recentTrades',
      'coin': coin,
    });
    if (data is! List) return [];
    return data
        .map((e) => Trade.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get the max approved builder fee for a user and HIP-3 builder.
  ///
  /// Returns the maximum fee rate the user has authorized this builder to charge
  /// for HIP-3 DEX trades. Returns null if no approval exists.
  ///
  /// **Parameters:**
  /// - [user] - User's 42-character hex address
  /// - [builder] - Builder's 42-character hex address
  ///
  /// **Returns:** Fee rate as string (e.g., '0.0005' = 0.05%), or null if not approved
  ///
  /// **Example:**
  /// ```dart
  /// final maxFee = await info.maxBuilderFee(
  ///   user: '0x...',
  ///   builder: '0x...',
  /// );
  /// if (maxFee != null) {
  ///   final feePercent = double.parse(maxFee) * 100;
  ///   print('Max builder fee: ${feePercent.toStringAsFixed(4)}%');
  /// } else {
  ///   print('No builder fee approved');
  /// }
  /// ```
  Future<String?> maxBuilderFee({
    required String user,
    required String builder,
  }) async {
    final data = await _transport.postInfo({
      'type': 'maxBuilderFee',
      'user': user.toLowerCase(),
      'builder': builder.toLowerCase(),
    });
    if (data is String) return data;
    if (data is Map) return data['maxFeeRate'] as String?;
    return null;
  }

  /// Fetch order status by order ID.
  ///
  /// Returns status of a specific order including fill information and metadata.
  /// Returns status "unknownOid" if order not found.
  ///
  /// Example:
  /// ```dart
  /// final status = await info.orderStatus(user: '0x...', oid: 123456789);
  /// if (status.status == 'order') {
  ///   print('Order status: ${status.order!.status}');
  /// }
  /// ```
  Future<OrderStatusResponse> orderStatus({
    required String user,
    required int oid,
  }) async {
    final data = await _transport.postInfo({
      'type': 'orderStatus',
      'user': user.toLowerCase(),
      'oid': oid,
    });
    return OrderStatusResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch user's portfolio with historical account value and PnL.
  ///
  /// Returns portfolio data across different time periods (day, week, month, allTime).
  /// Each period contains account value history, PnL history, and total volume.
  ///
  /// Example:
  /// ```dart
  /// final portfolio = await info.portfolio('0x...');
  /// final dayPeriod = portfolio.periods['day']!;
  /// print('Account value history: ${dayPeriod.accountValueHistory}');
  /// print('Total volume: ${dayPeriod.vlm}');
  /// ```
  Future<PortfolioResponse> portfolio(String user) async {
    final data = await _transport.postInfo({
      'type': 'portfolio',
      'user': user.toLowerCase(),
    });
    return PortfolioResponse.fromJson(data as List<dynamic>);
  }

  /// Fetch historical funding rates for a coin.
  ///
  /// Returns funding rate data points within the specified time range.
  /// Times are in milliseconds since Unix epoch.
  ///
  /// Example:
  /// ```dart
  /// final now = DateTime.now().millisecondsSinceEpoch;
  /// final dayAgo = now - (24 * 60 * 60 * 1000);
  /// final history = await info.fundingHistory(
  ///   coin: 'BTC',
  ///   startTime: dayAgo,
  ///   endTime: now,
  /// );
  /// ```
  Future<List<FundingHistoryEntry>> fundingHistory({
    required String coin,
    required int startTime,
    int? endTime,
  }) async {
    final payload = <String, dynamic>{
      'type': 'fundingHistory',
      'coin': coin,
      'startTime': startTime,
    };
    if (endTime != null) payload['endTime'] = endTime;

    final data = await _transport.postInfo(payload);
    if (data is! List) return [];
    return data
        .map((e) => FundingHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================================================================
  // VAULT OPERATIONS
  // ===========================================================================

  /// Fetch detailed information about a specific vault.
  ///
  /// [vaultAddress] is the vault's 42-character hex address.
  /// [user] is optional - if provided, includes user-specific follower state.
  ///
  /// Returns complete vault information including portfolio performance,
  /// followers, commission rates, and relationship hierarchy.
  ///
  /// Example:
  /// ```dart
  /// final details = await info.vaultDetails(
  ///   vaultAddress: '0x...',
  /// );
  /// print('Vault: ${details.name}');
  /// print('Leader: ${details.leader}');
  /// print('APR: ${details.apr}');
  /// print('Followers: ${details.followers.length}');
  /// ```
  Future<VaultDetails> vaultDetails({
    required String vaultAddress,
    String? user,
  }) async {
    final payload = <String, dynamic>{
      'type': 'vaultDetails',
      'vaultAddress': vaultAddress.toLowerCase(),
    };

    if (user != null && user.isNotEmpty) {
      payload['user'] = user.toLowerCase();
    }

    final data = await _transport.postInfo(payload);
    return VaultDetails.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch summaries for all vaults on Hyperliquid.
  ///
  /// Returns an array of vault summaries including name, TVL, leader,
  /// and creation timestamp. Useful for vault discovery.
  ///
  /// Note: API returns empty array in some cases - this is a known issue.
  /// If this returns empty, use [leadingVaults] for specific vault leaders.
  ///
  /// Example:
  /// ```dart
  /// final summaries = await info.vaultSummaries();
  /// if (summaries.isEmpty) {
  ///   print('No vaults found (known API issue)');
  /// } else {
  ///   for (final vault in summaries) {
  ///     print('${vault.name}: TVL \$${vault.tvl}');
  ///   }
  /// }
  /// ```
  Future<List<VaultSummary>> vaultSummaries() async {
    final data = await _transport.postInfo({'type': 'vaultSummaries'});

    if (data is! List) return [];
    return data
        .map((e) => VaultSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all vaults managed by a specific vault leader.
  ///
  /// [user] is the vault leader's 42-character hex address.
  ///
  /// Returns detailed information about all vaults led by this user,
  /// including performance metrics and commission rates.
  ///
  /// Example:
  /// ```dart
  /// final vaults = await info.leadingVaults('0x...');
  /// for (final vault in vaults) {
  ///   print('${vault.name}');
  ///   print('  TVL: \$${vault.tvl}');
  ///   print('  7D PnL: ${vault.pnl7D}');
  ///   print('  30D PnL: ${vault.pnl30D}');
  /// }
  /// ```
  Future<List<LeadingVault>> leadingVaults(String user) async {
    final data = await _transport.postInfo({
      'type': 'leadingVaults',
      'user': user.toLowerCase(),
    });

    if (data is! List) return [];
    return data
        .map((e) => LeadingVault.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch user's vault deposits across all vaults.
  ///
  /// [user] is the user's 42-character hex address.
  ///
  /// Returns an array of vault addresses and equity amounts for
  /// all vaults the user has deposited into.
  ///
  /// Example:
  /// ```dart
  /// final equities = await info.userVaultEquities('0x...');
  /// for (final equity in equities) {
  ///   print('Vault ${equity.vaultAddress}: \$${equity.equity}');
  /// }
  /// ```
  Future<List<UserVaultEquity>> userVaultEquities(String user) async {
    final data = await _transport.postInfo({
      'type': 'userVaultEquities',
      'user': user.toLowerCase(),
    });

    if (data is! List) return [];
    return data
        .map((e) => UserVaultEquity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Close the underlying HTTP client.
  void close() {
    _transport.close();
  }
}
