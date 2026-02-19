/// Types for Hyperliquid Exchange API requests and responses.
library;

import 'common_types.dart';

/// Response from the Hyperliquid exchange endpoint.
class ExchangeResponse {
  final String status;
  final dynamic response;

  const ExchangeResponse({required this.status, this.response});

  bool get isOk => status == 'ok';
  bool get isError => status == 'err';

  /// Extract error message from various response formats.
  String? get errorMessage {
    if (isOk) return null;
    if (response is String) return response as String;
    if (response is Map<String, dynamic>) {
      final map = response as Map<String, dynamic>;
      return map['error'] as String? ??
          map['errorText'] as String? ??
          map['message'] as String?;
    }
    return response?.toString();
  }

  factory ExchangeResponse.fromJson(Map<String, dynamic> json) {
    return ExchangeResponse(
      status: json['status'] as String,
      response: json['response'],
    );
  }
}

/// Wire format for a single order (field order is critical for msgpack).
///
/// Fields MUST be in order: a, b, p, s, r, t
/// This matches the Python SDK's `order_request_to_order_wire`.
class OrderWire {
  /// Asset ID.
  final int asset;

  /// Buy (true) or sell (false).
  final bool isBuy;

  /// Limit price as string.
  final String limitPx;

  /// Size as string.
  final String sz;

  /// Reduce only.
  final bool reduceOnly;

  /// Order type (limit, market, or trigger).
  final Map<String, dynamic> orderType;

  const OrderWire({
    required this.asset,
    required this.isBuy,
    required this.limitPx,
    required this.sz,
    required this.reduceOnly,
    required this.orderType,
  });

  /// Serialize to the wire format with correct field ordering.
  Map<String, dynamic> toWire() => {
        'a': asset,
        'b': isBuy,
        'p': limitPx,
        's': sz,
        'r': reduceOnly,
        't': orderType,
      };

  /// Create a limit order wire.
  factory OrderWire.limit({
    required int asset,
    required bool isBuy,
    required String limitPx,
    required String sz,
    bool reduceOnly = false,
    TimeInForce tif = TimeInForce.gtc,
  }) {
    return OrderWire(
      asset: asset,
      isBuy: isBuy,
      limitPx: limitPx,
      sz: sz,
      reduceOnly: reduceOnly,
      orderType: {
        'limit': {'tif': tif.value}
      },
    );
  }

  /// Create a market order wire.
  ///
  /// Note: For market orders, [limitPx] should be set to a price with
  /// appropriate slippage applied.
  factory OrderWire.market({
    required int asset,
    required bool isBuy,
    required String limitPx,
    required String sz,
    bool reduceOnly = false,
  }) {
    return OrderWire(
      asset: asset,
      isBuy: isBuy,
      limitPx: limitPx,
      sz: sz,
      reduceOnly: reduceOnly,
      orderType: {'market': {}},
    );
  }

  /// Create a trigger (TP/SL) order wire.
  ///
  /// Field order in trigger MUST be: isMarket, triggerPx, tpsl
  factory OrderWire.trigger({
    required int asset,
    required bool isBuy,
    required String limitPx,
    required String sz,
    required String triggerPx,
    required TpslType tpsl,
    bool isMarket = true,
    bool reduceOnly = true,
  }) {
    return OrderWire(
      asset: asset,
      isBuy: isBuy,
      limitPx: limitPx,
      sz: sz,
      reduceOnly: reduceOnly,
      orderType: {
        'trigger': {
          'isMarket': isMarket,
          'triggerPx': triggerPx,
          'tpsl': tpsl.value,
        }
      },
    );
  }
}

/// Cancel request wire format.
class CancelWire {
  final int asset;
  final int oid;

  const CancelWire({required this.asset, required this.oid});

  Map<String, dynamic> toWire() => {'a': asset, 'o': oid};
}

/// Modify request wire format.
class ModifyWire {
  final int oid;
  final OrderWire order;

  const ModifyWire({required this.oid, required this.order});

  Map<String, dynamic> toWire() {
    return {
      'oid': oid,
      'order': order.toWire(),
    };
  }
}

/// TWAP (Time-Weighted Average Price) order wire format.
class TwapWire {
  /// Asset ID.
  final int asset;

  /// Buy (true) or sell (false).
  final bool isBuy;

  /// Total size to execute as string.
  final String sz;

  /// Reduce only.
  final bool reduceOnly;

  /// Duration in minutes (1-1440).
  final int durationMins;

  /// Randomize execution timing (false = evenly spaced, true = randomized).
  final bool randomize;

  const TwapWire({
    required this.asset,
    required this.isBuy,
    required this.sz,
    required this.durationMins,
    this.reduceOnly = false,
    this.randomize = false,
  });

  Map<String, dynamic> toWire() {
    return {
      'a': asset,
      'b': isBuy,
      's': sz,
      'r': reduceOnly,
      'm': durationMins,
      't': randomize,
    };
  }
}

/// TWAP cancel request wire format.
class TwapCancelWire {
  /// Asset ID.
  final int asset;

  /// TWAP ID to cancel.
  final int twapId;

  const TwapCancelWire({required this.asset, required this.twapId});

  Map<String, dynamic> toWire() => {'a': asset, 't': twapId};
}

/// Order grouping type.
enum OrderGrouping {
  /// No grouping.
  na('na'),

  /// Normal TP/SL grouping (main order + TP + SL in one tx).
  normalTpsl('normalTpsl'),

  /// Position TP/SL grouping.
  positionTpsl('positionTpsl');

  const OrderGrouping(this.value);
  final String value;
}
