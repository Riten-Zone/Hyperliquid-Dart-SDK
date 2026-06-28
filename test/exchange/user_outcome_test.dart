import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HIP-4 userOutcome actions', () {
    late _MockWallet wallet;
    late _FakeExchangeTransport transport;
    late ExchangeClient exchange;

    setUp(() {
      wallet = _MockWallet();
      transport = _FakeExchangeTransport();
      exchange = ExchangeClient(wallet: wallet, transport: transport);
    });

    test('splitOutcome sends exact userOutcome payload', () async {
      await exchange.splitOutcome(outcome: 171, amount: '1.25');

      expect(_lastAction(transport), {
        'type': 'userOutcome',
        'splitOutcome': {'outcome': 171, 'amount': '1.25'},
      });
    });

    test('mergeOutcome sends exact userOutcome payload', () async {
      await exchange.mergeOutcome(outcome: 171, amount: '1.25');

      expect(_lastAction(transport), {
        'type': 'userOutcome',
        'mergeOutcome': {'outcome': 171, 'amount': '1.25'},
      });
    });

    test('mergeOutcome keeps null amount for max merge', () async {
      await exchange.mergeOutcome(outcome: 171);

      expect(_lastAction(transport), {
        'type': 'userOutcome',
        'mergeOutcome': {'outcome': 171, 'amount': null},
      });
    });

    test('mergeQuestion sends exact userOutcome payload', () async {
      await exchange.mergeQuestion(question: 32, amount: '1.25');

      expect(_lastAction(transport), {
        'type': 'userOutcome',
        'mergeQuestion': {'question': 32, 'amount': '1.25'},
      });
    });

    test('mergeQuestion keeps null amount for max merge', () async {
      await exchange.mergeQuestion(question: 32);

      expect(_lastAction(transport), {
        'type': 'userOutcome',
        'mergeQuestion': {'question': 32, 'amount': null},
      });
    });

    test('negateOutcome sends exact userOutcome payload', () async {
      await exchange.negateOutcome(question: 32, outcome: 171, amount: '1.25');

      expect(_lastAction(transport), {
        'type': 'userOutcome',
        'negateOutcome': {'question': 32, 'outcome': 171, 'amount': '1.25'},
      });
    });

    test(
      'raw userOutcome forwards operation for future compatibility',
      () async {
        await exchange.userOutcome({
          'splitOutcome': {'outcome': 171, 'amount': '1'},
        });

        expect(_lastAction(transport), {
          'type': 'userOutcome',
          'splitOutcome': {'outcome': 171, 'amount': '1'},
        });
      },
    );
  });
}

Map<String, dynamic> _lastAction(_FakeExchangeTransport transport) {
  expect(transport.requests, isNotEmpty);
  final request = transport.requests.last;
  expect(request['nonce'], isA<int>());
  expect(request['signature'], isA<Map<String, dynamic>>());
  return request['action'] as Map<String, dynamic>;
}

class _MockWallet implements WalletAdapter {
  static final _fakeSignature = '0x${'0' * 128}1b';

  @override
  Future<String> getAddress() async =>
      '0x0000000000000000000000000000000000000001';

  @override
  Future<String> signTypedData(Map<String, dynamic> typedData) async {
    return _fakeSignature;
  }
}

class _FakeExchangeTransport extends HttpTransport {
  final requests = <Map<String, dynamic>>[];

  @override
  Future<dynamic> postExchange(Map<String, dynamic> payload) async {
    requests.add(Map<String, dynamic>.from(payload));
    return {
      'status': 'ok',
      'response': {'type': 'default'},
    };
  }
}
