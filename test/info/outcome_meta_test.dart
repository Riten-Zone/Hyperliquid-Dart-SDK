import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HIP-4 outcome metadata', () {
    test('outcomeMeta posts documented request and parses metadata', () async {
      final transport = _FakeInfoTransport({
        'outcomes': [
          {
            'outcome': 171,
            'name': 'Fallback',
            'description': '',
            'sideSpecs': [
              {'name': 'Yes'},
              {'name': 'No'},
            ],
            'quoteToken': 'USDC',
          },
        ],
        'questions': [
          {
            'question': 126,
            'name': 'Recurring',
            'description': 'class:priceBucket|underlying:BTC',
            'fallbackOutcome': 661,
            'namedOutcomes': [662, 663, 664],
            'settledNamedOutcomes': [],
          },
        ],
      });
      final info = InfoClient(transport: transport);

      final meta = await info.outcomeMeta();

      expect(transport.requests, [
        {'type': 'outcomeMeta'},
      ]);
      expect(meta.outcomes, hasLength(1));
      expect(meta.outcomes.first.outcome, 171);
      expect(meta.outcomes.first.name, 'Fallback');
      expect(meta.outcomes.first.quoteToken, 'USDC');
      expect(meta.outcomes.first.sideSpecs.map((s) => s.name), ['Yes', 'No']);
      expect(meta.questions, hasLength(1));
      expect(meta.questions.first.question, 126);
      expect(meta.questions.first.fallbackOutcome, 661);
      expect(meta.questions.first.namedOutcomes, [662, 663, 664]);
      expect(meta.raw.containsKey('outcomes'), isTrue);
    });

    test(
      'settledOutcome posts outcome id and handles unsettled null',
      () async {
        final transport = _FakeInfoTransport(null);
        final info = InfoClient(transport: transport);

        final settled = await info.settledOutcome(171);

        expect(settled, isNull);
        expect(transport.requests, [
          {'type': 'settledOutcome', 'outcome': 171},
        ]);
      },
    );

    test('settledOutcome parses settlement payload when present', () async {
      final transport = _FakeInfoTransport({
        'outcome': 171,
        'settleFraction': '1.0',
      });
      final info = InfoClient(transport: transport);

      final settled = await info.settledOutcome(171);

      expect(settled, isNotNull);
      expect(settled!.outcome, 171);
      expect(settled.settleFraction, '1.0');
      expect(settled.raw['settleFraction'], '1.0');
    });
  });
}

class _FakeInfoTransport extends HttpTransport {
  final dynamic response;
  final requests = <Map<String, dynamic>>[];

  _FakeInfoTransport(this.response);

  @override
  Future<dynamic> postInfo(Map<String, dynamic> payload) async {
    requests.add(Map<String, dynamic>.from(payload));
    return response;
  }
}
