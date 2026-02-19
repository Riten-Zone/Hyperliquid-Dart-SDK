import 'package:hyperliquid_dart/hyperliquid_dart.dart';

void main() async {
  final wallet = PrivateKeyWalletAdapter('0xYOUR_PRIVATE_KEY');
  final exchange = ExchangeClient(wallet: wallet);
  final userAddress = await wallet.getAddress();

  // Example 1: Toggle spot dusting
  print('Example 1: Opt out of spot dusting');
  await exchange.spotUser(optOut: true);
  print('✓ Spot dusting disabled');

  // Example 2: Transfer USDC from perp to spot
  print('\nExample 2: Transfer USDC perp → spot');
  await exchange.sendAsset(
    destination: userAddress,
    sourceDex: '', // Perp DEX
    destinationDex: 'spot',
    token: 'USDC',
    amount: '10.0',
  );
  print('✓ Transferred 10 USDC to spot account');

  // Example 3: Send spot tokens to another user
  print('\nExample 3: Send spot USDC to friend');
  await exchange.spotSend(
    destination: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    token: 'USDC:0x6d1e7cde53ba9467b783cb7c530ce054', // Correct USDC token ID
    amount: '5.0',
  );
  print('✓ Sent 5 USDC to friend');

  // Example 4: Sub-account transfer
  print('\nExample 4: Transfer to sub-account');
  await exchange.subAccountTransfer(
    subAccountUser: '0xYOUR_SUB_ACCOUNT',
    isDeposit: true,
    usd: 100.0, // Will be converted to 100000000 microunits
  );
  print('✓ Deposited 100 USDC to sub-account');

  exchange.close();
}
