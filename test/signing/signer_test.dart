import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

/// A mock wallet that captures the typed data and returns a fake signature.
class MockWalletAdapter implements WalletAdapter {
  Map<String, dynamic>? lastTypedData;

  // Valid 65-byte signature (130 hex chars) — all zeros with v=27
  static final _fakeSignature =
      '0x${'0' * 128}1b'; // 64 bytes r + 64 bytes s + 1 byte v (0x1b = 27)

  @override
  Future<String> getAddress() async =>
      '0x0000000000000000000000000000000000000001';

  @override
  Future<String> signTypedData(Map<String, dynamic> typedData) async {
    lastTypedData = typedData;
    return _fakeSignature;
  }
}

void main() {
  group('signL1Action', () {
    late MockWalletAdapter mockWallet;

    setUp(() {
      mockWallet = MockWalletAdapter();
    });

    test('produces a valid SignatureComponents', () async {
      final sig = await signL1Action(
        wallet: mockWallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: false,
      );

      expect(sig.r, startsWith('0x'));
      expect(sig.s, startsWith('0x'));
      expect(sig.v, anyOf(27, 28));
    });

    test('passes correct EIP-712 domain for mainnet', () async {
      await signL1Action(
        wallet: mockWallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: false,
      );

      final domain = mockWallet.lastTypedData!['domain'] as Map<String, dynamic>;
      expect(domain['name'], 'Exchange');
      expect(domain['version'], '1');
      expect(domain['chainId'], 1337);
      expect(domain['verifyingContract'], '0x0000000000000000000000000000000000000000');
    });

    test('uses source "a" for mainnet', () async {
      await signL1Action(
        wallet: mockWallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: false,
      );

      final message = mockWallet.lastTypedData!['message'] as Map<String, dynamic>;
      expect(message['source'], 'a');
    });

    test('uses source "b" for testnet', () async {
      await signL1Action(
        wallet: mockWallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: true,
      );

      final message = mockWallet.lastTypedData!['message'] as Map<String, dynamic>;
      expect(message['source'], 'b');
    });

    test('connectionId is a 0x-prefixed bytes32 string', () async {
      await signL1Action(
        wallet: mockWallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: false,
      );

      final message = mockWallet.lastTypedData!['message'] as Map<String, dynamic>;
      final connectionId = message['connectionId'] as String;
      expect(connectionId, startsWith('0x'));
      expect(connectionId.length, 66); // 0x + 64 hex chars
    });

    test('primaryType is Agent', () async {
      await signL1Action(
        wallet: mockWallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: false,
      );

      expect(mockWallet.lastTypedData!['primaryType'], 'Agent');
    });

    test('types include EIP712Domain and Agent', () async {
      await signL1Action(
        wallet: mockWallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: false,
      );

      final types = mockWallet.lastTypedData!['types'] as Map<String, dynamic>;
      expect(types.containsKey('EIP712Domain'), isTrue);
      expect(types.containsKey('Agent'), isTrue);
    });
  });

  group('parseSignature', () {
    test('extracts r, s, v from a valid 65-byte signature', () {
      // Example: 64 bytes 'a', 64 bytes 'b', v=0x1b (27)
      final sig = '0x${'aa' * 32}${'bb' * 32}1b';
      final components = parseSignature(sig);

      expect(components.r, '0x${'aa' * 32}');
      expect(components.s, '0x${'bb' * 32}');
      expect(components.v, 27);
    });

    test('normalizes v=0 to v=27', () {
      final sig = '0x${'aa' * 32}${'bb' * 32}00';
      final components = parseSignature(sig);
      expect(components.v, 27);
    });

    test('normalizes v=1 to v=28', () {
      final sig = '0x${'aa' * 32}${'bb' * 32}01';
      final components = parseSignature(sig);
      expect(components.v, 28);
    });

    test('keeps v=27 as-is', () {
      final sig = '0x${'aa' * 32}${'bb' * 32}1b';
      final components = parseSignature(sig);
      expect(components.v, 27);
    });

    test('keeps v=28 as-is', () {
      final sig = '0x${'aa' * 32}${'bb' * 32}1c';
      final components = parseSignature(sig);
      expect(components.v, 28);
    });

    test('works without 0x prefix', () {
      final sig = '${'aa' * 32}${'bb' * 32}1b';
      final components = parseSignature(sig);
      expect(components.r, '0x${'aa' * 32}');
      expect(components.v, 27);
    });

    test('throws on invalid signature length', () {
      expect(() => parseSignature('0xdeadbeef'), throwsArgumentError);
    });

    test('toJson returns correct map', () {
      final sig = '0x${'aa' * 32}${'bb' * 32}1b';
      final components = parseSignature(sig);
      final json = components.toJson();

      expect(json['r'], '0x${'aa' * 32}');
      expect(json['s'], '0x${'bb' * 32}');
      expect(json['v'], 27);
    });
  });

  group('PrivateKeyWalletAdapter', () {
    // Well-known test private key (DO NOT USE WITH REAL FUNDS)
    // This is the standard Hardhat/Ganache test account #0
    const testPrivateKey =
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
    const expectedAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

    test('derives correct Ethereum address from private key', () async {
      final wallet = PrivateKeyWalletAdapter(testPrivateKey);
      final address = await wallet.getAddress();
      expect(address.toLowerCase(), expectedAddress.toLowerCase());
    });

    test('works without 0x prefix', () async {
      final wallet = PrivateKeyWalletAdapter(testPrivateKey.substring(2));
      final address = await wallet.getAddress();
      expect(address.toLowerCase(), expectedAddress.toLowerCase());
    });

    test('signTypedData returns a valid 65-byte signature', () async {
      final wallet = PrivateKeyWalletAdapter(testPrivateKey);

      final signature = await wallet.signTypedData({
        'domain': {
          'name': 'Exchange',
          'version': '1',
          'chainId': 1337,
          'verifyingContract': '0x0000000000000000000000000000000000000000',
        },
        'types': {
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
        },
        'primaryType': 'Agent',
        'message': {
          'source': 'a',
          'connectionId':
              '0x0000000000000000000000000000000000000000000000000000000000000000',
        },
      });

      expect(signature, startsWith('0x'));
      // 0x + 130 hex chars (65 bytes)
      expect(signature.length, 132);
    });

    test('signature is deterministic', () async {
      final wallet = PrivateKeyWalletAdapter(testPrivateKey);

      final typedData = {
        'domain': {
          'name': 'Exchange',
          'version': '1',
          'chainId': 1337,
          'verifyingContract': '0x0000000000000000000000000000000000000000',
        },
        'types': {
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
        },
        'primaryType': 'Agent',
        'message': {
          'source': 'a',
          'connectionId':
              '0x0000000000000000000000000000000000000000000000000000000000000000',
        },
      };

      final sig1 = await wallet.signTypedData(typedData);
      final sig2 = await wallet.signTypedData(typedData);
      expect(sig1, sig2);
    });

    test('end-to-end: signL1Action produces valid signature', () async {
      final wallet = PrivateKeyWalletAdapter(testPrivateKey);

      final sig = await signL1Action(
        wallet: wallet,
        action: {'type': 'updateLeverage', 'asset': 0, 'isCross': true, 'leverage': 10},
        nonce: 1700000000000,
        isTestnet: false,
      );

      expect(sig.r, startsWith('0x'));
      expect(sig.s, startsWith('0x'));
      expect(sig.v, anyOf(27, 28));

      // r and s should be 66 chars (0x + 64)
      expect(sig.r.length, 66);
      expect(sig.s.length, 66);
    });
  });
}
