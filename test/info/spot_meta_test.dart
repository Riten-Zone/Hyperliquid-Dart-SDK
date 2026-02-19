@Tags(['integration'])
library;

import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Spot market integration', () {
    late InfoClient info;

    setUpAll(() {
      info = InfoClient(isTestnet: false);
    });

    tearDownAll(() {
      info.close();
    });

    test('fetches spot metadata', () async {
      final spotMeta = await info.spotMeta();

      expect(spotMeta.universe, isNotEmpty);
      expect(spotMeta.tokens, isNotEmpty);

      final firstToken = spotMeta.tokens.first;
      expect(firstToken.name, isNotEmpty);
      expect(firstToken.tokenId, startsWith('0x'));
      expect(firstToken.tokenId.length, 34); // "0x" + 32 hex chars
      expect(firstToken.szDecimals, greaterThan(0));
      expect(firstToken.weiDecimals, greaterThan(0));

      print('✓ Spot tokens: ${spotMeta.tokens.length}');
      print('  Sample: ${firstToken.name} (${firstToken.tokenId})');
    });

    test('fetches spot metadata and asset contexts', () async {
      final combined = await info.spotMetaAndAssetCtxs();

      expect(combined.meta.tokens, isNotEmpty);
      expect(combined.assetCtxs, isNotEmpty);

      final firstCtx = combined.assetCtxs.first;
      expect(firstCtx.coin, isNotEmpty);
      expect(firstCtx.markPx, isNotEmpty);
      expect(double.parse(firstCtx.markPx), greaterThan(0));
      expect(firstCtx.circulatingSupply, isNotEmpty);

      print('✓ Asset contexts: ${combined.assetCtxs.length}');
      print('  Sample: ${firstCtx.coin} @ \$${firstCtx.markPx}');
      print('  Volume (24h): ${firstCtx.dayNtlVlm}');
    });

    test('fetches token details', () async {
      // First get a token ID from spotMeta
      final spotMeta = await info.spotMeta();
      expect(spotMeta.tokens, isNotEmpty);

      final tokenId = spotMeta.tokens.first.tokenId;
      expect(tokenId, startsWith('0x'));

      final details = await info.tokenDetails(tokenId);

      // Validate structure and required fields
      expect(details.name, isNotEmpty);
      expect(details.maxSupply, isNotEmpty);
      expect(details.totalSupply, isNotEmpty);
      expect(details.circulatingSupply, isNotEmpty);
      expect(details.szDecimals, isA<int>());
      expect(details.weiDecimals, isA<int>());
      expect(details.markPx, isNotEmpty);
      expect(details.seededUsdc, isNotEmpty);
      expect(details.futureEmissions, isNotEmpty);

      print('✓ Token: ${details.name}');
      print('  Supply: ${details.circulatingSupply}/${details.maxSupply}');
      print('  Mark Price: \$${details.markPx}');
      print('  Decimals: sz=${details.szDecimals}, wei=${details.weiDecimals}');
    });

    test('spot metadata and asset contexts have valid structure', () async {
      final combined = await info.spotMetaAndAssetCtxs();

      // Validate metadata structure
      final tokenCount = combined.meta.tokens.length;
      final ctxCount = combined.assetCtxs.length;

      print('Tokens: $tokenCount, Contexts: $ctxCount');

      // Should have both tokens and contexts
      expect(tokenCount, greaterThan(0));
      expect(ctxCount, greaterThan(0));

      // Validate asset context structure
      for (final ctx in combined.assetCtxs.take(3)) {
        expect(ctx.coin, isNotEmpty);
        expect(ctx.markPx, isNotEmpty);
        expect(ctx.prevDayPx, isNotEmpty);
        expect(ctx.dayNtlVlm, isNotEmpty);
        expect(ctx.circulatingSupply, isNotEmpty);
        expect(ctx.totalSupply, isNotEmpty);
        expect(ctx.dayBaseVlm, isNotEmpty);
      }

      print('✓ Spot metadata and asset contexts have valid structure');
    });
  });
}
