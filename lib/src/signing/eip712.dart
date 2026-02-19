/// EIP-712 typed data construction for Hyperliquid signing.
library;

import '../utils/constants.dart';

/// EIP-712 type definitions for Hyperliquid L1 actions.
const Map<String, List<Map<String, String>>> l1ActionTypes = {
  'EIP712Domain': [
    {'name': 'name', 'type': 'string'},
    {'name': 'version', 'type': 'string'},
    {'name': 'chainId', 'type': 'uint256'},
    {'name': 'verifyingContract', 'type': 'address'},
  ],
  'Agent': [
    {'name': 'source', 'type': 'string'},
    {'name': 'connectionId', 'type': 'bytes32'},
  ],
};

/// EIP-712 type definitions for user-signed actions (e.g. approveBuilderFee).
const Map<String, List<Map<String, String>>> approveBuilderFeeTypes = {
  'EIP712Domain': [
    {'name': 'name', 'type': 'string'},
    {'name': 'version', 'type': 'string'},
    {'name': 'chainId', 'type': 'uint256'},
    {'name': 'verifyingContract', 'type': 'address'},
  ],
  'HyperliquidTransaction:ApproveBuilderFee': [
    {'name': 'hyperliquidChain', 'type': 'string'},
    {'name': 'maxFeeRate', 'type': 'string'},
    {'name': 'builder', 'type': 'address'},
    {'name': 'nonce', 'type': 'uint64'},
  ],
};

/// EIP-712 type definitions for usdClassTransfer.
const Map<String, List<Map<String, String>>> usdClassTransferTypes = {
  'EIP712Domain': [
    {'name': 'name', 'type': 'string'},
    {'name': 'version', 'type': 'string'},
    {'name': 'chainId', 'type': 'uint256'},
    {'name': 'verifyingContract', 'type': 'address'},
  ],
  'HyperliquidTransaction:UsdClassTransfer': [
    {'name': 'hyperliquidChain', 'type': 'string'},
    {'name': 'amount', 'type': 'string'},
    {'name': 'toPerp', 'type': 'bool'},
    {'name': 'nonce', 'type': 'uint64'},
  ],
};

/// EIP-712 type definitions for usdSend.
const Map<String, List<Map<String, String>>> usdSendTypes = {
  'EIP712Domain': [
    {'name': 'name', 'type': 'string'},
    {'name': 'version', 'type': 'string'},
    {'name': 'chainId', 'type': 'uint256'},
    {'name': 'verifyingContract', 'type': 'address'},
  ],
  'HyperliquidTransaction:UsdSend': [
    {'name': 'hyperliquidChain', 'type': 'string'},
    {'name': 'destination', 'type': 'address'},
    {'name': 'amount', 'type': 'string'},
    {'name': 'time', 'type': 'uint64'},
  ],
};

/// EIP-712 type definitions for spotSend.
const Map<String, List<Map<String, String>>> spotSendTypes = {
  'EIP712Domain': [
    {'name': 'name', 'type': 'string'},
    {'name': 'version', 'type': 'string'},
    {'name': 'chainId', 'type': 'uint256'},
    {'name': 'verifyingContract', 'type': 'address'},
  ],
  'HyperliquidTransaction:SpotSend': [
    {'name': 'hyperliquidChain', 'type': 'string'},
    {'name': 'destination', 'type': 'string'},  // Must be 'string' not 'address' per official docs
    {'name': 'token', 'type': 'string'},
    {'name': 'amount', 'type': 'string'},
    {'name': 'time', 'type': 'uint64'},
  ],
};

/// EIP-712 type definitions for sendAsset.
const Map<String, List<Map<String, String>>> sendAssetTypes = {
  'EIP712Domain': [
    {'name': 'name', 'type': 'string'},
    {'name': 'version', 'type': 'string'},
    {'name': 'chainId', 'type': 'uint256'},
    {'name': 'verifyingContract', 'type': 'address'},
  ],
  'HyperliquidTransaction:SendAsset': [
    {'name': 'hyperliquidChain', 'type': 'string'},
    {'name': 'destination', 'type': 'string'},  // Must be 'string' not 'address' per official docs
    {'name': 'sourceDex', 'type': 'string'},
    {'name': 'destinationDex', 'type': 'string'},
    {'name': 'token', 'type': 'string'},
    {'name': 'amount', 'type': 'string'},
    {'name': 'fromSubAccount', 'type': 'string'},
    {'name': 'nonce', 'type': 'uint64'},
  ],
};

/// Build EIP-712 typed data for an L1 action.
///
/// [actionHash] is the keccak256 hash of the msgpack-encoded action
/// (the `connectionId` field).
Map<String, dynamic> buildL1TypedData({
  required String actionHash,
  bool isTestnet = false,
}) {
  return {
    'domain': {
      'name': HyperliquidEip712.domainName,
      'version': HyperliquidEip712.domainVersion,
      'chainId': HyperliquidEip712.chainId,
      'verifyingContract': HyperliquidEip712.verifyingContract,
    },
    'types': l1ActionTypes,
    'primaryType': 'Agent',
    'message': {
      'source': HyperliquidEip712.source(isTestnet: isTestnet),
      'connectionId': actionHash,
    },
  };
}

/// Build EIP-712 typed data for approveBuilderFee.
Map<String, dynamic> buildApproveBuilderFeeTypedData({
  required String hyperliquidChain,
  required String maxFeeRate,
  required String builder,
  required int nonce,
  int? signatureChainId,
}) {
  final chainId = signatureChainId ?? HyperliquidEip712.arbitrumChainId;

  return {
    'domain': {
      'name': HyperliquidEip712.userSignedDomainName,
      'version': HyperliquidEip712.domainVersion,
      'chainId': chainId,
      'verifyingContract': HyperliquidEip712.verifyingContract,
    },
    'types': approveBuilderFeeTypes,
    'primaryType': 'HyperliquidTransaction:ApproveBuilderFee',
    'message': {
      'hyperliquidChain': hyperliquidChain,
      'maxFeeRate': maxFeeRate,
      'builder': builder.toLowerCase(),
      'nonce': nonce,
    },
  };
}

/// Build EIP-712 typed data for usdClassTransfer.
Map<String, dynamic> buildUsdClassTransferTypedData({
  required String hyperliquidChain,
  required String amount,
  required bool toPerp,
  required int nonce,
  int? signatureChainId,
}) {
  final chainId = signatureChainId ?? HyperliquidEip712.arbitrumChainId;

  return {
    'domain': {
      'name': HyperliquidEip712.userSignedDomainName,
      'version': HyperliquidEip712.domainVersion,
      'chainId': chainId,
      'verifyingContract': HyperliquidEip712.verifyingContract,
    },
    'types': usdClassTransferTypes,
    'primaryType': 'HyperliquidTransaction:UsdClassTransfer',
    'message': {
      'hyperliquidChain': hyperliquidChain,
      'amount': amount,
      'toPerp': toPerp,
      'nonce': nonce,
    },
  };
}

/// Build EIP-712 typed data for usdSend.
Map<String, dynamic> buildUsdSendTypedData({
  required String hyperliquidChain,
  required String destination,
  required String amount,
  required int time,
  int? signatureChainId,
}) {
  final chainId = signatureChainId ?? HyperliquidEip712.arbitrumChainId;

  return {
    'domain': {
      'name': HyperliquidEip712.userSignedDomainName,
      'version': HyperliquidEip712.domainVersion,
      'chainId': chainId,
      'verifyingContract': HyperliquidEip712.verifyingContract,
    },
    'types': usdSendTypes,
    'primaryType': 'HyperliquidTransaction:UsdSend',
    'message': {
      'hyperliquidChain': hyperliquidChain,
      'destination': destination.toLowerCase(),
      'amount': amount,
      'time': time,
    },
  };
}

/// Build EIP-712 typed data for spotSend action.
Map<String, dynamic> buildSpotSendTypedData({
  required String hyperliquidChain,
  required String destination,
  required String token,
  required String amount,
  required int time,
  int? signatureChainId,
}) {
  final chainId = signatureChainId ?? HyperliquidEip712.arbitrumChainId;

  return {
    'domain': {
      'name': HyperliquidEip712.userSignedDomainName,
      'version': HyperliquidEip712.domainVersion,
      'chainId': chainId,
      'verifyingContract': HyperliquidEip712.verifyingContract,
    },
    'types': spotSendTypes,
    'primaryType': 'HyperliquidTransaction:SpotSend',
    'message': {
      'hyperliquidChain': hyperliquidChain,
      'destination': destination.toLowerCase(),
      'token': token,
      'amount': amount,
      'time': time,
    },
  };
}

/// Build EIP-712 typed data for sendAsset action.
Map<String, dynamic> buildSendAssetTypedData({
  required String hyperliquidChain,
  required String destination,
  required String sourceDex,
  required String destinationDex,
  required String token,
  required String amount,
  required String fromSubAccount,
  required int nonce,
  int? signatureChainId,
}) {
  final chainId = signatureChainId ?? HyperliquidEip712.arbitrumChainId;

  return {
    'domain': {
      'name': HyperliquidEip712.userSignedDomainName,
      'version': HyperliquidEip712.domainVersion,
      'chainId': chainId,
      'verifyingContract': HyperliquidEip712.verifyingContract,
    },
    'types': sendAssetTypes,
    'primaryType': 'HyperliquidTransaction:SendAsset',
    'message': {
      'hyperliquidChain': hyperliquidChain,
      'destination': destination.toLowerCase(),
      'sourceDex': sourceDex,
      'destinationDex': destinationDex,
      'token': token,
      'amount': amount,
      'fromSubAccount': fromSubAccount,  // Don't lowercase - it's type 'string' not 'address'
      'nonce': nonce,
    },
  };
}
