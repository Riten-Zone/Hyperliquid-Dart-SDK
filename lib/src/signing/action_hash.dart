/// Action hashing for Hyperliquid L1 actions.
///
/// Creates the `connectionId` (bytes32) used in EIP-712 signing by
/// keccak256-hashing the msgpack-encoded action + nonce + vaultAddress.
library;

import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:pointycastle/digests/keccak.dart';

/// Create the L1 action hash (connectionId) used in EIP-712 signing.
///
/// This replicates the behavior of `@nktkas/hyperliquid`'s
/// `createL1ActionHash` function:
/// 1. Msgpack-encode the action
/// 2. Append nonce as big-endian uint64
/// 3. Append vaultAddress byte (0 if no vault, 1 + address bytes if vault)
/// 4. Keccak256 hash the result
///
/// Returns the hash as a `0x`-prefixed hex string.
String createL1ActionHash({
  required Map<String, dynamic> action,
  required int nonce,
  String? vaultAddress,
}) {
  // 1. Msgpack-encode the action.
  final actionBytes = msgpack.serialize(action);

  // 2. Encode nonce as big-endian uint64 (8 bytes).
  final nonceBytes = Uint8List(8);
  final bd = ByteData.view(nonceBytes.buffer);
  bd.setUint64(0, nonce);

  // 3. Encode vault address.
  Uint8List vaultBytes;
  if (vaultAddress != null && vaultAddress.isNotEmpty) {
    final addrHex = vaultAddress.startsWith('0x')
        ? vaultAddress.substring(2)
        : vaultAddress;
    final addrBytes = _hexToBytes(addrHex);
    vaultBytes = Uint8List(1 + addrBytes.length);
    vaultBytes[0] = 1;
    vaultBytes.setRange(1, vaultBytes.length, addrBytes);
  } else {
    vaultBytes = Uint8List.fromList([0]);
  }

  // 4. Concatenate: actionBytes + nonceBytes + vaultBytes
  final combined = Uint8List(
      actionBytes.length + nonceBytes.length + vaultBytes.length);
  combined.setRange(0, actionBytes.length, actionBytes);
  combined.setRange(
      actionBytes.length, actionBytes.length + nonceBytes.length, nonceBytes);
  combined.setRange(actionBytes.length + nonceBytes.length, combined.length,
      vaultBytes);

  // 5. Keccak256 hash.
  final digest = KeccakDigest(256);
  final hash = Uint8List(digest.digestSize);
  digest.update(combined, 0, combined.length);
  digest.doFinal(hash, 0);

  return '0x${_bytesToHex(hash)}';
}

String _bytesToHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

Uint8List _hexToBytes(String hex) {
  final h = hex.startsWith('0x') ? hex.substring(2) : hex;
  final result = Uint8List(h.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}
