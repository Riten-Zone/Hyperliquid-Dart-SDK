import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('createL1ActionHash', () {
    test('returns 0x-prefixed 64-char hex string', () {
      final hash = createL1ActionHash(
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1234567890,
      );
      expect(hash, startsWith('0x'));
      expect(hash.length, 66); // "0x" + 64 hex chars
      expect(RegExp(r'^0x[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });

    test('is deterministic — same inputs produce same output', () {
      final action = {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10};
      const nonce = 1700000000000;

      final hash1 = createL1ActionHash(action: action, nonce: nonce);
      final hash2 = createL1ActionHash(action: action, nonce: nonce);
      expect(hash1, hash2);
    });

    test('different nonces produce different hashes', () {
      final action = {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10};

      final hash1 = createL1ActionHash(action: action, nonce: 1000);
      final hash2 = createL1ActionHash(action: action, nonce: 2000);
      expect(hash1, isNot(hash2));
    });

    test('different actions produce different hashes', () {
      const nonce = 1234567890;

      final hash1 = createL1ActionHash(
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: nonce,
      );
      final hash2 = createL1ActionHash(
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 20},
        nonce: nonce,
      );
      expect(hash1, isNot(hash2));
    });

    test('vault address changes the hash', () {
      final action = {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10};
      const nonce = 1234567890;

      final hashNoVault = createL1ActionHash(action: action, nonce: nonce);
      final hashWithVault = createL1ActionHash(
        action: action,
        nonce: nonce,
        vaultAddress: '0x1234567890abcdef1234567890abcdef12345678',
      );
      expect(hashNoVault, isNot(hashWithVault));
    });

    test('null vault and empty vault produce the same hash', () {
      final action = {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10};
      const nonce = 1234567890;

      final hashNull = createL1ActionHash(action: action, nonce: nonce);
      final hashEmpty = createL1ActionHash(
        action: action,
        nonce: nonce,
        vaultAddress: '',
      );
      expect(hashNull, hashEmpty);
    });
  });
}
