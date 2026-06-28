@Tags(['integration'])
library;

import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HIP-4 outcome metadata integration', () {
    late InfoClient info;

    setUpAll(() {
      info = InfoClient();
    });

    tearDownAll(() {
      info.close();
    });

    test(
      'fetches live outcome metadata and checks settlement endpoint',
      () async {
        final meta = await info.outcomeMeta();

        expect(meta.outcomes, isNotEmpty);
        expect(meta.questions, isNotEmpty);

        final firstOutcome = meta.outcomes.first;
        expect(firstOutcome.outcome, greaterThanOrEqualTo(0));
        expect(firstOutcome.name, isNotEmpty);
        expect(firstOutcome.sideSpecs, isNotEmpty);
        expect(firstOutcome.quoteToken, isNotEmpty);

        final firstQuestion = meta.questions.first;
        expect(firstQuestion.question, greaterThanOrEqualTo(0));
        expect(firstQuestion.name, isNotEmpty);
        expect(firstQuestion.namedOutcomes, isNotEmpty);

        final settled = await info.settledOutcome(firstOutcome.outcome);
        expect(settled, isA<SettledOutcome?>());

        print(
          'Live HIP-4 outcomeMeta: '
          '${meta.outcomes.length} outcomes, ${meta.questions.length} questions',
        );
        print(
          'Sample outcome: '
          '${firstOutcome.outcome} ${firstOutcome.name} '
          'sides=${firstOutcome.sideSpecs.map((s) => s.name).join('/')} '
          'quote=${firstOutcome.quoteToken}',
        );
        print(
          'Sample question: '
          '${firstQuestion.question} ${firstQuestion.name} '
          'outcomes=${firstQuestion.namedOutcomes.take(5).join(',')}',
        );
        print(
          'settledOutcome(${firstOutcome.outcome}): '
          '${settled == null ? 'unsettled/null' : settled.raw.keys.join(',')}',
        );
      },
    );
  });
}
