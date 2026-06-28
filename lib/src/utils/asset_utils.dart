/// Utilities for converting coin symbols to Hyperliquid asset IDs.
///
/// Handles both regular perpetuals (index in universe) and HIP-3
/// builder-deployed perpetuals (format: "dex:asset").
library;

/// Check if a coin symbol is a HIP-3 perpetual (format: "dex:asset").
bool isHip3CoinSymbol(String coinSymbol) => coinSymbol.contains(':');

/// Parse a HIP-3 coin symbol into its dex and asset components.
///
/// Returns `null` if the format is invalid.
({String dex, String asset})? parseHip3CoinSymbol(String coinSymbol) {
  final parts = coinSymbol.split(':');
  if (parts.length != 2) return null;
  return (dex: parts[0], asset: parts[1]);
}

/// Get the asset ID for a regular perpetual by looking up its index in the
/// universe array.
///
/// Returns `null` if the coin is not found.
int? getRegularAssetId(String coinSymbol, List<String> universeNames) {
  final index = universeNames.indexOf(coinSymbol);
  return index == -1 ? null : index;
}

/// Get the asset ID for a HIP-3 builder-deployed perpetual.
///
/// Asset ID = 100000 + (perp_dex_index * 10000) + index_in_meta
///
/// [perpDexIndex] is the index of the deploying DEX.
/// [metaIndex] is the index of the asset within that DEX's metadata.
int getHip3AssetId({required int perpDexIndex, required int metaIndex}) {
  return 100000 + (perpDexIndex * 10000) + metaIndex;
}

/// Get the HIP-4 outcome encoding for an outcome id and binary side.
///
/// `side` must be 0 or 1. The same encoding is used in the outcome spot coin,
/// token name, and asset id representations.
int getOutcomeEncoding({required int outcome, required int side}) {
  if (side != 0 && side != 1) {
    throw RangeError.range(side, 0, 1, 'side');
  }
  return 10 * outcome + side;
}

/// Get the HIP-4 outcome spot coin name, e.g. `#10`.
String getOutcomeSpotCoin({required int outcome, required int side}) {
  return '#${getOutcomeEncoding(outcome: outcome, side: side)}';
}

/// Get the HIP-4 outcome token name, e.g. `+10`.
String getOutcomeTokenName({required int outcome, required int side}) {
  return '+${getOutcomeEncoding(outcome: outcome, side: side)}';
}

/// Get the HIP-4 outcome asset id for orders and cancels.
///
/// Asset ID = 100000000 + (10 * outcome + side).
int getOutcomeAssetId({required int outcome, required int side}) {
  return 100000000 + getOutcomeEncoding(outcome: outcome, side: side);
}

/// Resolve an asset ID for any coin symbol (regular or HIP-3).
///
/// For regular perpetuals, looks up the coin in [universeNames].
/// For HIP-3 perpetuals, currently returns `null` (requires DEX metadata
/// lookup that the caller must provide).
int? resolveAssetId(String coinSymbol, List<String> universeNames) {
  if (isHip3CoinSymbol(coinSymbol)) {
    // HIP-3 resolution requires external DEX metadata — caller must use
    // getHip3AssetId directly with the correct indices.
    return null;
  }
  return getRegularAssetId(coinSymbol, universeNames);
}
