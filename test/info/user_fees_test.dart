@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('UserFees integration', () {
    late InfoClient info;
    late String userAddress;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();
      info = InfoClient(isTestnet: false);
    });

    tearDownAll(() {
      info.close();
    });

    test('fetches user fee structure', () async {
      final fees = await info.userFees(userAddress);

      expect(fees, isA<UserFees>());
      expect(fees.userCrossRate, isNotEmpty);
      expect(fees.userAddRate, isNotEmpty);
      expect(fees.userSpotCrossRate, isNotEmpty);
      expect(fees.userSpotAddRate, isNotEmpty);
      expect(fees.dailyUserVlm, isA<List<DailyUserVolume>>());

      print('✓ Fee structure retrieved');
      print('  Perp taker fee: ${fees.userCrossRate}');
      print('  Perp maker rebate: ${fees.userAddRate}');
      print('  Spot taker fee: ${fees.userSpotCrossRate}');
      print('  Spot maker rebate: ${fees.userSpotAddRate}');

      if (fees.activeReferralDiscount != null) {
        print('  Referral discount: ${fees.activeReferralDiscount}');
      }

      if (fees.activeStakingDiscount != null) {
        print(
            '  Staking discount: ${fees.activeStakingDiscount!.discount} (${fees.activeStakingDiscount!.bpsOfMaxSupply} bps of max supply)');
      }

      if (fees.trial != null) {
        final endDate =
            DateTime.fromMillisecondsSinceEpoch(fees.trial!.endTimestamp);
        print('  Fee trial active until: $endDate');
      }

      if (fees.dailyUserVlm.isNotEmpty) {
        print('\n  Recent trading volume (last ${fees.dailyUserVlm.length} days):');
        for (var i = 0;
            i < fees.dailyUserVlm.length && i < 5;
            i++) {
          final vol = fees.dailyUserVlm[i];
          print(
              '    ${vol.date}: Taker=${vol.userCross}, Maker=${vol.userAdd}');
        }
      }
    });

    test('validates fee structure types', () async {
      final fees = await info.userFees(userAddress);

      // Validate rate format (should be decimal strings like "0.0002")
      final crossRate = double.tryParse(fees.userCrossRate);
      expect(crossRate, isNotNull);
      expect(crossRate! >= 0, true);

      final addRate = double.tryParse(fees.userAddRate);
      expect(addRate, isNotNull);

      // Validate volume history
      for (final vol in fees.dailyUserVlm) {
        expect(vol.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        final userCross = double.tryParse(vol.userCross);
        expect(userCross, isNotNull);
        expect(userCross! >= 0, true);

        final userAdd = double.tryParse(vol.userAdd);
        expect(userAdd, isNotNull);
        expect(userAdd! >= 0, true);

        final exchange = double.tryParse(vol.exchange);
        expect(exchange, isNotNull);
        expect(exchange! >= 0, true);
      }

      print('✓ All fee structure types validated');
    });

    test('handles zero-volume user gracefully', () async {
      // Test with a random address that likely has no volume
      final randomAddress = '0x0000000000000000000000000000000000000001';
      final fees = await info.userFees(randomAddress);

      expect(fees, isA<UserFees>());
      expect(fees.userCrossRate, isNotEmpty);
      expect(fees.userAddRate, isNotEmpty);

      print('✓ Zero-volume user handled correctly');
      print('  Default taker fee: ${fees.userCrossRate}');
      print('  Default maker rebate: ${fees.userAddRate}');
    });
  });
}
