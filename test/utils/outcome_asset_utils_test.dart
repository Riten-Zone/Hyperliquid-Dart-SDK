import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HIP-4 outcome asset helpers', () {
    test('builds official outcome encodings and asset representations', () {
      expect(getOutcomeEncoding(outcome: 1, side: 0), 10);
      expect(getOutcomeEncoding(outcome: 1, side: 1), 11);
      expect(getOutcomeSpotCoin(outcome: 1, side: 0), '#10');
      expect(getOutcomeTokenName(outcome: 1, side: 0), '+10');
      expect(getOutcomeAssetId(outcome: 1, side: 0), 100000010);
    });

    test('rejects invalid outcome sides', () {
      expect(() => getOutcomeEncoding(outcome: 1, side: 2), throwsRangeError);
    });
  });
}
