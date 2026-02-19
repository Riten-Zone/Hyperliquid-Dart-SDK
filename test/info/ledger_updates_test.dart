@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('LedgerUpdates integration', () {
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

    test('fetches ledger updates for past 30 days', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final updates = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: thirtyDaysAgo,
        endTime: now,
      );

      expect(updates, isA<List<LedgerUpdate>>());

      print('✓ Found ${updates.length} ledger updates in past 30 days');

      if (updates.isEmpty) {
        print('  No ledger activity (expected for new accounts)');
        return;
      }

      // Group by type
      final byType = <String, int>{};
      for (final update in updates) {
        byType[update.delta.type] = (byType[update.delta.type] ?? 0) + 1;
      }

      print('\n  Update types:');
      for (final entry in byType.entries) {
        print('    ${entry.key}: ${entry.value}');
      }

      // Show recent updates
      print('\n  Recent updates (last 5):');
      final recent = updates.take(5).toList();
      for (var i = 0; i < recent.length; i++) {
        final update = recent[i];
        final date = DateTime.fromMillisecondsSinceEpoch(update.time);
        final type = update.delta.type;

        String detail = '';
        switch (type) {
          case 'deposit':
          case 'withdraw':
            detail = update.delta.usdc ?? 'N/A';
            break;
          case 'accountClassTransfer':
            final direction = update.delta.toPerp == true ? 'spot→perp' : 'perp→spot';
            detail = '${update.delta.usdc} USDC ($direction)';
            break;
          case 'internalTransfer':
            detail =
                '${update.delta.usdc} USDC to ${update.delta.destination?.substring(0, 10)}...';
            break;
          case 'spotTransfer':
            detail = '${update.delta.amount} ${update.delta.token}';
            break;
          default:
            detail = 'See delta for details';
        }

        print('    ${i + 1}. $date - $type: $detail');
      }
    });

    test('validates ledger update structure', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);

      final updates = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: sevenDaysAgo,
        endTime: now,
      );

      if (updates.isEmpty) {
        print('✓ No ledger updates to validate (skipping validation)');
        return;
      }

      for (final update in updates) {
        // Validate required fields
        expect(update.time, greaterThan(0));
        expect(update.hash, isNotEmpty);
        expect(update.delta, isA<LedgerDelta>());
        expect(update.delta.type, isNotEmpty);

        // Validate timestamp is within range
        expect(update.time, greaterThanOrEqualTo(sevenDaysAgo));
        expect(update.time, lessThanOrEqualTo(now));

        // Validate hash format (should be 0x followed by hex)
        expect(update.hash, matches(RegExp(r'^0x[a-fA-F0-9]+$')));
      }

      print('✓ All ${updates.length} ledger updates have valid structure');
    });

    test('handles different delta types correctly', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final ninetyDaysAgo = now - (90 * 24 * 60 * 60 * 1000);

      final updates = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: ninetyDaysAgo,
        endTime: now,
      );

      if (updates.isEmpty) {
        print('✓ No ledger updates (expected for new accounts)');
        return;
      }

      final deltaTypes = updates.map((u) => u.delta.type).toSet();

      print('✓ Found ${deltaTypes.length} different delta types:');
      for (final type in deltaTypes) {
        final count = updates.where((u) => u.delta.type == type).length;
        print('  - $type: $count occurrences');

        // Show sample for each type
        final sample = updates.firstWhere((u) => u.delta.type == type);
        final delta = sample.delta;

        String sampleData = '';
        if (delta.usdc != null) sampleData += 'usdc=${delta.usdc} ';
        if (delta.token != null) sampleData += 'token=${delta.token} ';
        if (delta.amount != null) sampleData += 'amount=${delta.amount} ';
        if (delta.toPerp != null) sampleData += 'toPerp=${delta.toPerp} ';

        if (sampleData.isNotEmpty) {
          print('    Sample: $sampleData');
        }
      }
    });

    test('respects time range filtering', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneDayAgo = now - (24 * 60 * 60 * 1000);

      final updates = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: oneDayAgo,
        endTime: now,
      );

      // All updates should be within the specified range
      for (final update in updates) {
        expect(update.time, greaterThanOrEqualTo(oneDayAgo));
        expect(update.time, lessThanOrEqualTo(now));
      }

      print('✓ Time range filtering works correctly (${updates.length} updates in past 24h)');
    });

    test('works without endTime parameter', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final threeDaysAgo = now - (3 * 24 * 60 * 60 * 1000);

      // Call without endTime - should default to now
      final updates = await info.userNonFundingLedgerUpdates(
        user: userAddress,
        startTime: threeDaysAgo,
      );

      expect(updates, isA<List<LedgerUpdate>>());

      // Updates should not be in the future
      for (final update in updates) {
        expect(update.time, lessThanOrEqualTo(now + 60000)); // Allow 1min tolerance
      }

      print('✓ Works without endTime (${updates.length} updates)');
    });
  });
}
