import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Helper script to find real vault addresses for testing
void main() async {
  final info = InfoClient(isTestnet: false);

  print('🔍 Searching for real vaults on mainnet...\n');

  // Try 1: vaultSummaries
  print('1. Trying vaultSummaries()...');
  final summaries = await info.vaultSummaries();

  if (summaries.isNotEmpty) {
    print('   ✓ Found ${summaries.length} vaults via vaultSummaries!');
    for (final vault in summaries.take(3)) {
      print('   📊 ${vault.name}');
      print('      Address: ${vault.vaultAddress}');
      print('      Leader: ${vault.leader}');
      print('      TVL: \$${vault.tvl}');
      print('');
    }
  } else {
    print('   ✗ vaultSummaries returned empty (known API issue)\n');
  }

  // Try 2: Query meta to find some users, then check their vaults
  print('2. Trying to find vault leaders via metadata...');
  final meta = await info.metaAndAssetCtxs();

  // Try some common/known addresses (you can add real ones here)
  final testAddresses = [
    '0x0000000000000000000000000000000000000000', // Zero address
    // Add more known vault leader addresses here if you have them
  ];

  bool foundVault = false;

  for (final addr in testAddresses) {
    try {
      final vaults = await info.leadingVaults(addr);
      if (vaults.isNotEmpty) {
        print('   ✓ Found ${vaults.length} vault(s) for leader $addr');
        for (final vault in vaults.take(2)) {
          print('   📊 ${vault.name}');
          print('      Address: ${vault.vaultAddress}');
          print('      TVL: \$${vault.tvl}');
          print('      7D PnL: ${vault.pnl7D}');
          print('');
          foundVault = true;
        }
      }
    } catch (e) {
      // Silently continue
    }
  }

  if (!foundVault && summaries.isEmpty) {
    print('   ✗ Could not find any vaults\n');
    print('📋 To test vault functionality:');
    print('   1. Visit https://app.hyperliquid.xyz/vaults');
    print('   2. Find a vault and copy its address');
    print('   3. Add it to the test file or run:');
    print('      dart run example/vault_example.dart');
  }

  // Try 3: Get info about a specific vault if we found one
  if (summaries.isNotEmpty || foundVault) {
    print('\n3. Testing vaultDetails() with found vault...');
    String? testVaultAddr;

    if (summaries.isNotEmpty) {
      testVaultAddr = summaries.first.vaultAddress;
    }

    if (testVaultAddr != null) {
      try {
        final details = await info.vaultDetails(vaultAddress: testVaultAddr);
        print('   ✓ Successfully fetched vault details:');
        print('   📈 ${details.name}');
        print('      Leader: ${details.leader}');
        print('      APR: ${details.apr}');
        print('      Followers: ${details.followers.length}');
        print('      Commission: ${details.leaderCommission}');
        print('');

        // Print addresses for use in tests
        print('📝 Use these for testing:');
        print('   Vault Address: $testVaultAddr');
        print('   Leader Address: ${details.leader}');
      } catch (e) {
        print('   ✗ Error fetching details: $e');
      }
    }
  }

  info.close();
  print('\n✅ Done!');
}
