/// High-level signing orchestrator for Hyperliquid actions.
library;

import '../models/common_types.dart';
import 'action_hash.dart';
import 'eip712.dart';
import 'wallet_adapter.dart';

/// Parse an EIP-712 signature hex string into r, s, v components.
///
/// The signature must be 65 bytes (130 hex chars, optionally with `0x` prefix).
SignatureComponents parseSignature(String signature) {
  final sig =
      signature.startsWith('0x') ? signature.substring(2) : signature;

  if (sig.length != 130) {
    throw ArgumentError('Invalid signature length: ${sig.length}, expected 130');
  }

  final r = '0x${sig.substring(0, 64)}';
  final s = '0x${sig.substring(64, 128)}';
  var v = int.parse(sig.substring(128, 130), radix: 16);

  // Normalize v to 27 or 28 (EIP-155 recovery id).
  if (v < 27) {
    v += 27;
  } else if (v > 28) {
    v = v % 2 == 0 ? 27 : 28;
  }

  return SignatureComponents(r: r, s: s, v: v);
}

/// Sign a Hyperliquid L1 action.
///
/// 1. Hash the action (keccak256 of msgpack-encoded action + nonce).
/// 2. Build EIP-712 typed data with the hash as `connectionId`.
/// 3. Sign via the [wallet] adapter.
/// 4. Parse signature into r, s, v.
Future<SignatureComponents> signL1Action({
  required WalletAdapter wallet,
  required Map<String, dynamic> action,
  required int nonce,
  bool isTestnet = false,
  String? vaultAddress,
}) async {
  final actionHash = createL1ActionHash(
    action: action,
    nonce: nonce,
    vaultAddress: vaultAddress,
  );

  final typedData = buildL1TypedData(
    actionHash: actionHash,
    isTestnet: isTestnet,
  );

  final signature = await wallet.signTypedData(typedData);
  return parseSignature(signature);
}

/// Sign a user-signed action (e.g. approveBuilderFee, usdClassTransfer, usdSend).
///
/// These use a different EIP-712 domain (`HyperliquidSignTransaction`)
/// and chain ID (Arbitrum by default).
Future<SignatureComponents> signUserSignedAction({
  required WalletAdapter wallet,
  required String hyperliquidChain,
  required String primaryType,
  required Map<String, dynamic> message,
  int? signatureChainId,
}) async {
  late Map<String, dynamic> typedData;

  switch (primaryType) {
    case 'HyperliquidTransaction:ApproveBuilderFee':
      typedData = buildApproveBuilderFeeTypedData(
        hyperliquidChain: hyperliquidChain,
        maxFeeRate: message['maxFeeRate'] as String,
        builder: message['builder'] as String,
        nonce: message['nonce'] as int,
        signatureChainId: signatureChainId,
      );
      break;

    case 'HyperliquidTransaction:UsdClassTransfer':
      typedData = buildUsdClassTransferTypedData(
        hyperliquidChain: hyperliquidChain,
        amount: message['amount'] as String,
        toPerp: message['toPerp'] as bool,
        nonce: message['nonce'] as int,
        signatureChainId: signatureChainId,
      );
      break;

    case 'HyperliquidTransaction:UsdSend':
      typedData = buildUsdSendTypedData(
        hyperliquidChain: hyperliquidChain,
        destination: message['destination'] as String,
        amount: message['amount'] as String,
        time: message['time'] as int,
        signatureChainId: signatureChainId,
      );
      break;

    case 'HyperliquidTransaction:SpotSend':
      typedData = buildSpotSendTypedData(
        hyperliquidChain: hyperliquidChain,
        destination: message['destination'] as String,
        token: message['token'] as String,
        amount: message['amount'] as String,
        time: message['time'] as int,
        signatureChainId: signatureChainId,
      );
      break;

    case 'HyperliquidTransaction:SendAsset':
      typedData = buildSendAssetTypedData(
        hyperliquidChain: hyperliquidChain,
        destination: message['destination'] as String,
        sourceDex: message['sourceDex'] as String,
        destinationDex: message['destinationDex'] as String,
        token: message['token'] as String,
        amount: message['amount'] as String,
        fromSubAccount: message['fromSubAccount'] as String,
        nonce: message['nonce'] as int,
        signatureChainId: signatureChainId,
      );
      break;

    default:
      throw UnimplementedError(
          'User-signed action type "$primaryType" is not yet supported');
  }

  final signature = await wallet.signTypedData(typedData);
  return parseSignature(signature);
}
