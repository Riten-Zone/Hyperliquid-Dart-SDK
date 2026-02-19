@Tags(['integration'])
library;

import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HIP-3 PerpDexs integration', () {
    late InfoClient info;

    setUpAll(() async {
      info = InfoClient(isTestnet: false);
    });

    tearDownAll(() {
      info.close();
    });

    test('fetches all HIP-3 DEXs', () async {
      final dexs = await info.perpDexs();

      // Should have at least some DEXs (as of Feb 2026)
      expect(dexs, isA<List<PerpDex>>());
      expect(dexs.length, greaterThan(0));

      print('✓ Found ${dexs.length} HIP-3 DEXs\n');

      // Print all DEXs and their assets
      for (var i = 0; i < dexs.length; i++) {
        final dex = dexs[i];
        expect(dex.name, isNotEmpty);
        expect(dex.fullName, isNotEmpty);
        expect(dex.deployer, startsWith('0x'));
        expect(dex.assetToStreamingOiCap, isA<Map<String, String>>());
        expect(dex.assetToFundingMultiplier, isA<Map<String, String>>());

        print('  ${i + 1}. ${dex.name} (${dex.fullName})');
        print('     Deployer: ${dex.deployer}');
        print(
            '     Collateral: ${dex.getCollateralSymbol()}${dex.collateralToken != null ? ' (token ID: ${dex.collateralToken}${dex.collateralToken == 0 ? ' - native margin' : ' - spot token'})' : ' (not specified)'}');
        print('     Assets (${dex.assetToStreamingOiCap.length}):');

        if (dex.assetToStreamingOiCap.isEmpty) {
          print('       (No assets)');
        } else {
          final assets = dex.assetToStreamingOiCap.keys.toList()..sort();
          for (var j = 0; j < assets.length; j++) {
            final asset = assets[j];
            final cap = dex.assetToStreamingOiCap[asset];
            print('       ${j + 1}. $asset (OI Cap: $cap)');
          }
        }

        if (i < dexs.length - 1) print('');
      }
    });

    test('fetches metadata for specific HIP-3 DEX', () async {
      // Get list of DEXs first
      final dexs = await info.perpDexs();
      if (dexs.isEmpty) {
        print('⚠ Skipping - no HIP-3 DEXs available');
        return;
      }

      final dexName = dexs.first.name;
      print('Testing with DEX: $dexName');

      // Fetch metadata for that DEX
      final meta = await info.meta(dex: dexName);
      expect(meta, isA<Meta>());
      expect(meta.universe, isA<List<AssetMetadata>>());
      expect(meta.universe.length, greaterThan(0));
      expect(meta.collateralToken, isA<int?>());

      // Validate structure
      final firstAsset = meta.universe.first;
      expect(firstAsset.name, isNotEmpty);
      expect(firstAsset.szDecimals, greaterThanOrEqualTo(0));
      expect(firstAsset.maxLeverage, greaterThan(0));

      print('✓ DEX $dexName has ${meta.universe.length} assets');
      print(
          '  Collateral token: ${meta.collateralToken} (${meta.collateralToken != null ? _getTokenSymbol(meta.collateralToken!) : 'not specified'})');
      print(
          '  Sample asset: ${firstAsset.name} (${firstAsset.szDecimals} decimals, ${firstAsset.maxLeverage}x max leverage)');
    });

    test('fetches metadata and contexts for HIP-3 DEX', () async {
      final dexs = await info.perpDexs();
      if (dexs.isEmpty) {
        print('⚠ Skipping - no HIP-3 DEXs available');
        return;
      }

      final dexName = dexs.first.name;
      final data = await info.metaAndAssetCtxs(dex: dexName);

      expect(data.universe, isA<List<AssetMetadata>>());
      expect(data.assetCtxs, isA<List<AssetContext>>());
      expect(data.universe.length, equals(data.assetCtxs.length));

      if (data.universe.isNotEmpty) {
        final asset = data.universe.first;
        final ctx = data.assetCtxs.first;

        expect(asset.name, isNotEmpty);
        expect(ctx.funding, isNotEmpty);
        expect(ctx.markPx, isNotEmpty);

        print('✓ DEX $dexName: ${data.universe.length} assets with contexts');
        print(
            '  Sample: ${asset.name} - Mark: ${ctx.markPx}, Funding: ${ctx.funding}');
      }
    });

    test('regular meta() still works without dex parameter', () async {
      // Ensure backward compatibility
      final meta = await info.meta();
      expect(meta, isA<Meta>());
      expect(meta.universe, isA<List<AssetMetadata>>());
      expect(meta.universe.length, greaterThan(0)); // Should have regular perps
      expect(meta.collateralToken, isA<int?>()); // May be 0 for USDC or null

      print('✓ Regular perpetuals: ${meta.universe.length} assets');
      print(
          '  Collateral token: ${meta.collateralToken != null ? '${meta.collateralToken} (${_getTokenSymbol(meta.collateralToken!)})' : 'not specified'}');
    });
  });
}

/// Helper to map token ID to symbol
/// IMPORTANT: Token 0 is Perp USDC (native margin), not spot USDC!
String _getTokenSymbol(int tokenId) {
  switch (tokenId) {
    case 0:
      return 'Perp USDC'; // Native margin token
    case 360:
      return 'USDH'; // Spot token
    case 2:
      return 'USDT'; // Spot token
    default:
      return 'Token $tokenId';
  }
}
