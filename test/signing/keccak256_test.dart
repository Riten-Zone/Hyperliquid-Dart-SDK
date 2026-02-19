import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/digests/keccak.dart';
import 'package:test/test.dart';

/// Helper: keccak256 hash returning hex string.
String keccak256Hex(Uint8List data) {
  final digest = KeccakDigest(256);
  final hash = Uint8List(digest.digestSize);
  digest.update(data, 0, data.length);
  digest.doFinal(hash, 0);
  return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  group('Keccak-256 (Ethereum)', () {
    test('empty string matches Ethereum test vector', () {
      // Ethereum's keccak256 of empty bytes:
      // c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
      final hash = keccak256Hex(Uint8List(0));
      expect(
        hash,
        'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470',
      );
    });

    test('"abc" matches Ethereum test vector', () {
      // keccak256("abc") = 4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
      final hash = keccak256Hex(Uint8List.fromList(utf8.encode('abc')));
      expect(
        hash,
        '4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45',
      );
    });

    test('does NOT produce NIST SHA-3 output', () {
      // NIST SHA-3-256 of empty string:
      // a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a
      // Our implementation should NOT match this — we use Keccak, not SHA-3.
      final hash = keccak256Hex(Uint8List(0));
      expect(
        hash,
        isNot(
          'a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a',
        ),
      );
    });

    test('"abc" does NOT produce NIST SHA-3 output', () {
      // NIST SHA-3-256("abc") = 3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532
      final hash = keccak256Hex(Uint8List.fromList(utf8.encode('abc')));
      expect(
        hash,
        isNot(
          '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532',
        ),
      );
    });

    test('produces 32-byte (64 hex char) output', () {
      final hash = keccak256Hex(Uint8List.fromList([1, 2, 3]));
      expect(hash.length, 64);
    });

    test('different inputs produce different outputs', () {
      final hash1 = keccak256Hex(Uint8List.fromList([1]));
      final hash2 = keccak256Hex(Uint8List.fromList([2]));
      expect(hash1, isNot(hash2));
    });
  });
}
