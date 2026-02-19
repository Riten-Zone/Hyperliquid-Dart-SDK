/// Shared types used across the Hyperliquid SDK.
library;

/// Order side.
enum Side {
  /// Buy / Long.
  buy,

  /// Sell / Short.
  sell;

  /// Convert to the boolean representation used by Hyperliquid (true = buy).
  bool get asBool => this == Side.buy;

  /// Create from boolean (true = buy, false = sell).
  static Side fromBool(bool isBuy) => isBuy ? Side.buy : Side.sell;

  /// Create from Hyperliquid's string representation ('A' = sell, 'B' = buy).
  static Side fromHyperliquid(String s) => s == 'B' ? Side.buy : Side.sell;
}

/// Time-in-force for limit orders.
enum TimeInForce {
  /// Good 'til cancelled.
  gtc('Gtc'),

  /// Immediate or cancel.
  ioc('Ioc'),

  /// Add liquidity only (post-only).
  alo('Alo');

  const TimeInForce(this.value);

  /// The string value sent to the Hyperliquid API.
  final String value;
}

/// Take-profit / stop-loss type.
enum TpslType {
  tp('tp'),
  sl('sl');

  const TpslType(this.value);
  final String value;
}

/// Leverage mode.
enum MarginMode {
  cross,
  isolated;

  /// Whether this is cross margin.
  bool get isCross => this == MarginMode.cross;
}

/// Parsed signature components from an EIP-712 signature.
class SignatureComponents {
  final String r;
  final String s;
  final int v;

  const SignatureComponents({
    required this.r,
    required this.s,
    required this.v,
  });

  Map<String, dynamic> toJson() => {'r': r, 's': s, 'v': v};
}

/// Builder fee configuration for order placement.
class BuilderFee {
  /// Builder address (will be lowercased).
  final String address;

  /// Fee rate in tenths of a basis point (e.g. 10 = 1bp = 0.01%).
  final int feeRate;

  const BuilderFee({required this.address, required this.feeRate});

  /// Serialize to the wire format expected by Hyperliquid.
  Map<String, dynamic> toWire() => {
        'b': address.toLowerCase(),
        'f': feeRate,
      };
}
