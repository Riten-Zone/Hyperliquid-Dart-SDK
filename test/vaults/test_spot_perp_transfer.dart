import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';

/// Test script for transferring USDC between spot and perp accounts
///
/// Usage:
/// ```bash
/// export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
/// export TRANSFER_AMOUNT=10  # Amount in USDC
/// export TO_PERP=true  # true = spot→perp, false = perp→spot
/// dart run test_spot_perp_transfer.dart
/// ```

void main() async {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];
  final amountStr = Platform.environment['TRANSFER_AMOUNT'];
  final toPerpStr = Platform.environment['TO_PERP'];

  if (privateKey == null || privateKey.isEmpty) {
    print('❌ Error: HYPERLIQUID_PRIVATE_KEY not set!');
    exit(1);
  }

  if (amountStr == null || amountStr.isEmpty) {
    print('❌ Error: TRANSFER_AMOUNT not set!');
    print('\nUsage:');
    print('  export HYPERLIQUID_PRIVATE_KEY=0xYOUR_PRIVATE_KEY');
    print('  export TRANSFER_AMOUNT=10');
    print('  export TO_PERP=true  # true=spot→perp, false=perp→spot');
    print('  dart run test_spot_perp_transfer.dart');
    exit(1);
  }

  final toPerp = toPerpStr?.toLowerCase() == 'true';
  final direction = toPerp ? 'SPOT → PERP' : 'PERP → SPOT';

  final wallet = PrivateKeyWalletAdapter(privateKey);
  final userAddress = await wallet.getAddress();
  final exchange = ExchangeClient(wallet: wallet, isTestnet: false); // MAINNET
  final info = InfoClient(isTestnet: false); // MAINNET

  print('💸 USD CLASS TRANSFER TEST (MAINNET)\n');
  print('👤 Address: $userAddress');
  print('💰 Amount: \$$amountStr USDC');
  print('📊 Direction: $direction\n');

  try {
    // Check current balances
    print('═══════════════════════════════════════════════════');
    print('📊 CURRENT BALANCES');
    print('═══════════════════════════════════════════════════\n');

    final perpState = await info.clearinghouseState(userAddress);
    final spotState = await info.spotClearinghouseState(userAddress);

    final perpBalance = double.parse(perpState.withdrawable);
    print('Perp Balance: \$${perpBalance.toStringAsFixed(2)} USDC');

    final spotUsdc = spotState.balances
        .where((b) => b.coin == 'USDC')
        .firstOrNull;

    final spotBalance = spotUsdc != null
        ? double.parse(spotUsdc.total)
        : 0.0;
    print('Spot Balance: \$${spotBalance.toStringAsFixed(2)} USDC\n');

    // Validate sufficient balance
    final transferAmount = double.parse(amountStr);
    final sourceBalance = toPerp ? spotBalance : perpBalance;
    final sourceName = toPerp ? 'Spot' : 'Perp';

    if (sourceBalance < transferAmount) {
      print('❌ Insufficient balance in $sourceName account!');
      print('   Available: \$${sourceBalance.toStringAsFixed(2)}');
      print('   Required:  \$${transferAmount.toStringAsFixed(2)}');
      exit(1);
    }

    // Get confirmation
    print('⚠️  CONFIRMATION REQUIRED ⚠️');
    print('═══════════════════════════════════════════════════');
    print('Transfer \$${transferAmount.toStringAsFixed(2)} USDC');
    print('Direction: $direction');
    print('');
    print('Type "CONFIRM" to proceed: ');

    final confirmation = stdin.readLineSync();
    if (confirmation?.trim().toUpperCase() != 'CONFIRM') {
      print('\n❌ Transfer cancelled');
      exit(0);
    }

    // Execute transfer
    print('\n═══════════════════════════════════════════════════');
    print('💸 EXECUTING TRANSFER');
    print('═══════════════════════════════════════════════════\n');

    print('Transferring \$${transferAmount.toStringAsFixed(2)} USDC ($direction)...');
    final result = await exchange.usdClassTransfer(
      amount: amountStr,
      toPerp: toPerp,
    );

    if (result.status != 'ok') {
      print('❌ Transfer failed!');
      print('Status: ${result.status}');
      print('Response: ${result.response}');
      exit(1);
    }

    print('✅ Transfer successful!\n');
    print('Response: ${result.response}');

    // Wait and check updated balances
    print('\n⏳ Waiting 3 seconds for balance update...');
    await Future.delayed(Duration(seconds: 3));

    print('\n═══════════════════════════════════════════════════');
    print('📊 UPDATED BALANCES');
    print('═══════════════════════════════════════════════════\n');

    final newPerpState = await info.clearinghouseState(userAddress);
    final newSpotState = await info.spotClearinghouseState(userAddress);

    final newPerpBalance = double.parse(newPerpState.withdrawable);
    final newSpotUsdc = newSpotState.balances
        .where((b) => b.coin == 'USDC')
        .firstOrNull;
    final newSpotBalance = newSpotUsdc != null
        ? double.parse(newSpotUsdc.total)
        : 0.0;

    final perpChange = newPerpBalance - perpBalance;
    final spotChange = newSpotBalance - spotBalance;

    print('Perp Balance: \$${newPerpBalance.toStringAsFixed(2)} USDC');
    print('   Change: ${perpChange >= 0 ? '+' : ''}\$${perpChange.toStringAsFixed(2)}');
    print('');
    print('Spot Balance: \$${newSpotBalance.toStringAsFixed(2)} USDC');
    print('   Change: ${spotChange >= 0 ? '+' : ''}\$${spotChange.toStringAsFixed(2)}');

    print('\n═══════════════════════════════════════════════════');
    print('✅ TRANSFER COMPLETE');
    print('═══════════════════════════════════════════════════');

  } catch (e, stackTrace) {
    print('\n❌ Error during transfer: $e');
    print(stackTrace);
    exit(1);
  } finally {
    exchange.close();
    info.close();
  }
}
