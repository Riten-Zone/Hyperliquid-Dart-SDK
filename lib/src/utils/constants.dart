/// Hyperliquid API constants and configuration.
library;

/// Base URLs for Hyperliquid API endpoints.
class HyperliquidUrls {
  /// Mainnet info endpoint (read-only queries).
  static const String mainnetInfo = 'https://api.hyperliquid.xyz/info';

  /// Mainnet exchange endpoint (signed actions).
  static const String mainnetExchange = 'https://api.hyperliquid.xyz/exchange';

  /// Mainnet WebSocket endpoint.
  static const String mainnetWs = 'wss://api.hyperliquid.xyz/ws';

  /// Testnet info endpoint.
  static const String testnetInfo =
      'https://api.hyperliquid-testnet.xyz/info';

  /// Testnet exchange endpoint.
  static const String testnetExchange =
      'https://api.hyperliquid-testnet.xyz/exchange';

  /// Testnet WebSocket endpoint.
  static const String testnetWs = 'wss://api.hyperliquid-testnet.xyz/ws';

  /// Get info URL for the given network.
  static String infoUrl({bool isTestnet = false}) =>
      isTestnet ? testnetInfo : mainnetInfo;

  /// Get exchange URL for the given network.
  static String exchangeUrl({bool isTestnet = false}) =>
      isTestnet ? testnetExchange : mainnetExchange;

  /// Get WebSocket URL for the given network.
  static String wsUrl({bool isTestnet = false}) =>
      isTestnet ? testnetWs : mainnetWs;
}

/// EIP-712 signing constants for Hyperliquid.
class HyperliquidEip712 {
  /// Domain name used in EIP-712 signing for L1 actions.
  static const String domainName = 'Exchange';

  /// Domain version.
  static const String domainVersion = '1';

  /// Chain ID used by Hyperliquid (always 1337).
  static const int chainId = 1337;

  /// Verifying contract (zero address).
  static const String verifyingContract =
      '0x0000000000000000000000000000000000000000';

  /// Source identifier for mainnet.
  static const String mainnetSource = 'a';

  /// Source identifier for testnet.
  static const String testnetSource = 'b';

  /// Domain name for user-signed actions (e.g. approveBuilderFee).
  static const String userSignedDomainName = 'HyperliquidSignTransaction';

  /// Arbitrum One chain ID (used for user-signed actions).
  static const int arbitrumChainId = 42161;

  /// Get the source string for the given network.
  static String source({bool isTestnet = false}) =>
      isTestnet ? testnetSource : mainnetSource;
}

/// Candle interval strings accepted by the Hyperliquid API.
class CandleIntervals {
  static const String m1 = '1m';
  static const String m3 = '3m';
  static const String m5 = '5m';
  static const String m15 = '15m';
  static const String m30 = '30m';
  static const String h1 = '1h';
  static const String h2 = '2h';
  static const String h4 = '4h';
  static const String h8 = '8h';
  static const String h12 = '12h';
  static const String d1 = '1d';
  static const String d3 = '3d';
  static const String w1 = '1w';
  static const String month1 = '1M';

  /// All valid intervals.
  static const List<String> all = [
    m1, m3, m5, m15, m30,
    h1, h2, h4, h8, h12,
    d1, d3, w1, month1,
  ];

  /// Map interval string to approximate duration in seconds.
  static const Map<String, int> durationSeconds = {
    '1m': 60,
    '3m': 180,
    '5m': 300,
    '15m': 900,
    '30m': 1800,
    '1h': 3600,
    '2h': 7200,
    '4h': 14400,
    '8h': 28800,
    '12h': 43200,
    '1d': 86400,
    '3d': 259200,
    '1w': 604800,
    '1M': 2592000,
  };
}
