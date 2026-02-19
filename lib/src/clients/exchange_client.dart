/// Client for executing Hyperliquid exchange operations.
library;

import '../models/common_types.dart';
import '../models/exchange_types.dart';
import '../signing/signer.dart';
import '../signing/wallet_adapter.dart';
import '../transport/http_transport.dart';

/// Client for placing orders, cancelling orders, updating leverage, and other
/// write operations on the Hyperliquid exchange.
///
/// Requires a [WalletAdapter] for signing all actions.
///
/// ```dart
/// final exchange = ExchangeClient(wallet: myWalletAdapter);
///
/// await exchange.updateLeverage(
///   asset: 0, // BTC
///   leverage: 10,
///   isCross: true,
/// );
///
/// final result = await exchange.placeOrder(
///   orders: [OrderWire.limit(asset: 0, isBuy: true, limitPx: '50000', sz: '0.001')],
/// );
///
/// exchange.close();
/// ```
class ExchangeClient {
  final WalletAdapter wallet;
  final HttpTransport _transport;
  final bool isTestnet;

  /// Create an ExchangeClient.
  ///
  /// [wallet] is used to sign all exchange actions.
  ExchangeClient({
    required this.wallet,
    this.isTestnet = false,
    HttpTransport? transport,
  }) : _transport = transport ?? HttpTransport(isTestnet: isTestnet);

  /// Place one or more orders (perpetual futures or spot markets).
  ///
  /// **Asset IDs:**
  /// - Perpetual futures: Use index from `meta.universe` (e.g., 0 for BTC)
  /// - Spot markets: Use `10000 + index` from `spotMeta.universe`
  ///   - Tip: Use `info.getSpotAssetId(tokenName)` to get the correct asset ID
  ///
  /// [orders] are the order wires to submit.
  /// [grouping] controls TP/SL grouping (default: no grouping).
  /// [builder] optionally adds a builder fee.
  /// [vaultAddress] allows trading on behalf of a sub-account (master account signs).
  ///
  /// Example (perpetual futures):
  /// ```dart
  /// await exchange.placeOrder(
  ///   orders: [OrderWire.limit(
  ///     asset: 0,  // BTC perpetual
  ///     isBuy: true,
  ///     limitPx: '50000',
  ///     sz: '0.1',
  ///   )],
  /// );
  /// ```
  ///
  /// Example (spot markets):
  /// ```dart
  /// final purrAssetId = await info.getSpotAssetId('PURR/USDC');
  /// await exchange.placeOrder(
  ///   orders: [OrderWire.limit(
  ///     asset: purrAssetId!,  // 10000 + spot index
  ///     isBuy: true,
  ///     limitPx: '0.0001',
  ///     sz: '1000',
  ///   )],
  /// );
  /// ```
  Future<ExchangeResponse> placeOrder({
    required List<OrderWire> orders,
    OrderGrouping grouping = OrderGrouping.na,
    BuilderFee? builder,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'order',
      'orders': orders.map((o) => o.toWire()).toList(),
      'grouping': grouping.value,
    };

    if (builder != null) {
      action['builder'] = builder.toWire();
    }

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Cancel one or more orders by their order IDs.
  ///
  /// Use this to cancel specific orders when you know their order IDs.
  /// For cancelling by client order ID, use [cancelOrdersByCloid] instead.
  ///
  /// **Parameters:**
  /// - [cancels] - List of `CancelWire` objects (asset + order ID pairs)
  /// - [vaultAddress] - Optional vault/sub-account address for vault trading
  ///
  /// **Example:**
  /// ```dart
  /// final result = await exchange.cancelOrders(
  ///   cancels: [
  ///     CancelWire(asset: 0, oid: 123456789),  // Cancel BTC order
  ///     CancelWire(asset: 1, oid: 987654321),  // Cancel ETH order
  ///   ],
  /// );
  /// if (result.status == 'ok') {
  ///   print('Orders cancelled successfully');
  /// }
  /// ```
  Future<ExchangeResponse> cancelOrders({
    required List<CancelWire> cancels,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'cancel',
      'cancels': cancels.map((c) => c.toWire()).toList(),
    };

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Cancel orders by client order ID (cloid).
  ///
  /// Useful when you assigned custom IDs to orders and want to cancel
  /// them without looking up the exchange-assigned order IDs.
  ///
  /// **Parameters:**
  /// - [asset] - Asset index (e.g., 0 for BTC)
  /// - [cloids] - List of client-assigned order ID strings
  /// - [vaultAddress] - Optional vault/sub-account address for vault trading
  ///
  /// **Example:**
  /// ```dart
  /// final result = await exchange.cancelOrdersByCloid(
  ///   asset: 0,  // BTC
  ///   cloids: ['my-order-1', 'my-order-2'],
  /// );
  /// if (result.status == 'ok') {
  ///   print('Orders cancelled by cloid');
  /// }
  /// ```
  Future<ExchangeResponse> cancelOrdersByCloid({
    required int asset,
    required List<String> cloids,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'cancelByCloid',
      'cancels': cloids.map((cloid) => {'asset': asset, 'cloid': cloid}).toList(),
    };

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Modify an existing order's parameters.
  ///
  /// Modifying only size preserves queue position; modifying price loses it.
  ///
  /// [vaultAddress] allows trading on behalf of a sub-account (master account signs).
  ///
  /// Example:
  /// ```dart
  /// final result = await exchange.modify(
  ///   oid: 123456789,
  ///   order: OrderWire.limit(
  ///     asset: 0,
  ///     isBuy: true,
  ///     limitPx: '50000',
  ///     sz: '0.002',
  ///     tif: TimeInForce.gtc,
  ///   ),
  /// );
  /// ```
  Future<ExchangeResponse> modify({
    required int oid,
    required OrderWire order,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'modify',
      'oid': oid,
      'order': order.toWire(),
    };

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Modify multiple orders in a single atomic request.
  ///
  /// Each modification can succeed or fail independently.
  ///
  /// [vaultAddress] allows trading on behalf of a sub-account (master account signs).
  ///
  /// Example:
  /// ```dart
  /// final result = await exchange.batchModify(
  ///   modifies: [
  ///     ModifyWire(
  ///       oid: 123456789,
  ///       order: OrderWire.limit(asset: 0, isBuy: true, limitPx: '50000', sz: '0.002'),
  ///     ),
  ///     ModifyWire(
  ///       oid: 123456790,
  ///       order: OrderWire.limit(asset: 0, isBuy: true, limitPx: '51000', sz: '0.003'),
  ///     ),
  ///   ],
  /// );
  /// ```
  Future<ExchangeResponse> batchModify({
    required List<ModifyWire> modifies,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'batchModify',
      'modifies': modifies.map((m) => m.toWire()).toList(),
    };

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Update leverage for a perpetual asset.
  ///
  /// Changes the leverage multiplier for a specific asset. Higher leverage
  /// means more exposure with the same capital, but higher liquidation risk.
  ///
  /// **Parameters:**
  /// - [asset] - Asset index (e.g., 0 for BTC)
  /// - [leverage] - Leverage multiplier (e.g., 10 for 10x)
  /// - [isCross] - true for cross margin, false for isolated margin
  /// - [vaultAddress] - Optional vault/sub-account address for vault trading
  ///
  /// **Example:**
  /// ```dart
  /// // Set BTC to 10x cross leverage
  /// await exchange.updateLeverage(
  ///   asset: 0,
  ///   leverage: 10,
  ///   isCross: true,
  /// );
  ///
  /// // Set ETH to 5x isolated leverage
  /// await exchange.updateLeverage(
  ///   asset: 1,
  ///   leverage: 5,
  ///   isCross: false,
  /// );
  /// ```
  Future<ExchangeResponse> updateLeverage({
    required int asset,
    required int leverage,
    required bool isCross,
    String? vaultAddress,
  }) async {
    // Field order matters for msgpack: type, asset, isCross, leverage
    final action = <String, dynamic>{};
    action['type'] = 'updateLeverage';
    action['asset'] = asset;
    action['isCross'] = isCross;
    action['leverage'] = leverage;

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Add or remove isolated margin for a position.
  ///
  /// Only applies to positions using isolated margin mode. Allows you to
  /// adjust margin allocation to reduce or increase liquidation risk.
  ///
  /// **Parameters:**
  /// - [asset] - Asset index (e.g., 0 for BTC)
  /// - [isBuy] - true for long position, false for short position
  /// - [ntli] - Margin amount in USDC microunits (positive to add, negative to remove)
  /// - [vaultAddress] - Optional vault/sub-account address for vault trading
  ///
  /// **Example:**
  /// ```dart
  /// // Add 100 USDC to isolated long BTC position
  /// await exchange.updateIsolatedMargin(
  ///   asset: 0,
  ///   isBuy: true,
  ///   ntli: 100000000,  // 100 USDC in microunits
  /// );
  ///
  /// // Remove 50 USDC from isolated short ETH position
  /// await exchange.updateIsolatedMargin(
  ///   asset: 1,
  ///   isBuy: false,
  ///   ntli: -50000000,  // -50 USDC in microunits
  /// );
  /// ```
  Future<ExchangeResponse> updateIsolatedMargin({
    required int asset,
    required bool isBuy,
    /// Positive to add margin, negative to remove.
    required int ntli,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'updateIsolatedMargin',
      'asset': asset,
      'isBuy': isBuy,
      'ntli': ntli,
    };

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Transfer USDC to another address or sub-account.
  ///
  /// Internal Hyperliquid transfer (not on-chain). Instant and feeless.
  /// Works between main accounts and sub-accounts.
  ///
  /// **Parameters:**
  /// - [destination] - Recipient's 42-character hex address
  /// - [amount] - Amount in USDC as string (e.g., "100.5")
  ///
  /// **Example:**
  /// ```dart
  /// // Transfer 100 USDC to another user
  /// await exchange.usdTransfer(
  ///   destination: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  ///   amount: '100.0',
  /// );
  ///
  /// // Transfer to sub-account
  /// await exchange.usdTransfer(
  ///   destination: '0xYOUR_SUB_ACCOUNT_ADDRESS',
  ///   amount: '50.0',
  /// );
  /// ```
  Future<ExchangeResponse> usdTransfer({
    required String destination,
    required String amount,
  }) async {
    final action = <String, dynamic>{
      'type': 'usdTransfer',
      'destination': destination.toLowerCase(),
      'amount': amount,
    };

    return _signAndSend(action);
  }

  /// Withdraw USDC to an external Ethereum address (via Arbitrum bridge).
  ///
  /// Initiates an on-chain withdrawal from Hyperliquid to Arbitrum.
  /// Subject to network confirmations and bridge processing time.
  ///
  /// **Parameters:**
  /// - [destination] - Ethereum address on Arbitrum (42-character hex)
  /// - [amount] - Amount in USDC as string (e.g., "100.5")
  ///
  /// **Example:**
  /// ```dart
  /// // Withdraw 500 USDC to external wallet
  /// await exchange.withdraw(
  ///   destination: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  ///   amount: '500.0',
  /// );
  /// ```
  ///
  /// **Note:** Withdrawals are processed on-chain and may take time to confirm.
  /// For internal transfers, use [usdTransfer] instead (instant and feeless).
  Future<ExchangeResponse> withdraw({
    required String destination,
    required String amount,
  }) async {
    final action = <String, dynamic>{
      'type': 'withdraw3',
      'destination': destination.toLowerCase(),
      'amount': amount,
    };

    return _signAndSend(action);
  }

  /// Schedule automatic cancellation of all orders at a future time.
  ///
  /// Useful as a "dead man's switch" for risk management.
  /// If the system stops updating the schedule, orders auto-cancel.
  ///
  /// Example:
  /// ```dart
  /// final futureTime = DateTime.now()
  ///     .add(Duration(minutes: 10))
  ///     .millisecondsSinceEpoch;
  /// await exchange.scheduleCancel(time: futureTime);
  /// ```
  Future<ExchangeResponse> scheduleCancel({
    required int time,
  }) async {
    final action = <String, dynamic>{
      'type': 'scheduleCancel',
      'time': time,
    };

    return _signAndSend(action);
  }

  /// Place a TWAP (Time-Weighted Average Price) order.
  ///
  /// TWAP orders execute gradually over time to minimize market impact.
  ///
  /// Constraints:
  /// - Duration: 5-1440 minutes
  /// - Minimum $10 per child order
  /// - Total value must support at least 2 child orders
  ///
  /// Example:
  /// ```dart
  /// final result = await exchange.twapOrder(
  ///   twap: TwapWire(
  ///     asset: 0,
  ///     isBuy: true,
  ///     limitPx: '50000',
  ///     sz: '0.5',
  ///     durationMins: 60,
  ///     reduceOnly: false,
  ///   ),
  /// );
  /// ```
  Future<ExchangeResponse> twapOrder({
    required TwapWire twap,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'twapOrder',
      'twap': twap.toWire(),
    };

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Cancel a TWAP order.
  ///
  /// Cancels an active TWAP order by its TWAP ID.
  ///
  /// [vaultAddress] allows trading on behalf of a sub-account (master account signs).
  ///
  /// Example:
  /// ```dart
  /// await exchange.twapCancel(
  ///   cancel: TwapCancelWire(asset: 0, twapId: 12345),
  /// );
  /// ```
  Future<ExchangeResponse> twapCancel({
    required TwapCancelWire cancel,
    String? vaultAddress,
  }) async {
    final action = <String, dynamic>{
      'type': 'twapCancel',
      ...cancel.toWire(), // Spread fields at action level
    };

    if (vaultAddress != null && vaultAddress.isNotEmpty) {
      action['vaultAddress'] = vaultAddress.toLowerCase();
    }

    return _signAndSend(action);
  }

  /// Approve a builder fee.
  ///
  /// This uses the user-signed action flow (different EIP-712 domain).
  Future<ExchangeResponse> approveBuilderFee({
    required String builder,
    required String maxFeeRate,
    int? nonce,
  }) async {
    final ts = nonce ?? DateTime.now().millisecondsSinceEpoch;
    final chain = isTestnet ? 'Testnet' : 'Mainnet';

    final signature = await signUserSignedAction(
      wallet: wallet,
      hyperliquidChain: chain,
      primaryType: 'HyperliquidTransaction:ApproveBuilderFee',
      message: {
        'maxFeeRate': maxFeeRate,
        'builder': builder.toLowerCase(),
        'nonce': ts,
      },
    );

    final action = <String, dynamic>{
      'type': 'approveBuilderFee',
      'hyperliquidChain': chain,
      'signatureChainId': '0xa4b1',
      'maxFeeRate': maxFeeRate,
      'builder': builder.toLowerCase(),
      'nonce': ts,
    };

    final requestBody = <String, dynamic>{
      'action': action,
      'nonce': ts,
      'signature': signature.toJson(),
    };

    final data = await _transport.postExchange(requestBody);
    return ExchangeResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Transfer USDC between spot and perpetual accounts.
  ///
  /// [amount] is in USDC (e.g., "1.5" for 1.5 USDC).
  /// [toPerp] is true to transfer spot → perp, false for perp → spot.
  ///
  /// This uses the user-signed action flow (different EIP-712 domain).
  ///
  /// Example:
  /// ```dart
  /// // Transfer 100 USDC from spot to perp
  /// await exchange.usdClassTransfer(amount: '100', toPerp: true);
  ///
  /// // Transfer 50 USDC from perp to spot
  /// await exchange.usdClassTransfer(amount: '50', toPerp: false);
  /// ```
  Future<ExchangeResponse> usdClassTransfer({
    required String amount,
    required bool toPerp,
    int? nonce,
  }) async {
    final ts = nonce ?? DateTime.now().millisecondsSinceEpoch;
    final chain = isTestnet ? 'Testnet' : 'Mainnet';

    final signature = await signUserSignedAction(
      wallet: wallet,
      hyperliquidChain: chain,
      primaryType: 'HyperliquidTransaction:UsdClassTransfer',
      message: {
        'hyperliquidChain': chain,
        'amount': amount,
        'toPerp': toPerp,
        'nonce': ts,
      },
    );

    final action = <String, dynamic>{
      'type': 'usdClassTransfer',
      'hyperliquidChain': chain,
      'signatureChainId': '0xa4b1',
      'amount': amount,
      'toPerp': toPerp,
      'nonce': ts,
    };

    final requestBody = <String, dynamic>{
      'action': action,
      'nonce': ts,
      'signature': signature.toJson(),
    };

    final data = await _transport.postExchange(requestBody);
    return ExchangeResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Send USDC to another address (internal Hyperliquid transfer).
  ///
  /// [destination] is the recipient's address.
  /// [amount] is in USDC (e.g., "1.5" for 1.5 USDC).
  ///
  /// IMPORTANT: This transfers spot USDC within Hyperliquid (not on-chain).
  /// Does not interact with the EVM bridge.
  ///
  /// This uses the user-signed action flow (different EIP-712 domain).
  ///
  /// Example:
  /// ```dart
  /// await exchange.usdSend(
  ///   destination: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  ///   amount: '10.5',
  /// );
  /// ```
  Future<ExchangeResponse> usdSend({
    required String destination,
    required String amount,
    int? nonce,
  }) async {
    final ts = nonce ?? DateTime.now().millisecondsSinceEpoch;
    final chain = isTestnet ? 'Testnet' : 'Mainnet';

    final signature = await signUserSignedAction(
      wallet: wallet,
      hyperliquidChain: chain,
      primaryType: 'HyperliquidTransaction:UsdSend',
      message: {
        'hyperliquidChain': chain,
        'destination': destination.toLowerCase(),
        'amount': amount,
        'time': ts,
      },
    );

    final action = <String, dynamic>{
      'type': 'usdSend',
      'hyperliquidChain': chain,
      'signatureChainId': '0xa4b1',
      'destination': destination.toLowerCase(),
      'amount': amount,
      'time': ts,
    };

    final requestBody = <String, dynamic>{
      'action': action,
      'nonce': ts,
      'signature': signature.toJson(),
    };

    final data = await _transport.postExchange(requestBody);
    return ExchangeResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Toggle spot dusting settings.
  ///
  /// When [optOut] is true, prevents automatic dusting of small spot token amounts.
  /// Uses L1 action signing (msgpack + keccak256).
  ///
  /// Example:
  /// ```dart
  /// // Disable spot dusting
  /// await exchange.spotUser(optOut: true);
  /// ```
  Future<ExchangeResponse> spotUser({
    required bool optOut,
  }) async {
    final action = <String, dynamic>{
      'type': 'spotUser',
      'toggleSpotDusting': {
        'optOut': optOut,
      },
    };

    return _signAndSend(action);
  }

  /// Send spot tokens to another address.
  ///
  /// [destination] is the recipient's Ethereum address (0x...).
  /// [token] is the token identifier (e.g., "USDC:0xeb62eee3685fc4c43992febcd9e75443").
  /// [amount] is the human-readable amount (e.g., "10.5" for 10.5 tokens).
  /// [time] optional custom timestamp (defaults to current time).
  ///
  /// Uses user-signed action (EIP-712 direct signing).
  ///
  /// Example:
  /// ```dart
  /// await exchange.spotSend(
  ///   destination: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  ///   token: 'USDC:0xeb62eee3685fc4c43992febcd9e75443',
  ///   amount: '10.5',
  /// );
  /// ```
  Future<ExchangeResponse> spotSend({
    required String destination,
    required String token,
    required String amount,
    int? time,
  }) async {
    final ts = time ?? DateTime.now().millisecondsSinceEpoch;
    final chain = isTestnet ? 'Testnet' : 'Mainnet';
    final signatureChainId = '0xa4b1'; // Arbitrum One

    // Step 1: Sign the action
    final signature = await signUserSignedAction(
      wallet: wallet,
      hyperliquidChain: chain,
      primaryType: 'HyperliquidTransaction:SpotSend',
      message: {
        'hyperliquidChain': chain,
        'destination': destination.toLowerCase(),
        'token': token,
        'amount': amount,
        'time': ts,
      },
    );

    // Step 2: Build action
    final action = <String, dynamic>{
      'type': 'spotSend',
      'signatureChainId': signatureChainId,
      'hyperliquidChain': chain,
      'destination': destination.toLowerCase(),
      'token': token,
      'amount': amount,
      'time': ts,
    };

    // Step 3: Send with signature
    final requestBody = <String, dynamic>{
      'action': action,
      'nonce': ts,
      'signature': signature.toJson(),
    };

    final data = await _transport.postExchange(requestBody);
    return ExchangeResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Transfer assets between DEXs, addresses, and/or sub-accounts.
  ///
  /// Most versatile transfer method. Examples:
  /// - Perp → Spot: [sourceDex]="", [destinationDex]="spot"
  /// - Spot → Perp: [sourceDex]="spot", [destinationDex]=""
  /// - Cross-user transfer: [destination] = different address
  /// - Sub-account transfer: [fromSubAccount] = sub-account address
  ///
  /// [destination] recipient address.
  /// [sourceDex] source DEX ("" for perp, "spot" for spot).
  /// [destinationDex] destination DEX ("" for perp, "spot" for spot).
  /// [token] token identifier (e.g., "USDC:0x..." or "USDC" for perp/spot transfers).
  /// [amount] human-readable amount.
  /// [fromSubAccount] source sub-account (default: "" for main account).
  /// [nonce] optional custom nonce (defaults to current timestamp).
  ///
  /// Example:
  /// ```dart
  /// // Transfer USDC from perp to spot
  /// await exchange.sendAsset(
  ///   destination: userAddress,
  ///   sourceDex: '',
  ///   destinationDex: 'spot',
  ///   token: 'USDC',
  ///   amount: '10.0',
  /// );
  /// ```
  Future<ExchangeResponse> sendAsset({
    required String destination,
    required String sourceDex,
    required String destinationDex,
    required String token,
    required String amount,
    String fromSubAccount = '',
    int? nonce,
  }) async {
    final ts = nonce ?? DateTime.now().millisecondsSinceEpoch;
    final chain = isTestnet ? 'Testnet' : 'Mainnet';
    final signatureChainId = '0xa4b1';

    // Step 1: Sign
    final signature = await signUserSignedAction(
      wallet: wallet,
      hyperliquidChain: chain,
      primaryType: 'HyperliquidTransaction:SendAsset',
      message: {
        'hyperliquidChain': chain,
        'destination': destination.toLowerCase(),
        'sourceDex': sourceDex,
        'destinationDex': destinationDex,
        'token': token,
        'amount': amount,
        'fromSubAccount': fromSubAccount,  // Don't lowercase - it's type 'string' not 'address'
        'nonce': ts,
      },
    );

    // Step 2: Build action
    final action = <String, dynamic>{
      'type': 'sendAsset',
      'signatureChainId': signatureChainId,
      'hyperliquidChain': chain,
      'destination': destination.toLowerCase(),
      'sourceDex': sourceDex,
      'destinationDex': destinationDex,
      'token': token,
      'amount': amount,
      'fromSubAccount': fromSubAccount,  // Don't lowercase - it's type 'string' not 'address'
      'nonce': ts,
    };

    // Step 3: Send
    final requestBody = <String, dynamic>{
      'action': action,
      'nonce': ts,
      'signature': signature.toJson(),
    };

    final data = await _transport.postExchange(requestBody);
    return ExchangeResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Transfer USDC between sub-accounts (perpetual DEX only).
  ///
  /// [subAccountUser] is the sub-account address (0x...).
  /// [isDeposit] true = deposit to sub-account, false = withdraw from sub-account.
  /// [usd] amount in USDC (will be multiplied by 1e6 for API).
  ///
  /// Note: Amount must be converted to microunits (USDC * 1e6).
  ///
  /// Example:
  /// ```dart
  /// // Deposit 100 USDC to sub-account
  /// await exchange.subAccountTransfer(
  ///   subAccountUser: '0xYOUR_SUB_ACCOUNT',
  ///   isDeposit: true,
  ///   usd: 100.0,
  /// );
  /// ```
  Future<ExchangeResponse> subAccountTransfer({
    required String subAccountUser,
    required bool isDeposit,
    required double usd,
  }) async {
    final action = <String, dynamic>{
      'type': 'subAccountTransfer',
      'subAccountUser': subAccountUser.toLowerCase(),
      'isDeposit': isDeposit,
      'usd': (usd * 1e6).round(), // Convert to microunits
    };

    return _signAndSend(action);
  }

  /// Transfer spot tokens between sub-accounts (spot DEX only).
  ///
  /// [subAccountUser] is the sub-account address (0x...).
  /// [isDeposit] true = deposit to sub-account, false = withdraw.
  /// [token] token identifier (e.g., "USDC:0x...").
  /// [amount] human-readable amount.
  ///
  /// Example:
  /// ```dart
  /// // Deposit 50 USDC to spot sub-account
  /// await exchange.subAccountSpotTransfer(
  ///   subAccountUser: '0xYOUR_SUB_ACCOUNT',
  ///   isDeposit: true,
  ///   token: 'USDC:0xeb62eee3685fc4c43992febcd9e75443',
  ///   amount: '50.0',
  /// );
  /// ```
  Future<ExchangeResponse> subAccountSpotTransfer({
    required String subAccountUser,
    required bool isDeposit,
    required String token,
    required String amount,
  }) async {
    final action = <String, dynamic>{
      'type': 'subAccountSpotTransfer',
      'subAccountUser': subAccountUser.toLowerCase(),
      'isDeposit': isDeposit,
      'token': token,
      'amount': amount,
    };

    return _signAndSend(action);
  }

  // ===========================================================================
  // VAULT OPERATIONS
  // ===========================================================================

  /// Transfer USDC to or from a vault.
  ///
  /// [vaultAddress] is the vault's 42-character hex address.
  /// [isDeposit] true = deposit to vault, false = withdraw from vault.
  /// [usd] amount in USDC (will be converted to microunits internally).
  ///
  /// IMPORTANT: Uses USDC from your PERP account balance (NOT spot!).
  /// If your USDC is in spot, use usdClassTransfer() first to move it to perp.
  ///
  /// Requires master account signature. Deposits subject to 24-hour lockup.
  /// Protocol enforces $5 minimum deposit. Vault leaders must maintain at least 5% vault equity.
  ///
  /// Uses L1Action signing (msgpack + keccak256).
  ///
  /// Example:
  /// ```dart
  /// // Deposit 100 USDC to vault
  /// await exchange.vaultTransfer(
  ///   vaultAddress: '0x...',
  ///   isDeposit: true,
  ///   usd: 100.0,
  /// );
  ///
  /// // Withdraw 50 USDC from vault
  /// await exchange.vaultTransfer(
  ///   vaultAddress: '0x...',
  ///   isDeposit: false,
  ///   usd: 50.0,
  /// );
  /// ```
  Future<ExchangeResponse> vaultTransfer({
    required String vaultAddress,
    required bool isDeposit,
    required double usd,
  }) async {
    final action = <String, dynamic>{
      'type': 'vaultTransfer',
      'vaultAddress': vaultAddress.toLowerCase(),
      'isDeposit': isDeposit,
      'usd': (usd * 1e6).round(), // Convert to microunits
    };

    return _signAndSend(action);
  }

  /// Sign an action and send it to the exchange endpoint.
  Future<ExchangeResponse> _signAndSend(Map<String, dynamic> action) async {
    final nonce = DateTime.now().millisecondsSinceEpoch;

    final signature = await signL1Action(
      wallet: wallet,
      action: action,
      nonce: nonce,
      isTestnet: isTestnet,
    );

    final requestBody = <String, dynamic>{
      'action': action,
      'nonce': nonce,
      'signature': signature.toJson(),
    };

    final data = await _transport.postExchange(requestBody);
    final response = ExchangeResponse.fromJson(data as Map<String, dynamic>);

    if (response.isError) {
      throw HyperliquidApiException(
        statusCode: 200,
        message: response.errorMessage ?? 'Unknown exchange error',
      );
    }

    return response;
  }

  /// Close the underlying HTTP client.
  void close() {
    _transport.close();
  }
}
