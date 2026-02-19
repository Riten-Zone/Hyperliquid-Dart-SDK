import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Example: Trading HIP-3 builder-deployed perpetuals
///
/// Demonstrates how to:
/// 1. List available HIP-3 DEXs
/// 2. Get metadata for a specific DEX
/// 3. Calculate HIP-3 asset IDs
/// 4. Place orders on HIP-3 perpetuals
void main() async {
  // Create clients
  final info = InfoClient();
  final wallet = PrivateKeyWalletAdapter('0xYOUR_PRIVATE_KEY');
  final exchange = ExchangeClient(wallet: wallet);

  try {
    // 1. Get list of HIP-3 DEXs
    print('=== Available HIP-3 DEXs ===');
    final dexs = await info.perpDexs();
    for (final dex in dexs) {
      print('${dex.name} (${dex.fullName})');
      print('  Assets: ${dex.assetToStreamingOiCap.length}');
      print('  Note: perpDexs() does not include collateral token. Use meta(dex) to get it.');
    }

    if (dexs.isEmpty) {
      print('No HIP-3 DEXs available');
      return;
    }

    // 2. Get metadata for first DEX
    final targetDex = dexs.first.name;
    print('\n=== Metadata for DEX: $targetDex ===');
    final meta = await info.meta(dex: targetDex);
    final collateralInfo = meta.collateralToken == 0
        ? 'Perp USDC (native margin, same as regular Hyperliquid perps)'
        : 'Spot token ID ${meta.collateralToken} (requires spot token balance)';
    print('Collateral: $collateralInfo');
    print('Assets:');
    for (final asset in meta.universe) {
      print(
          '  ${asset.name}: ${asset.szDecimals} decimals, ${asset.maxLeverage}x max leverage');
    }

    // 3. Calculate HIP-3 asset ID
    // Asset ID = 100000 + (perp_dex_index * 10000) + index_in_meta
    final perpDexIndex = 0; // First DEX in the list
    final assetIndex = 0; // First asset in the DEX's universe
    final assetId = getHip3AssetId(
      perpDexIndex: perpDexIndex,
      metaIndex: assetIndex,
    );
    print('\nAsset ID for ${meta.universe.first.name}: $assetId');

    // 4. Place a limit order on HIP-3 perpetual
    // IMPORTANT: Check the collateral token requirement:
    // - Token 0 = Perp USDC (native margin, same as regular perps)
    // - Token >0 = Spot token (you need that specific spot token balance)
    print('\n=== Placing HIP-3 Order ===');
    if (meta.collateralToken == 0) {
      print('NOTE: This DEX uses Perp USDC (native margin token)\n');
    } else {
      print('NOTE: This DEX requires spot token ID ${meta.collateralToken} as collateral\n');
    }
    final result = await exchange.placeOrder(
      orders: [
        OrderWire.limit(
          asset: assetId, // HIP-3 asset ID
          isBuy: true,
          limitPx: '100.0', // Adjust based on current price
          sz: '1.0', // Adjust based on szDecimals
          tif: TimeInForce.gtc,
        ),
      ],
    );
    print('Order result: ${result.status}');
    if (result.response != null && result.response!.data != null) {
      print('Response: ${result.response!.data}');
    }
  } finally {
    info.close();
    exchange.close();
  }
}
