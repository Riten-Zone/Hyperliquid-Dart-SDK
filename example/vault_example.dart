import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Complete vault operations example demonstrating:
/// 1. Browsing all vaults
/// 2. Querying vault details and performance
/// 3. Checking user vault positions
/// 4. Depositing/withdrawing from vaults
///
/// IMPORTANT: This example includes real transactions!
/// - Read-only examples (1-4) are safe to run
/// - Write operations (5-6) require a private key and transfer real funds
/// - Vault deposits have a 24-hour lockup period

void main() async {
  final info = InfoClient();

  print('=== Vault Operations Example ===\n');

  // ==========================================================================
  // EXAMPLE 1: Browse all vaults
  // ==========================================================================
  print('1. Browsing all vaults...');
  final summaries = await info.vaultSummaries();

  if (summaries.isEmpty) {
    print('⚠ vaultSummaries returned empty (known API issue)');
    print('  Use leadingVaults() for specific vault leaders instead\n');
  } else {
    print('Found ${summaries.length} vaults:\n');
    for (final vault in summaries.take(5)) {
      print('  📊 ${vault.name}');
      print('    Address: ${vault.vaultAddress}');
      print('    TVL: \$${vault.tvl}');
      print('    Leader: ${vault.leader}');
      print('    Status: ${vault.isClosed ? '🔒 CLOSED' : '✅ OPEN'}');
      print('    Created: ${DateTime.fromMillisecondsSinceEpoch(vault.createTimeMillis)}');
      print('');
    }
  }

  // ==========================================================================
  // EXAMPLE 2: Get detailed vault information
  // ==========================================================================
  print('2. Fetching vault details...');

  if (summaries.isNotEmpty) {
    final vaultAddress = summaries.first.vaultAddress;
    final details = await info.vaultDetails(
      vaultAddress: vaultAddress,
    );

    print('  📈 Vault: ${details.name}');
    print('  👤 Leader: ${details.leader}');
    print('  📊 APR: ${(details.apr * 100).toStringAsFixed(2)}%');
    print('  💰 Commission: ${(details.leaderCommission * 100).toStringAsFixed(2)}%');
    print('  👥 Followers: ${details.followers.length}');
    print('  🏦 Max Distributable: \$${details.maxDistributable.toStringAsFixed(2)}');
    print('  💵 Max Withdrawable: \$${details.maxWithdrawable.toStringAsFixed(2)}');
    print('  🔒 Is Closed: ${details.isClosed}');

    if (details.description != null && details.description!.isNotEmpty) {
      print('  📝 Description: ${details.description}');
    }

    // Display portfolio performance
    print('\n  Performance:');
    print('    24h Volume: ${details.portfolio.day.vlm}');
    print('    7d Volume: ${details.portfolio.week.vlm}');
    print('    30d Volume: ${details.portfolio.month.vlm}');

    // Display top followers (if any)
    if (details.followers.isNotEmpty) {
      print('\n  Top Followers:');
      for (final follower in details.followers.take(3)) {
        print('    • ${follower.user.substring(0, 10)}...');
        print('      Equity: \$${follower.vaultEquity}');
        print('      PnL: ${follower.pnl}');
        print('      Days following: ${follower.daysFollowing}');
      }
    }

    // Display relationship if exists
    if (details.relationship != null) {
      print('\n  Relationship: ${details.relationship!.type}');
      if (details.relationship!.data?.childAddresses != null) {
        print('    Child vaults: ${details.relationship!.data!.childAddresses!.length}');
      }
    }

    print('');
  }

  // ==========================================================================
  // EXAMPLE 3: Query vaults by specific leader
  // ==========================================================================
  print('3. Fetching vaults managed by a leader...');

  if (summaries.isNotEmpty) {
    final leaderAddress = summaries.first.leader;
    print('  Leader: $leaderAddress');

    final leaderVaults = await info.leadingVaults(leaderAddress);

    if (leaderVaults.isEmpty) {
      print('  No vaults found for this leader\n');
    } else {
      print('  Found ${leaderVaults.length} vault(s):\n');

      for (final vault in leaderVaults) {
        print('  📊 ${vault.name}');
        print('    Address: ${vault.vaultAddress}');
        print('');
      }
    }
  }

  // ==========================================================================
  // EXAMPLE 4: Check user's vault positions
  // ==========================================================================
  print('4. Checking user vault positions...');
  print('  (Replace with your address to see your positions)\n');

  // Example with a placeholder address
  // To use: replace with a real user address
  const exampleUser = '0x0000000000000000000000000000000000000000';

  final equities = await info.userVaultEquities(exampleUser);

  if (equities.isEmpty) {
    print('  No vault positions found for this user\n');
  } else {
    print('  Found ${equities.length} vault position(s):\n');
    for (final equity in equities) {
      print('  💰 Vault: ${equity.vaultAddress}');
      print('    Equity: \$${equity.equity}\n');
    }
  }

  // ==========================================================================
  // EXAMPLE 5: Deposit to vault (requires private key)
  // ==========================================================================
  print('5. Depositing to vault (DISABLED - requires private key)...');
  print('  ⚠ To enable, uncomment the code below and add your private key\n');

  /*
  // UNCOMMENT TO ENABLE (USE WITH CAUTION!)
  final wallet = PrivateKeyWalletAdapter('0xYOUR_PRIVATE_KEY_HERE');
  final exchange = ExchangeClient(wallet: wallet);

  const vaultAddress = '0xYOUR_VAULT_ADDRESS_HERE';
  const depositAmount = 100.0; // 100 USDC

  print('  Depositing $depositAmount USDC to vault...');

  final depositResult = await exchange.vaultTransfer(
    vaultAddress: vaultAddress,
    isDeposit: true,
    usd: depositAmount,
  );

  if (depositResult.status == 'ok') {
    print('  ✓ Deposited $depositAmount USDC to vault');
    print('  ⚠ Note: 24-hour lockup period applies!');
    print('  Response: ${depositResult.response}');
  } else {
    print('  ✗ Deposit failed: ${depositResult.response}');
  }

  exchange.close();
  */

  // ==========================================================================
  // EXAMPLE 6: Withdraw from vault (requires private key)
  // ==========================================================================
  print('6. Withdrawing from vault (DISABLED - requires private key)...');
  print('  ⚠ To enable, uncomment the code below and add your private key\n');

  /*
  // UNCOMMENT TO ENABLE (USE WITH CAUTION!)
  final wallet = PrivateKeyWalletAdapter('0xYOUR_PRIVATE_KEY_HERE');
  final exchange = ExchangeClient(wallet: wallet);

  const vaultAddress = '0xYOUR_VAULT_ADDRESS_HERE';
  const withdrawAmount = 50.0; // 50 USDC

  print('  Withdrawing $withdrawAmount USDC from vault...');

  final withdrawResult = await exchange.vaultTransfer(
    vaultAddress: vaultAddress,
    isDeposit: false,
    usd: withdrawAmount,
  );

  if (withdrawResult.status == 'ok') {
    print('  ✓ Withdrew $withdrawAmount USDC from vault');
    print('  Response: ${withdrawResult.response}');
  } else {
    print('  ✗ Withdrawal failed: ${withdrawResult.response}');
    print('  (Funds may be locked or insufficient equity)');
  }

  exchange.close();
  */

  // ==========================================================================
  // Cleanup
  // ==========================================================================
  info.close();

  print('=== Example Complete ===');
  print('\nKey Takeaways:');
  print('  • vaultSummaries() may return empty (use leadingVaults() instead)');
  print('  • Vault deposits have a 24-hour lockup period');
  print('  • Vault leaders must maintain at least 5% equity');
  print('  • All vault operations require master account signature');
}
