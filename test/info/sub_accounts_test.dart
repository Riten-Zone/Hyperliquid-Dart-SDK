@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('Sub-account integration', () {
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

    test('fetches user sub-accounts', () async {
      final subs = await info.subAccounts(userAddress);

      // May be empty if user has no sub-accounts
      expect(subs, isA<List<SubAccount>>());

      if (subs.isNotEmpty) {
        final first = subs.first;
        expect(first.name, isNotEmpty);
        expect(first.subAccountUser, startsWith('0x'));
        expect(first.master, equals(userAddress.toLowerCase()));
        expect(first.clearinghouseState, isA<ClearinghouseState>());
        expect(first.spotState, isA<SubAccountSpotState>());

        print('✓ Found ${subs.length} sub-accounts');
        print('  Sample: ${first.name} (${first.subAccountUser})');
        print('  Account Value: ${first.clearinghouseState.accountValue}');
      } else {
        print('✓ User has no sub-accounts (expected for test account)');
      }
    });

    test('sub-account structure is valid', () async {
      final subs = await info.subAccounts(userAddress);

      if (subs.isEmpty) {
        print('✓ Skipping validation - no sub-accounts');
        return;
      }

      for (final sub in subs) {
        // Validate required fields
        expect(sub.name, isNotEmpty);
        expect(sub.subAccountUser, matches(RegExp(r'^0x[a-fA-F0-9]{40}$')));
        expect(sub.master, matches(RegExp(r'^0x[a-fA-F0-9]{40}$')));

        // Validate nested structures
        expect(sub.clearinghouseState, isA<ClearinghouseState>());
        expect(sub.clearinghouseState.accountValue, isNotEmpty);
        expect(sub.spotState.balances, isA<List<SubAccountBalance>>());

        // Check spot balances if present
        if (sub.spotState.balances.isNotEmpty) {
          final balance = sub.spotState.balances.first;
          expect(balance.coin, isNotEmpty);
          expect(balance.total, isNotEmpty);
        }
      }

      print('✓ All ${subs.length} sub-accounts have valid structure');
    });
  });
}
