@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

/// To test with a real vault, set environment variables:
/// ```bash
/// export TEST_VAULT_ADDRESS=0xYOUR_VAULT_ADDRESS
/// export TEST_VAULT_LEADER=0xVAULT_LEADER_ADDRESS
/// dart test test/info/vault_info_test.dart
/// ```
///
/// Example with Hyperliquid Provider (HLP) vault:
/// ```bash
/// export TEST_VAULT_ADDRESS=0xdfc24b077bc1425ad1dea75bcb6f8158e10df303
/// export TEST_VAULT_LEADER=0x677d831aef5328190852e24f13c46cac05f984e7
/// dart test test/info/vault_info_test.dart
/// ```
///
/// Find vaults at: https://app.hyperliquid.xyz/vaults
/// See VAULT_REFERENCES.md for known vault addresses

void main() {
  group('Vault info integration', () {
    late InfoClient info;

    // Get vault addresses from environment
    final testVaultAddress = Platform.environment['TEST_VAULT_ADDRESS'];
    final testVaultLeader = Platform.environment['TEST_VAULT_LEADER'];

    setUpAll(() {
      info = InfoClient(isTestnet: false);
      if (testVaultAddress != null) {
        print('\n📊 Testing with vault: $testVaultAddress');
        if (testVaultLeader != null) {
          print('   Leader: $testVaultLeader');
        }
        print('');
      } else {
        print('\n⚠️  No TEST_VAULT_ADDRESS set - tests will check API availability');
        print('   To test with real data:');
        print('   1. Visit https://app.hyperliquid.xyz/vaults');
        print('   2. Copy a vault address and leader address');
        print('   3. Run:');
        print('      export TEST_VAULT_ADDRESS=0x...');
        print('      export TEST_VAULT_LEADER=0x...');
        print('   4. Run: dart test test/info/vault_info_test.dart\n');
      }
    });

    tearDownAll(() {
      info.close();
    });

    test('vaultSummaries() returns valid structure', () async {
      final summaries = await info.vaultSummaries();

      expect(summaries, isA<List<VaultSummary>>());

      if (summaries.isEmpty) {
        print('⚠️  vaultSummaries returned empty (known API issue)');
        print('   This endpoint often returns empty - use leadingVaults() instead');
      } else {
        print('✓ Found ${summaries.length} vaults');
        final first = summaries.first;
        expect(first.vaultAddress, startsWith('0x'));
        expect(first.vaultAddress.length, 42);
        expect(first.name, isNotEmpty);
        expect(first.leader, startsWith('0x'));
        expect(first.leader.length, 42);
        print('  Sample: ${first.name} (${first.vaultAddress})');
      }
    });

    test('vaultDetails() works with real vault address', () async {
      if (testVaultAddress == null) {
        print('⚠️  Skipping - no TEST_VAULT_ADDRESS set');
        print('   Set TEST_VAULT_ADDRESS env var to test this');
        return;
      }

      final details = await info.vaultDetails(
        vaultAddress: testVaultAddress,
      );

      // Validate structure
      expect(details.vaultAddress.toLowerCase(), equals(testVaultAddress.toLowerCase()));
      expect(details.name, isNotEmpty);
      expect(details.leader, startsWith('0x'));
      expect(details.leader.length, 42);
      expect(details.portfolio, isA<VaultPortfolio>());
      expect(details.apr, greaterThan(0.0));
      expect(details.followers, isA<List<VaultFollower>>());
      expect(details.leaderCommission, greaterThanOrEqualTo(0.0));

      print('✓ Vault: ${details.name}');
      print('  Leader: ${details.leader}');
      print('  APR: ${(details.apr * 100).toStringAsFixed(2)}%');
      print('  Commission: ${(details.leaderCommission * 100).toStringAsFixed(2)}%');
      print('  Followers: ${details.followers.length}');
      print('  Is Closed: ${details.isClosed}');

      // Validate portfolio structure
      expect(details.portfolio.day, isA<PortfolioPeriod>());
      expect(details.portfolio.week, isA<PortfolioPeriod>());
      expect(details.portfolio.month, isA<PortfolioPeriod>());
      expect(details.portfolio.allTime, isA<PortfolioPeriod>());
    });

    test('vaultDetails() with user parameter works', () async {
      if (testVaultAddress == null) {
        print('⚠️  Skipping - no TEST_VAULT_ADDRESS set');
        return;
      }

      // Use vault leader as test user
      final details = await info.vaultDetails(
        vaultAddress: testVaultAddress,
        user: testVaultLeader ?? testVaultAddress,
      );

      expect(details.vaultAddress.toLowerCase(), equals(testVaultAddress.toLowerCase()));
      expect(details.name, isNotEmpty);
      print('✓ Vault details with user parameter: ${details.name}');
    });

    test('leadingVaults() works with real leader address', () async {
      if (testVaultLeader == null) {
        print('⚠️  Skipping - no TEST_VAULT_LEADER set');
        print('   Set TEST_VAULT_LEADER env var to test this');
        return;
      }

      final vaults = await info.leadingVaults(testVaultLeader);

      expect(vaults, isA<List<LeadingVault>>());

      if (vaults.isEmpty) {
        print('⚠️  Leader has no vaults');
      } else {
        print('✓ Found ${vaults.length} vault(s) for leader');
        final first = vaults.first;
        expect(first.vaultAddress, startsWith('0x'));
        expect(first.vaultAddress.length, 42);
        expect(first.name, isNotEmpty);

        print('  Vault: ${first.name}');
        print('    Address: ${first.vaultAddress}');
      }
    });

    test('userVaultEquities() returns valid structure', () async {
      final testUser = testVaultLeader ?? '0x0000000000000000000000000000000000000000';

      final equities = await info.userVaultEquities(testUser);

      expect(equities, isA<List<UserVaultEquity>>());

      if (equities.isEmpty) {
        print('✓ User has no vault positions (expected for most users)');
      } else {
        print('✓ Found ${equities.length} vault position(s)');
        final first = equities.first;
        expect(first.vaultAddress, startsWith('0x'));
        expect(first.vaultAddress.length, 42);
        expect(first.equity, isNotEmpty);
        print('  Vault: ${first.vaultAddress.substring(0, 10)}...');
        print('  Equity: \$${first.equity}');
      }
    });

    test('vault models deserialize correctly', () async {
      if (testVaultAddress == null) {
        print('⚠️  Skipping - no TEST_VAULT_ADDRESS set');
        return;
      }

      final details = await info.vaultDetails(
        vaultAddress: testVaultAddress,
      );

      // Test VaultRelationship deserialization
      if (details.relationship != null) {
        expect(details.relationship!.type, isNotEmpty);
        print('  Relationship: ${details.relationship!.type}');
      }

      // Test VaultFollower deserialization
      if (details.followers.isNotEmpty) {
        final follower = details.followers.first;
        expect(follower.user, startsWith('0x'));
        expect(follower.vaultEquity, isNotEmpty);
        expect(follower.pnl, isNotEmpty);
        expect(follower.allTimePnl, isNotEmpty);
        expect(follower.daysFollowing, isA<int>());
        expect(follower.vaultEntryTime, isA<int>());
        print('  ✓ Follower model deserialization works');
      }

      print('✓ All vault models deserialize correctly');
    });
  });
}
