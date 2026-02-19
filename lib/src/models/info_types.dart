/// Types for Hyperliquid Info API responses.
library;

/// Raw candle data from Hyperliquid API.
class Candle {
  /// Start time (milliseconds).
  final int startTime;

  /// End time (milliseconds).
  final int endTime;

  /// Open price.
  final double open;

  /// High price.
  final double high;

  /// Low price.
  final double low;

  /// Close price.
  final double close;

  /// Volume.
  final double volume;

  /// Number of trades.
  final int numTrades;

  /// Symbol.
  final String? symbol;

  /// Interval.
  final String? interval;

  const Candle({
    required this.startTime,
    required this.endTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.numTrades,
    this.symbol,
    this.interval,
  });

  factory Candle.fromJson(Map<String, dynamic> json) {
    return Candle(
      startTime: json['t'] as int,
      endTime: json['T'] as int,
      open: double.parse(json['o'] as String),
      high: double.parse(json['h'] as String),
      low: double.parse(json['l'] as String),
      close: double.parse(json['c'] as String),
      volume: double.parse(json['v'] as String),
      numTrades: json['n'] as int,
      symbol: json['s'] as String?,
      interval: json['i'] as String?,
    );
  }
}

/// Asset metadata from the universe array.
class AssetMetadata {
  /// Coin name (e.g. "BTC", "ETH").
  final String name;

  /// Number of decimal places for size.
  final int szDecimals;

  /// Maximum allowed leverage.
  final int? maxLeverage;

  /// Whether only isolated margin is allowed.
  final bool? onlyIsolated;

  /// Whether the asset is delisted.
  final bool? isDelisted;

  const AssetMetadata({
    required this.name,
    required this.szDecimals,
    this.maxLeverage,
    this.onlyIsolated,
    this.isDelisted,
  });

  factory AssetMetadata.fromJson(Map<String, dynamic> json) {
    return AssetMetadata(
      name: json['name'] as String,
      szDecimals: json['szDecimals'] as int,
      maxLeverage: json['maxLeverage'] as int?,
      onlyIsolated: json['onlyIsolated'] as bool?,
      isDelisted: json['isDelisted'] as bool?,
    );
  }
}

/// Asset context data (funding rate, open interest, prices).
class AssetContext {
  /// Day notional volume.
  final String dayNtlVlm;

  /// Current funding rate.
  final String funding;

  /// Impact prices [bid, ask].
  final List<String> impactPxs;

  /// Mark price.
  final String markPx;

  /// Mid price.
  final String midPx;

  /// Open interest.
  final String openInterest;

  /// Oracle price.
  final String oraclePx;

  /// Premium.
  final String premium;

  /// Previous day price.
  final String prevDayPx;

  const AssetContext({
    required this.dayNtlVlm,
    required this.funding,
    required this.impactPxs,
    required this.markPx,
    required this.midPx,
    required this.openInterest,
    required this.oraclePx,
    required this.premium,
    required this.prevDayPx,
  });

  factory AssetContext.fromJson(Map<String, dynamic> json) {
    return AssetContext(
      dayNtlVlm: json['dayNtlVlm'] as String? ?? '0',
      funding: json['funding'] as String? ?? '0',
      impactPxs: (json['impactPxs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      markPx: json['markPx'] as String? ?? '0',
      midPx: json['midPx'] as String? ?? '0',
      openInterest: json['openInterest'] as String? ?? '0',
      oraclePx: json['oraclePx'] as String? ?? '0',
      premium: json['premium'] as String? ?? '0',
      prevDayPx: json['prevDayPx'] as String? ?? '0',
    );
  }
}

/// Meta response containing asset universe and collateral token.
class Meta {
  /// Asset universe metadata.
  final List<AssetMetadata> universe;

  /// Collateral token ID
  /// - 0 = Perp USDC (native margin token used by regular Hyperliquid perps)
  /// - >0 = Spot token (index in spotMeta().tokens array)
  /// - null = Not specified
  ///
  /// IMPORTANT: Token 0 is NOT spot USDC, it's the perpetual USDC margin token.
  /// Only token IDs > 0 refer to spot tokens (e.g., 360=USDH, 2=USDT).
  final int? collateralToken;

  const Meta({
    required this.universe,
    this.collateralToken,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    final universeList = (json['universe'] as List<dynamic>?) ?? [];
    return Meta(
      universe: universeList
          .map((e) => AssetMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
      collateralToken: json['collateralToken'] as int?,
    );
  }
}

/// Combined meta and asset contexts response.
class MetaAndAssetCtxs {
  /// Asset universe metadata.
  final List<AssetMetadata> universe;

  /// Per-asset context data (same order as universe).
  final List<AssetContext> assetCtxs;

  const MetaAndAssetCtxs({required this.universe, required this.assetCtxs});
}

/// L2 orderbook level: [price, size].
class L2Level {
  final String price;
  final String size;

  const L2Level({required this.price, required this.size});

  factory L2Level.fromJson(Map<String, dynamic> json) {
    return L2Level(
      price: json['px'] as String,
      size: json['sz'] as String,
    );
  }
}

/// L2 orderbook snapshot.
class L2Book {
  final String coin;
  final List<L2Level> bids;
  final List<L2Level> asks;
  final int? time;

  const L2Book({
    required this.coin,
    required this.bids,
    required this.asks,
    this.time,
  });

  factory L2Book.fromJson(Map<String, dynamic> json) {
    final levels = json['levels'] as List<dynamic>;
    return L2Book(
      coin: json['coin'] as String,
      bids: (levels[0] as List<dynamic>)
          .map((e) => L2Level.fromJson(e as Map<String, dynamic>))
          .toList(),
      asks: (levels[1] as List<dynamic>)
          .map((e) => L2Level.fromJson(e as Map<String, dynamic>))
          .toList(),
      time: json['time'] as int?,
    );
  }
}

/// User's clearinghouse state (positions, margin, etc.).
class ClearinghouseState {
  final Map<String, dynamic> raw;

  const ClearinghouseState(this.raw);

  /// Account equity as a string.
  String get accountValue =>
      (raw['marginSummary'] as Map<String, dynamic>?)?['accountValue']
          as String? ??
      '0';

  /// Total margin used.
  String get totalMarginUsed =>
      (raw['marginSummary'] as Map<String, dynamic>?)?['totalMarginUsed']
          as String? ??
      '0';

  /// Total notional position.
  String get totalNtlPos =>
      (raw['marginSummary'] as Map<String, dynamic>?)?['totalNtlPos']
          as String? ??
      '0';

  /// Total raw USD.
  String get totalRawUsd =>
      (raw['marginSummary'] as Map<String, dynamic>?)?['totalRawUsd']
          as String? ??
      '0';

  /// Withdrawable amount.
  String get withdrawable => raw['withdrawable'] as String? ?? '0';

  /// Cross margin summary.
  Map<String, dynamic>? get crossMarginSummary =>
      raw['crossMarginSummary'] as Map<String, dynamic>?;

  /// Asset positions.
  List<Map<String, dynamic>> get assetPositions =>
      (raw['assetPositions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  factory ClearinghouseState.fromJson(Map<String, dynamic> json) {
    return ClearinghouseState(json);
  }
}

/// A single open order.
class OpenOrder {
  final String coin;
  final String side;
  final String limitPx;
  final String sz;
  final int oid;
  final int timestamp;
  final String? triggerCondition;
  final bool? isTrigger;
  final String? triggerPx;
  final bool? reduceOnly;
  final String? orderType;
  final String? origSz;
  final String? tif;
  final String? cloid;

  const OpenOrder({
    required this.coin,
    required this.side,
    required this.limitPx,
    required this.sz,
    required this.oid,
    required this.timestamp,
    this.triggerCondition,
    this.isTrigger,
    this.triggerPx,
    this.reduceOnly,
    this.orderType,
    this.origSz,
    this.tif,
    this.cloid,
  });

  factory OpenOrder.fromJson(Map<String, dynamic> json) {
    return OpenOrder(
      coin: json['coin'] as String,
      side: json['side'] as String,
      limitPx: json['limitPx'] as String,
      sz: json['sz'] as String,
      oid: json['oid'] as int,
      timestamp: json['timestamp'] as int,
      triggerCondition: json['triggerCondition'] as String?,
      isTrigger: json['isTrigger'] as bool?,
      triggerPx: json['triggerPx']?.toString(),
      reduceOnly: json['reduceOnly'] as bool?,
      orderType: json['orderType'] as String?,
      origSz: json['origSz'] as String?,
      tif: json['tif'] as String?,
      cloid: json['cloid'] as String?,
    );
  }
}

/// A historical order with status.
class HistoricalOrder {
  final OpenOrder order;
  final String status;
  final int statusTimestamp;

  const HistoricalOrder({
    required this.order,
    required this.status,
    required this.statusTimestamp,
  });

  factory HistoricalOrder.fromJson(Map<String, dynamic> json) {
    return HistoricalOrder(
      order: OpenOrder.fromJson(json['order'] as Map<String, dynamic>),
      status: json['status'] as String,
      statusTimestamp: json['statusTimestamp'] as int,
    );
  }
}

/// A user fill (trade execution).
class UserFill {
  final String coin;
  final String px;
  final String sz;
  final String side;
  final int time;
  final String startPosition;
  final String dir;
  final String closedPnl;
  final String hash;
  final int oid;
  final bool crossed;
  final String fee;
  final int tid;
  final String? feeToken;
  final String? builderFee;

  const UserFill({
    required this.coin,
    required this.px,
    required this.sz,
    required this.side,
    required this.time,
    required this.startPosition,
    required this.dir,
    required this.closedPnl,
    required this.hash,
    required this.oid,
    required this.crossed,
    required this.fee,
    required this.tid,
    this.feeToken,
    this.builderFee,
  });

  factory UserFill.fromJson(Map<String, dynamic> json) {
    return UserFill(
      coin: json['coin'] as String,
      px: json['px'] as String,
      sz: json['sz'] as String,
      side: json['side'] as String,
      time: json['time'] as int,
      startPosition: json['startPosition'] as String,
      dir: json['dir'] as String,
      closedPnl: json['closedPnl'] as String,
      hash: json['hash'] as String,
      oid: json['oid'] as int,
      crossed: json['crossed'] as bool,
      fee: json['fee'] as String,
      tid: json['tid'] as int,
      feeToken: json['feeToken'] as String?,
      builderFee: json['builderFee'] as String?,
    );
  }
}

/// A user funding payment.
class UserFunding {
  final int time;
  final String coin;
  final String usdc;
  final String szi;
  final String fundingRate;
  final String nSamples;

  const UserFunding({
    required this.time,
    required this.coin,
    required this.usdc,
    required this.szi,
    required this.fundingRate,
    required this.nSamples,
  });

  factory UserFunding.fromJson(Map<String, dynamic> json) {
    return UserFunding(
      time: json['time'] as int,
      coin: json['coin'] as String,
      usdc: json['usdc'] as String,
      szi: json['szi'] as String,
      fundingRate: json['fundingRate'] as String,
      nSamples: json['nSamples']?.toString() ?? '0',
    );
  }
}

/// Spot balance entry.
class SpotBalance {
  final String coin;
  final int token;
  final String hold;
  final String total;
  final String entryNtl;

  const SpotBalance({
    required this.coin,
    required this.token,
    required this.hold,
    required this.total,
    required this.entryNtl,
  });

  factory SpotBalance.fromJson(Map<String, dynamic> json) {
    return SpotBalance(
      coin: json['coin'] as String,
      token: json['token'] as int,
      hold: json['hold'] as String,
      total: json['total'] as String,
      entryNtl: json['entryNtl'] as String,
    );
  }
}

/// Spot clearinghouse state.
class SpotClearinghouseState {
  final List<SpotBalance> balances;

  const SpotClearinghouseState({required this.balances});

  factory SpotClearinghouseState.fromJson(Map<String, dynamic> json) {
    return SpotClearinghouseState(
      balances: (json['balances'] as List<dynamic>?)
              ?.map((e) => SpotBalance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Spot universe definition
class SpotUniverse {
  final List<int> tokens;
  final String name;
  final int index;
  final bool isCanonical;

  const SpotUniverse({
    required this.tokens,
    required this.name,
    required this.index,
    required this.isCanonical,
  });

  factory SpotUniverse.fromJson(Map<String, dynamic> json) {
    return SpotUniverse(
      tokens: (json['tokens'] as List<dynamic>).cast<int>(),
      name: json['name'] as String,
      index: json['index'] as int,
      isCanonical: json['isCanonical'] as bool,
    );
  }
}

/// Spot token metadata
class SpotToken {
  final String name;
  final int szDecimals;
  final int weiDecimals;
  final int index;
  final String tokenId;
  final bool isCanonical;
  final Map<String, dynamic>? evmContract;
  final String? fullName;
  final String deployerTradingFeeShare;

  const SpotToken({
    required this.name,
    required this.szDecimals,
    required this.weiDecimals,
    required this.index,
    required this.tokenId,
    required this.isCanonical,
    this.evmContract,
    this.fullName,
    required this.deployerTradingFeeShare,
  });

  factory SpotToken.fromJson(Map<String, dynamic> json) {
    return SpotToken(
      name: json['name'] as String,
      szDecimals: json['szDecimals'] as int,
      weiDecimals: json['weiDecimals'] as int,
      index: json['index'] as int,
      tokenId: json['tokenId'] as String,
      isCanonical: json['isCanonical'] as bool,
      evmContract: json['evmContract'] as Map<String, dynamic>?,
      fullName: json['fullName'] as String?,
      deployerTradingFeeShare: json['deployerTradingFeeShare'] as String,
    );
  }
}

/// Spot metadata response
class SpotMeta {
  final List<SpotUniverse> universe;
  final List<SpotToken> tokens;

  const SpotMeta({
    required this.universe,
    required this.tokens,
  });

  factory SpotMeta.fromJson(Map<String, dynamic> json) {
    return SpotMeta(
      universe: (json['universe'] as List<dynamic>?)
              ?.map((e) => SpotUniverse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tokens: (json['tokens'] as List<dynamic>?)
              ?.map((e) => SpotToken.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Spot asset context (market data)
class SpotAssetContext {
  final String prevDayPx;
  final String dayNtlVlm;
  final String markPx;
  final String? midPx;
  final String circulatingSupply;
  final String coin;
  final String totalSupply;
  final String dayBaseVlm;

  const SpotAssetContext({
    required this.prevDayPx,
    required this.dayNtlVlm,
    required this.markPx,
    this.midPx,
    required this.circulatingSupply,
    required this.coin,
    required this.totalSupply,
    required this.dayBaseVlm,
  });

  factory SpotAssetContext.fromJson(Map<String, dynamic> json) {
    return SpotAssetContext(
      prevDayPx: json['prevDayPx'] as String,
      dayNtlVlm: json['dayNtlVlm'] as String,
      markPx: json['markPx'] as String,
      midPx: json['midPx'] as String?,
      circulatingSupply: json['circulatingSupply'] as String,
      coin: json['coin'] as String,
      totalSupply: json['totalSupply'] as String,
      dayBaseVlm: json['dayBaseVlm'] as String,
    );
  }
}

/// Combined spot metadata and asset contexts
class SpotMetaAndAssetCtxs {
  final SpotMeta meta;
  final List<SpotAssetContext> assetCtxs;

  const SpotMetaAndAssetCtxs({
    required this.meta,
    required this.assetCtxs,
  });

  factory SpotMetaAndAssetCtxs.fromJson(List<dynamic> json) {
    if (json.length < 2) {
      return const SpotMetaAndAssetCtxs(
        meta: SpotMeta(universe: [], tokens: []),
        assetCtxs: [],
      );
    }

    return SpotMetaAndAssetCtxs(
      meta: SpotMeta.fromJson(json[0] as Map<String, dynamic>),
      assetCtxs: (json[1] as List<dynamic>?)
              ?.map((e) => SpotAssetContext.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Token details response
class TokenDetails {
  final String name;
  final String maxSupply;
  final String totalSupply;
  final String circulatingSupply;
  final int szDecimals;
  final int weiDecimals;
  final String midPx;
  final String markPx;
  final String prevDayPx;
  final Map<String, dynamic>? genesis;
  final String? deployer;
  final String? deployGas;
  final String? deployTime;
  final String seededUsdc;
  final List<dynamic> nonCirculatingUserBalances;
  final String futureEmissions;

  const TokenDetails({
    required this.name,
    required this.maxSupply,
    required this.totalSupply,
    required this.circulatingSupply,
    required this.szDecimals,
    required this.weiDecimals,
    required this.midPx,
    required this.markPx,
    required this.prevDayPx,
    this.genesis,
    this.deployer,
    this.deployGas,
    this.deployTime,
    required this.seededUsdc,
    required this.nonCirculatingUserBalances,
    required this.futureEmissions,
  });

  factory TokenDetails.fromJson(Map<String, dynamic> json) {
    return TokenDetails(
      name: json['name'] as String,
      maxSupply: json['maxSupply'] as String,
      totalSupply: json['totalSupply'] as String,
      circulatingSupply: json['circulatingSupply'] as String,
      szDecimals: json['szDecimals'] as int,
      weiDecimals: json['weiDecimals'] as int,
      midPx: json['midPx'] as String,
      markPx: json['markPx'] as String,
      prevDayPx: json['prevDayPx'] as String,
      genesis: json['genesis'] as Map<String, dynamic>?,
      deployer: json['deployer'] as String?,
      deployGas: json['deployGas'] as String?,
      deployTime: json['deployTime'] as String?,
      seededUsdc: json['seededUsdc'] as String,
      nonCirculatingUserBalances: json['nonCirculatingUserBalances'] as List<dynamic>? ?? [],
      futureEmissions: json['futureEmissions'] as String,
    );
  }
}

/// Sub-account balance information
class SubAccountBalance {
  final String coin;
  final int token;
  final String total;
  final String hold;
  final String entryNtl;

  const SubAccountBalance({
    required this.coin,
    required this.token,
    required this.total,
    required this.hold,
    required this.entryNtl,
  });

  factory SubAccountBalance.fromJson(Map<String, dynamic> json) {
    return SubAccountBalance(
      coin: json['coin'] as String,
      token: json['token'] as int,
      total: json['total'] as String,
      hold: json['hold'] as String,
      entryNtl: json['entryNtl'] as String,
    );
  }
}

/// Sub-account spot state
class SubAccountSpotState {
  final List<SubAccountBalance> balances;

  const SubAccountSpotState({required this.balances});

  factory SubAccountSpotState.fromJson(Map<String, dynamic> json) {
    return SubAccountSpotState(
      balances: (json['balances'] as List<dynamic>?)
              ?.map((e) => SubAccountBalance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Sub-account information
class SubAccount {
  final String name;
  final String subAccountUser;
  final String master;
  final ClearinghouseState clearinghouseState;
  final SubAccountSpotState spotState;

  const SubAccount({
    required this.name,
    required this.subAccountUser,
    required this.master,
    required this.clearinghouseState,
    required this.spotState,
  });

  factory SubAccount.fromJson(Map<String, dynamic> json) {
    return SubAccount(
      name: json['name'] as String,
      subAccountUser: json['subAccountUser'] as String,
      master: json['master'] as String,
      clearinghouseState: ClearinghouseState.fromJson(
        json['clearinghouseState'] as Map<String, dynamic>,
      ),
      spotState: SubAccountSpotState.fromJson(
        json['spotState'] as Map<String, dynamic>,
      ),
    );
  }
}

/// HIP-3 builder-deployed perpetual DEX information
///
/// NOTE: The perpDexs() endpoint does NOT include collateralToken.
/// To get the collateral token for a DEX:
/// 1. Call meta(dex: "dexName") - response includes collateralToken field
/// 2. Call spotMeta() to get the tokens array
/// 3. Look up tokens[collateralToken].name
///
/// Example:
/// ```dart
/// final dexs = await info.perpDexs();
/// final xyzMeta = await info.meta(dex: 'xyz');
/// // xyzMeta response includes collateralToken (e.g., 0 for USDC, 360 for USDH)
/// ```
class PerpDex {
  /// DEX short name (e.g., "xyz")
  final String name;

  /// Full display name
  final String fullName;

  /// Deployer address
  final String deployer;

  /// Collateral token ID indicating which token is used as margin for this DEX
  /// - 0 = Perp USDC (the native margin token, same as regular Hyperliquid perps)
  /// - >0 = Spot token (e.g., 360=USDH, 2=USDT) from spotMeta().tokens array
  /// - null = Not returned by perpDexs() endpoint (use meta(dex) to get it)
  ///
  /// CRITICAL: Token 0 is NOT spot USDC! It's the perpetual USDC margin token.
  /// Only HIP-3 DEXs with collateralToken > 0 use actual spot tokens as margin.
  final int? collateralToken;

  /// Map of asset to streaming OI cap
  /// Key: "dex:asset" (e.g., "xyz:AAPL")
  /// Value: Cap as string (e.g., "25000000.0")
  final Map<String, String> assetToStreamingOiCap;

  /// Map of asset to funding multiplier
  /// Key: "dex:asset"
  /// Value: Multiplier as string
  final Map<String, String> assetToFundingMultiplier;

  const PerpDex({
    required this.name,
    required this.fullName,
    required this.deployer,
    required this.collateralToken,
    required this.assetToStreamingOiCap,
    required this.assetToFundingMultiplier,
  });

  factory PerpDex.fromJson(Map<String, dynamic> json) {
    // Parse assetToStreamingOiCap from array format
    final oiCapList = json['assetToStreamingOiCap'] as List<dynamic>? ?? [];
    final oiCapMap = <String, String>{};
    for (final item in oiCapList) {
      if (item is List && item.length >= 2) {
        oiCapMap[item[0] as String] = item[1] as String;
      }
    }

    // Parse assetToFundingMultiplier from array format
    final fundingList =
        json['assetToFundingMultiplier'] as List<dynamic>? ?? [];
    final fundingMap = <String, String>{};
    for (final item in fundingList) {
      if (item is List && item.length >= 2) {
        fundingMap[item[0] as String] = item[1] as String;
      }
    }

    return PerpDex(
      name: json['name'] as String,
      fullName: json['fullName'] as String,
      deployer: json['deployer'] as String,
      collateralToken: json['collateralToken'] as int?,
      assetToStreamingOiCap: oiCapMap,
      assetToFundingMultiplier: fundingMap,
    );
  }

  /// Get collateral token symbol from ID
  ///
  /// IMPORTANT: Token 0 is Perp USDC (native margin), NOT spot USDC!
  /// - 0 = Perp USDC (same margin token as regular Hyperliquid perps)
  /// - >0 = Spot token from spotMeta().tokens array (e.g., 360=USDH, 2=USDT)
  ///
  /// For accurate token names with collateralToken > 0, call:
  /// ```dart
  /// final tokens = await info.spotMeta();
  /// final tokenName = tokens.tokens[collateralToken].name;
  /// ```
  String getCollateralSymbol() {
    if (collateralToken == null) {
      return 'Unknown';
    }
    switch (collateralToken) {
      case 0:
        return 'Perp USDC'; // Native margin token, NOT spot USDC
      case 360:
        return 'USDH'; // Spot token
      case 2:
        return 'USDT'; // Spot token
      default:
        return 'Spot Token $collateralToken'; // Other spot tokens
    }
  }
}

/// A recent trade.
class Trade {
  final String coin;
  final String side;
  final String px;
  final String sz;
  final int time;
  final String hash;
  final int tid;

  const Trade({
    required this.coin,
    required this.side,
    required this.px,
    required this.sz,
    required this.time,
    required this.hash,
    required this.tid,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      coin: json['coin'] as String,
      side: json['side'] as String,
      px: json['px'] as String,
      sz: json['sz'] as String,
      time: json['time'] as int,
      hash: json['hash'] as String,
      tid: json['tid'] as int,
    );
  }
}

/// Order status response.
class OrderStatusResponse {
  /// Status type: "order" or "unknownOid"
  final String status;

  /// Order details if status is "order", null if "unknownOid"
  final OrderDetail? order;

  const OrderStatusResponse({required this.status, this.order});

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponse(
      status: json['status'] as String,
      order: json['order'] != null
          ? OrderDetail.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Order detail with status information.
class OrderDetail {
  /// Order information
  final OrderInfo order;

  /// Order status: "open", "filled", "canceled", "triggered", "rejected", etc.
  final String status;

  /// Status timestamp in milliseconds
  final int statusTimestamp;

  const OrderDetail({
    required this.order,
    required this.status,
    required this.statusTimestamp,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      order: OrderInfo.fromJson(json['order'] as Map<String, dynamic>),
      status: json['status'] as String,
      statusTimestamp: json['statusTimestamp'] as int,
    );
  }
}

/// Detailed order information.
class OrderInfo {
  /// Asset symbol
  final String coin;

  /// Side: "A" (ask/sell) or "B" (bid/buy)
  final String side;

  /// Limit price
  final String limitPx;

  /// Current size
  final String sz;

  /// Order ID
  final int oid;

  /// Order timestamp in milliseconds
  final int timestamp;

  /// Trigger condition
  final String triggerCondition;

  /// Whether this is a trigger order
  final bool isTrigger;

  /// Trigger price
  final String triggerPx;

  /// Child orders (TP/SL pairs)
  final List<dynamic> children;

  /// Whether this is a position TP/SL
  final bool isPositionTpsl;

  /// Reduce-only flag
  final bool reduceOnly;

  /// Order type
  final String orderType;

  /// Original size
  final String origSz;

  /// Time in force
  final String tif;

  /// Client order ID (optional)
  final String? cloid;

  const OrderInfo({
    required this.coin,
    required this.side,
    required this.limitPx,
    required this.sz,
    required this.oid,
    required this.timestamp,
    required this.triggerCondition,
    required this.isTrigger,
    required this.triggerPx,
    required this.children,
    required this.isPositionTpsl,
    required this.reduceOnly,
    required this.orderType,
    required this.origSz,
    required this.tif,
    this.cloid,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      coin: json['coin'] as String,
      side: json['side'] as String,
      limitPx: json['limitPx'] as String,
      sz: json['sz'] as String,
      oid: json['oid'] as int,
      timestamp: json['timestamp'] as int,
      triggerCondition: json['triggerCondition'] as String,
      isTrigger: json['isTrigger'] as bool,
      triggerPx: json['triggerPx'] as String,
      children: json['children'] as List<dynamic>,
      isPositionTpsl: json['isPositionTpsl'] as bool,
      reduceOnly: json['reduceOnly'] as bool,
      orderType: json['orderType'] as String,
      origSz: json['origSz'] as String,
      tif: json['tif'] as String,
      cloid: json['cloid'] as String?,
    );
  }
}

/// Portfolio response with performance data across time periods.
class PortfolioResponse {
  /// Map of period name to period data
  final Map<String, PortfolioPeriod> periods;

  const PortfolioResponse({required this.periods});

  factory PortfolioResponse.fromJson(List<dynamic> json) {
    final periodsMap = <String, PortfolioPeriod>{};
    for (final item in json) {
      final periodName = item[0] as String;
      final periodData = item[1] as Map<String, dynamic>;
      periodsMap[periodName] = PortfolioPeriod.fromJson(periodData);
    }
    return PortfolioResponse(periods: periodsMap);
  }
}

/// Portfolio data for a specific time period.
class PortfolioPeriod {
  /// Account value history: [[timestamp_ms, value], ...]
  final List<List<dynamic>> accountValueHistory;

  /// PnL history: [[timestamp_ms, pnl], ...]
  final List<List<dynamic>> pnlHistory;

  /// Total trading volume
  final String vlm;

  const PortfolioPeriod({
    required this.accountValueHistory,
    required this.pnlHistory,
    required this.vlm,
  });

  factory PortfolioPeriod.fromJson(Map<String, dynamic> json) {
    return PortfolioPeriod(
      accountValueHistory:
          (json['accountValueHistory'] as List<dynamic>).cast<List<dynamic>>(),
      pnlHistory: (json['pnlHistory'] as List<dynamic>).cast<List<dynamic>>(),
      vlm: json['vlm'] as String,
    );
  }
}

/// Funding history entry.
class FundingHistoryEntry {
  /// Asset symbol
  final String coin;

  /// Funding rate in decimal format
  final String fundingRate;

  /// Market premium component
  final String premium;

  /// Timestamp in milliseconds
  final int time;

  const FundingHistoryEntry({
    required this.coin,
    required this.fundingRate,
    required this.premium,
    required this.time,
  });

  factory FundingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return FundingHistoryEntry(
      coin: json['coin'] as String,
      fundingRate: json['fundingRate'] as String,
      premium: json['premium'] as String,
      time: json['time'] as int,
    );
  }
}

/// Best bid-offer update from WebSocket.
class BboUpdate {
  /// Asset symbol
  final String coin;

  /// Timestamp in milliseconds
  final int time;

  /// Best bid-offer pair: [bid, ask]
  final List<BboLevel> bbo;

  const BboUpdate({
    required this.coin,
    required this.time,
    required this.bbo,
  });

  factory BboUpdate.fromJson(Map<String, dynamic> json) {
    final bboList = json['bbo'] as List<dynamic>;
    return BboUpdate(
      coin: json['coin'] as String,
      time: json['time'] as int,
      bbo: bboList
          .map((e) => BboLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Single BBO level (bid or ask).
class BboLevel {
  /// Price
  final String px;

  /// Size
  final String sz;

  const BboLevel({required this.px, required this.sz});

  factory BboLevel.fromJson(Map<String, dynamic> json) {
    return BboLevel(
      px: json['px'] as String,
      sz: json['sz'] as String,
    );
  }
}

/// WebData3 aggregate user information.
class WebData3 {
  /// User address
  final String user;

  /// User state with positions and margins
  final Map<String, dynamic> userState;

  /// Perpetual DEX states
  final List<dynamic> perpDexStates;

  /// Vaults information
  final List<dynamic> vaultsInfo;

  const WebData3({
    required this.user,
    required this.userState,
    required this.perpDexStates,
    required this.vaultsInfo,
  });

  factory WebData3.fromJson(Map<String, dynamic> json) {
    return WebData3(
      user: json['user'] as String? ?? '',
      userState: json['userState'] as Map<String, dynamic>? ?? {},
      perpDexStates: json['perpDexStates'] as List<dynamic>? ?? [],
      vaultsInfo: json['vaultsInfo'] as List<dynamic>? ?? [],
    );
  }
}

/// Notification message.
class NotificationMessage {
  /// User address receiving notification
  final String user;

  /// Notification message content
  final String message;

  const NotificationMessage({
    required this.user,
    required this.message,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      user: json['user'] as String,
      message: json['message'] as String,
    );
  }
}

/// TWAP execution state.
class TwapState {
  /// TWAP ID.
  final int twapId;

  /// Asset name.
  final String coin;

  /// Buy (true) or sell (false).
  final bool isBuy;

  /// Limit price.
  final String limitPx;

  /// Total size.
  final String sz;

  /// Size filled so far.
  final String szFilled;

  /// Duration in minutes.
  final int durationMins;

  /// Start timestamp in milliseconds.
  final int startTime;

  /// Status: "running", "finished", "canceled".
  final String status;

  /// Reduce only flag.
  final bool reduceOnly;

  const TwapState({
    required this.twapId,
    required this.coin,
    required this.isBuy,
    required this.limitPx,
    required this.sz,
    required this.szFilled,
    required this.durationMins,
    required this.startTime,
    required this.status,
    required this.reduceOnly,
  });

  factory TwapState.fromJson(Map<String, dynamic> json) {
    return TwapState(
      twapId: json['twapId'] as int,
      coin: json['coin'] as String,
      isBuy: json['isBuy'] as bool,
      limitPx: json['limitPx'] as String,
      sz: json['sz'] as String,
      szFilled: json['szFilled'] as String,
      durationMins: json['durationMins'] as int,
      startTime: json['startTime'] as int,
      status: json['status'] as String,
      reduceOnly: json['reduceOnly'] as bool,
    );
  }
}

/// Historical TWAP execution event.
class TwapHistoryEvent {
  /// TWAP ID (may be null for initial snapshot).
  final int? twapId;

  /// Asset name.
  final String coin;

  /// Buy (true) or sell (false).
  final bool isBuy;

  /// Limit price.
  final String limitPx;

  /// Total size.
  final String sz;

  /// Size filled.
  final String szFilled;

  /// Duration in minutes.
  final int durationMins;

  /// Start timestamp.
  final int startTime;

  /// End timestamp (may be null if still running).
  final int? endTime;

  /// Status: "running", "finished", "canceled".
  final String status;

  /// Reduce only flag.
  final bool reduceOnly;

  const TwapHistoryEvent({
    this.twapId,
    required this.coin,
    required this.isBuy,
    required this.limitPx,
    required this.sz,
    required this.szFilled,
    required this.durationMins,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.reduceOnly,
  });

  factory TwapHistoryEvent.fromJson(Map<String, dynamic> json) {
    return TwapHistoryEvent(
      twapId: json['twapId'] as int?,
      coin: json['coin'] as String,
      isBuy: json['isBuy'] as bool,
      limitPx: json['limitPx'] as String,
      sz: json['sz'] as String,
      szFilled: json['szFilled'] as String,
      durationMins: json['durationMins'] as int,
      startTime: json['startTime'] as int,
      endTime: json['endTime'] as int?,
      status: json['status'] as String,
      reduceOnly: json['reduceOnly'] as bool,
    );
  }
}

/// Individual TWAP slice fill event.
class TwapSliceFill {
  /// Associated TWAP ID (may be null in some WebSocket messages).
  final int? twapId;

  /// Asset name.
  final String coin;

  /// Fill price.
  final String px;

  /// Fill size.
  final String sz;

  /// Timestamp of fill.
  final int time;

  /// User address.
  final String user;

  /// Buy (true) or sell (false).
  final bool isBuy;

  /// Note: hash will be "0x000...000" for TWAP fills.
  final String hash;

  const TwapSliceFill({
    this.twapId,
    required this.coin,
    required this.px,
    required this.sz,
    required this.time,
    required this.user,
    required this.isBuy,
    required this.hash,
  });

  factory TwapSliceFill.fromJson(Map<String, dynamic> json) {
    return TwapSliceFill(
      twapId: json['twapId'] as int?,
      coin: json['coin'] as String,
      px: json['px'] as String,
      sz: json['sz'] as String,
      time: json['time'] as int,
      user: json['user'] as String,
      isBuy: json['isBuy'] as bool,
      hash: json['hash'] as String,
    );
  }
}

/// User fee structure and trading costs
class UserFees {
  /// Daily volume records
  final List<DailyUserVolume> dailyUserVlm;

  /// User's cross rate (taker fee)
  final String userCrossRate;

  /// User's add rate (maker rebate)
  final String userAddRate;

  /// User's spot cross rate (spot taker fee)
  final String userSpotCrossRate;

  /// User's spot add rate (spot maker rebate)
  final String userSpotAddRate;

  /// Active referral discount (e.g., "0.01" for 1%)
  final String? activeReferralDiscount;

  /// Active staking discount
  final ActiveStakingDiscount? activeStakingDiscount;

  /// Fee trial info (null if not in trial)
  final FeeTrial? trial;

  /// Fee trial reward amount
  final String? feeTrialReward;

  /// Next trial available timestamp (null if no cooldown)
  final int? nextTrialAvailableTimestamp;

  const UserFees({
    required this.dailyUserVlm,
    required this.userCrossRate,
    required this.userAddRate,
    required this.userSpotCrossRate,
    required this.userSpotAddRate,
    this.activeReferralDiscount,
    this.activeStakingDiscount,
    this.trial,
    this.feeTrialReward,
    this.nextTrialAvailableTimestamp,
  });

  factory UserFees.fromJson(Map<String, dynamic> json) {
    final vlmList = (json['dailyUserVlm'] as List<dynamic>?) ?? [];
    final trialData = json['trial'];
    final stakingData = json['activeStakingDiscount'];

    return UserFees(
      dailyUserVlm: vlmList
          .map((e) => DailyUserVolume.fromJson(e as Map<String, dynamic>))
          .toList(),
      userCrossRate: json['userCrossRate'] as String? ?? '0',
      userAddRate: json['userAddRate'] as String? ?? '0',
      userSpotCrossRate: json['userSpotCrossRate'] as String? ?? '0',
      userSpotAddRate: json['userSpotAddRate'] as String? ?? '0',
      activeReferralDiscount: json['activeReferralDiscount'] as String?,
      activeStakingDiscount: stakingData != null
          ? ActiveStakingDiscount.fromJson(stakingData as Map<String, dynamic>)
          : null,
      trial:
          trialData != null ? FeeTrial.fromJson(trialData as Map<String, dynamic>) : null,
      feeTrialReward: json['feeTrialReward'] as String?,
      nextTrialAvailableTimestamp: json['nextTrialAvailableTimestamp'] as int?,
    );
  }
}

/// Daily user trading volume
class DailyUserVolume {
  /// Date (e.g., "2024-01-15")
  final String date;

  /// User cross volume (taker)
  final String userCross;

  /// User add volume (maker)
  final String userAdd;

  /// Total exchange volume
  final String exchange;

  const DailyUserVolume({
    required this.date,
    required this.userCross,
    required this.userAdd,
    required this.exchange,
  });

  factory DailyUserVolume.fromJson(Map<String, dynamic> json) {
    return DailyUserVolume(
      date: json['date'] as String,
      userCross: json['userCross'] as String,
      userAdd: json['userAdd'] as String,
      exchange: json['exchange'] as String,
    );
  }
}

/// Active staking discount information
class ActiveStakingDiscount {
  /// Basis points of max supply staked
  final String bpsOfMaxSupply;

  /// Discount percentage (e.g., "0.05" for 5%)
  final String discount;

  const ActiveStakingDiscount({
    required this.bpsOfMaxSupply,
    required this.discount,
  });

  factory ActiveStakingDiscount.fromJson(Map<String, dynamic> json) {
    return ActiveStakingDiscount(
      bpsOfMaxSupply: json['bpsOfMaxSupply'] as String,
      discount: json['discount'] as String,
    );
  }
}

/// Fee trial information
class FeeTrial {
  /// Trial end timestamp
  final int endTimestamp;

  const FeeTrial({required this.endTimestamp});

  factory FeeTrial.fromJson(Map<String, dynamic> json) {
    return FeeTrial(
      endTimestamp: json['endTimestamp'] as int,
    );
  }
}

/// Non-funding ledger update entry
class LedgerUpdate {
  /// Transaction timestamp (milliseconds)
  final int time;

  /// Transaction hash (or "0x000...000" for internal transfers)
  final String hash;

  /// Update details (type and amounts)
  final LedgerDelta delta;

  const LedgerUpdate({
    required this.time,
    required this.hash,
    required this.delta,
  });

  factory LedgerUpdate.fromJson(Map<String, dynamic> json) {
    return LedgerUpdate(
      time: json['time'] as int,
      hash: json['hash'] as String,
      delta: LedgerDelta.fromJson(json['delta'] as Map<String, dynamic>),
    );
  }
}

/// Ledger delta (update details)
class LedgerDelta {
  /// Update type (deposit, withdraw, accountClassTransfer, etc.)
  final String type;

  /// Raw delta data (contains type-specific fields)
  final Map<String, dynamic> data;

  const LedgerDelta({
    required this.type,
    required this.data,
  });

  factory LedgerDelta.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return LedgerDelta(
      type: type,
      data: Map<String, dynamic>.from(json),
    );
  }

  /// Get USDC amount (for deposit, withdraw, transfer operations)
  String? get usdc => data['usdc'] as String?;

  /// Get token symbol (for spot operations)
  String? get token => data['token'] as String?;

  /// Get token amount (for spot operations)
  String? get amount => data['amount'] as String?;

  /// Get transfer direction (for accountClassTransfer)
  bool? get toPerp => data['toPerp'] as bool?;

  /// Get source user (for transfers)
  String? get user => data['user'] as String?;

  /// Get destination (for transfers)
  String? get destination => data['destination'] as String?;

  /// Get fee amount
  String? get fee => data['fee'] as String?;

  /// Get nonce (for withdrawals and some transfers)
  int? get nonce => data['nonce'] as int?;
}

// =============================================================================
// VAULT MODELS
// =============================================================================

/// Vault relationship data for parent/child vaults.
class VaultRelationshipData {
  /// Child vault addresses (only for parent vaults)
  final List<String>? childAddresses;

  const VaultRelationshipData({this.childAddresses});

  factory VaultRelationshipData.fromJson(Map<String, dynamic> json) {
    return VaultRelationshipData(
      childAddresses: (json['childAddresses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

/// Vault relationship type and data.
class VaultRelationship {
  /// Relationship type: "normal", "child", or "parent"
  final String type;

  /// Relationship data (optional)
  final VaultRelationshipData? data;

  const VaultRelationship({
    required this.type,
    this.data,
  });

  factory VaultRelationship.fromJson(Map<String, dynamic> json) {
    return VaultRelationship(
      type: json['type'] as String? ?? 'normal',
      data: json['data'] != null
          ? VaultRelationshipData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Follower state for a specific user (structure TBD).
class FollowerState {
  /// Raw follower state data
  final Map<String, dynamic> data;

  const FollowerState({required this.data});

  factory FollowerState.fromJson(Map<String, dynamic> json) {
    return FollowerState(data: json);
  }
}

/// Individual vault follower information.
class VaultFollower {
  /// User address
  final String user;

  /// User's equity in the vault
  final String vaultEquity;

  /// Current PnL
  final String pnl;

  /// All-time PnL
  final String allTimePnl;

  /// Days following the vault
  final int daysFollowing;

  /// Timestamp when user entered vault
  final int vaultEntryTime;

  /// Lockup expiration timestamp (optional)
  final int? lockupUntil;

  const VaultFollower({
    required this.user,
    required this.vaultEquity,
    required this.pnl,
    required this.allTimePnl,
    required this.daysFollowing,
    required this.vaultEntryTime,
    this.lockupUntil,
  });

  factory VaultFollower.fromJson(Map<String, dynamic> json) {
    return VaultFollower(
      user: json['user'] as String,
      vaultEquity: json['vaultEquity'] as String,
      pnl: json['pnl'] as String,
      allTimePnl: json['allTimePnl'] as String,
      daysFollowing: json['daysFollowing'] as int,
      vaultEntryTime: json['vaultEntryTime'] as int,
      lockupUntil: json['lockupUntil'] as int?,
    );
  }
}

/// Complete vault portfolio with performance metrics for different time periods.
class VaultPortfolio {
  /// Daily performance
  final PortfolioPeriod day;

  /// Weekly performance
  final PortfolioPeriod week;

  /// Monthly performance
  final PortfolioPeriod month;

  /// All-time performance
  final PortfolioPeriod allTime;

  /// Daily perpetual performance
  final PortfolioPeriod perpDay;

  /// Weekly perpetual performance
  final PortfolioPeriod perpWeek;

  /// Monthly perpetual performance
  final PortfolioPeriod perpMonth;

  /// All-time perpetual performance
  final PortfolioPeriod perpAllTime;

  const VaultPortfolio({
    required this.day,
    required this.week,
    required this.month,
    required this.allTime,
    required this.perpDay,
    required this.perpWeek,
    required this.perpMonth,
    required this.perpAllTime,
  });

  /// Parse portfolio from API response which comes as an array of tuples.
  /// Format: [["day", {...}], ["week", {...}], ["month", {...}], ...]
  factory VaultPortfolio.fromJson(List<dynamic> portfolioArray) {
    final emptyPeriod = PortfolioPeriod(
      accountValueHistory: [],
      pnlHistory: [],
      vlm: '0',
    );

    // Convert array of tuples to map for easier access
    final Map<String, PortfolioPeriod> periods = {};
    for (final item in portfolioArray) {
      if (item is List && item.length == 2) {
        final key = item[0] as String;
        final value = item[1] as Map<String, dynamic>;
        periods[key] = PortfolioPeriod.fromJson(value);
      }
    }

    return VaultPortfolio(
      day: periods['day'] ?? emptyPeriod,
      week: periods['week'] ?? emptyPeriod,
      month: periods['month'] ?? emptyPeriod,
      allTime: periods['allTime'] ?? emptyPeriod,
      perpDay: periods['perpDay'] ?? emptyPeriod,
      perpWeek: periods['perpWeek'] ?? emptyPeriod,
      perpMonth: periods['perpMonth'] ?? emptyPeriod,
      perpAllTime: periods['perpAllTime'] ?? emptyPeriod,
    );
  }
}

/// Detailed vault information including performance, followers, and configuration.
class VaultDetails {
  /// Vault address
  final String vaultAddress;

  /// Vault name
  final String name;

  /// Vault leader address
  final String leader;

  /// Vault description (optional)
  final String? description;

  /// Portfolio performance metrics
  final VaultPortfolio portfolio;

  /// Annual percentage return (as decimal, e.g. 0.73 = 73%)
  final double apr;

  /// List of vault followers
  final List<VaultFollower> followers;

  /// User-specific follower state (optional)
  final FollowerState? followerState;

  /// Leader commission rate (as decimal, e.g. 0.0 = 0%)
  final double leaderCommission;

  /// Leader's equity share fraction (as decimal)
  final double leaderFraction;

  /// Maximum distributable amount (USDC)
  final double maxDistributable;

  /// Maximum withdrawable amount (USDC)
  final double maxWithdrawable;

  /// Whether vault is closed
  final bool isClosed;

  /// Vault relationship (parent/child structure)
  final VaultRelationship? relationship;

  /// Whether deposits are allowed
  final bool allowDeposits;

  /// Whether to always close positions on withdrawal
  final bool alwaysCloseOnWithdraw;

  const VaultDetails({
    required this.vaultAddress,
    required this.name,
    required this.leader,
    this.description,
    required this.portfolio,
    required this.apr,
    required this.followers,
    this.followerState,
    required this.leaderCommission,
    required this.leaderFraction,
    required this.maxDistributable,
    required this.maxWithdrawable,
    required this.isClosed,
    this.relationship,
    required this.allowDeposits,
    required this.alwaysCloseOnWithdraw,
  });

  factory VaultDetails.fromJson(Map<String, dynamic> json) {
    return VaultDetails(
      vaultAddress: json['vaultAddress'] as String,
      name: json['name'] as String,
      leader: json['leader'] as String,
      description: json['description'] as String?,
      portfolio: VaultPortfolio.fromJson(json['portfolio'] as List<dynamic>),
      apr: (json['apr'] as num?)?.toDouble() ?? 0.0,
      followers: (json['followers'] as List<dynamic>?)
              ?.map((e) => VaultFollower.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      followerState: json['followerState'] != null
          ? FollowerState.fromJson(json['followerState'] as Map<String, dynamic>)
          : null,
      leaderCommission: (json['leaderCommission'] as num?)?.toDouble() ?? 0.0,
      leaderFraction: (json['leaderFraction'] as num?)?.toDouble() ?? 0.0,
      maxDistributable: (json['maxDistributable'] as num?)?.toDouble() ?? 0.0,
      maxWithdrawable: (json['maxWithdrawable'] as num?)?.toDouble() ?? 0.0,
      isClosed: json['isClosed'] as bool? ?? false,
      relationship: json['relationship'] != null
          ? VaultRelationship.fromJson(json['relationship'] as Map<String, dynamic>)
          : null,
      allowDeposits: json['allowDeposits'] as bool? ?? true,
      alwaysCloseOnWithdraw: json['alwaysCloseOnWithdraw'] as bool? ?? false,
    );
  }
}

/// Lightweight vault summary information.
class VaultSummary {
  /// Vault name
  final String name;

  /// Vault address
  final String vaultAddress;

  /// Vault leader address
  final String leader;

  /// Total value locked
  final String tvl;

  /// Whether vault is closed
  final bool isClosed;

  /// Vault relationship (parent/child structure)
  final VaultRelationship relationship;

  /// Vault creation timestamp (milliseconds)
  final int createTimeMillis;

  const VaultSummary({
    required this.name,
    required this.vaultAddress,
    required this.leader,
    required this.tvl,
    required this.isClosed,
    required this.relationship,
    required this.createTimeMillis,
  });

  factory VaultSummary.fromJson(Map<String, dynamic> json) {
    return VaultSummary(
      name: json['name'] as String,
      vaultAddress: json['vaultAddress'] as String,
      leader: json['leader'] as String,
      tvl: json['tvl'] as String? ?? '0',
      isClosed: json['isClosed'] as bool? ?? false,
      relationship: VaultRelationship.fromJson(
          json['relationship'] as Map<String, dynamic>? ?? {'type': 'normal'}),
      createTimeMillis: json['createTimeMillis'] as int? ?? 0,
    );
  }
}

/// Vault information for vaults managed by a specific leader.
/// Note: The API currently only returns address and name fields.
class LeadingVault {
  /// Vault address
  final String vaultAddress;

  /// Vault name
  final String name;

  const LeadingVault({
    required this.vaultAddress,
    required this.name,
  });

  factory LeadingVault.fromJson(Map<String, dynamic> json) {
    return LeadingVault(
      // API returns 'address' not 'vaultAddress'
      vaultAddress: json['address'] as String? ?? json['vaultAddress'] as String,
      name: json['name'] as String,
    );
  }
}

/// User's vault equity position.
class UserVaultEquity {
  /// Vault address
  final String vaultAddress;

  /// User's equity in this vault
  final String equity;

  const UserVaultEquity({
    required this.vaultAddress,
    required this.equity,
  });

  factory UserVaultEquity.fromJson(Map<String, dynamic> json) {
    return UserVaultEquity(
      vaultAddress: json['vaultAddress'] as String,
      equity: json['equity'] as String,
    );
  }
}
