@Tags(['integration'])
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

/// Integration tests for l2Book WebSocket aggregation (nSigFigs / mantissa).
///
/// Tests the fix where mantissa was sent as JSON string instead of integer,
/// causing Hyperliquid to ignore it. No private key needed — l2Book is public.
///
/// Run with:
///   dart test test/websocket/l2book_aggregation_test.dart --tags integration --reporter expanded
void main() {
  group('l2Book aggregation integration', () {
    late WebSocketClient ws;

    setUp(() async {
      ws = WebSocketClient(isTestnet: false);
      await ws.connect();
      // Brief pause for connection to stabilise
      await Future.delayed(const Duration(milliseconds: 500));
    });

    tearDown(() async {
      await ws.dispose();
    });

    // ── Helper ──────────────────────────────────────────────────────────────

    /// Subscribe and wait for the first L2Book update, then cancel.
    Future<L2Book> _awaitBook({
      int? nSigFigs,
      String? mantissa,
      String coin = 'BTC',
    }) async {
      final completer = Completer<L2Book>();
      final handle = ws.subscribeL2Book(
        coin,
        (book) {
          if (!completer.isCompleted) completer.complete(book);
        },
        nSigFigs: nSigFigs,
        mantissa: mantissa,
      );

      final book = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'No l2Book update received (coin=$coin nSigFigs=$nSigFigs mantissa=$mantissa)',
        ),
      );

      await handle.cancel();
      return book;
    }

    /// Returns the number of integer digits in a price string (e.g. "113377.0" → 6).
    int _intDigits(String priceStr) {
      final dot = priceStr.indexOf('.');
      return dot >= 0 ? dot : priceStr.length;
    }

    // ── Tests ───────────────────────────────────────────────────────────────

    test('default subscription receives valid l2Book data', () async {
      final book = await _awaitBook();

      print('\n📖 Default l2Book (BTC)');
      print('  Bids: ${book.bids.length}, Asks: ${book.asks.length}');
      if (book.bids.isNotEmpty) print('  Best bid: ${book.bids.first.price}');
      if (book.asks.isNotEmpty) print('  Best ask: ${book.asks.first.price}');

      expect(book.coin, equals('BTC'));
      expect(book.bids, isNotEmpty);
      expect(book.asks, isNotEmpty);
      // Prices should be valid numbers
      for (final level in [...book.bids, ...book.asks]) {
        expect(double.tryParse(level.price), isNotNull,
            reason: 'Price "${level.price}" should be parseable');
      }
    });

    test('nSigFigs=4 produces prices rounded to correct tick size', () async {
      const nSigFigs = 4;
      final book = await _awaitBook(nSigFigs: nSigFigs);

      expect(book.bids, isNotEmpty);

      // Compute expected tick from the first bid price
      final firstBidDigits = _intDigits(book.bids.first.price);
      final tickSize = math.pow(10, firstBidDigits - nSigFigs).toDouble();

      print('\n📖 l2Book BTC nSigFigs=$nSigFigs');
      print('  First bid: ${book.bids.first.price}');
      print('  Int digits: $firstBidDigits  →  expected tick: $tickSize');
      print('  Sample prices: ${book.bids.take(5).map((l) => l.price).join(', ')}');

      // All prices must be multiples of the tick size
      for (final level in [...book.bids, ...book.asks]) {
        final px = double.parse(level.price);
        final remainder = (px / tickSize).round() * tickSize - px;
        expect(remainder.abs(), lessThan(tickSize * 0.01),
            reason:
                'Price $px should be a multiple of tick $tickSize (nSigFigs=$nSigFigs)');
      }
    });

    test('nSigFigs=3 produces coarser prices than nSigFigs=5', () async {
      final precise = await _awaitBook(nSigFigs: 5);
      await Future.delayed(const Duration(milliseconds: 300));
      final coarse = await _awaitBook(nSigFigs: 3);

      final precisePrices =
          precise.bids.map((l) => double.parse(l.price)).toSet();
      final coarsePrices =
          coarse.bids.map((l) => double.parse(l.price)).toSet();

      print('\n📖 Precision comparison (BTC)');
      print('  nSigFigs=5 unique bid prices: ${precisePrices.length}');
      print('  nSigFigs=3 unique bid prices: ${coarsePrices.length}');

      // Coarser aggregation collapses more price levels → fewer unique prices
      expect(coarsePrices.length, lessThanOrEqualTo(precisePrices.length),
          reason:
              'nSigFigs=3 should have fewer or equal distinct prices than nSigFigs=5');
    });

    test('mantissa=2 produces prices at even multiples (tests SDK fix)', () async {
      // nSigFigs=5, mantissa=2 → tick = 2 for a 5-digit price (BTC ~113,000)
      // All prices should be even integers
      final book = await _awaitBook(nSigFigs: 5, mantissa: '2');

      expect(book.bids, isNotEmpty,
          reason: 'mantissa=2 subscription should receive data');

      final firstPrice = double.parse(book.bids.first.price);
      final intDigits = _intDigits(book.bids.first.price);

      // tick = 2 × 10^(intDigits - 5)
      final tick = 2.0 * math.pow(10, intDigits - 5).toDouble();

      print('\n📖 l2Book BTC nSigFigs=5 mantissa=2 (SDK fix test)');
      print('  First bid: ${book.bids.first.price}  (int digits: $intDigits)');
      print('  Expected tick: $tick');
      print(
          '  Sample bid prices: ${book.bids.take(5).map((l) => l.price).join(', ')}');

      for (final level in [...book.bids, ...book.asks]) {
        final px = double.parse(level.price);
        final remainder = (px / tick).round() * tick - px;
        expect(remainder.abs(), lessThan(tick * 0.01),
            reason:
                'Price $px should be a multiple of tick $tick (mantissa=2)');
      }

      print('\n✓ mantissa=2 tick size verified — SDK fix is working');
    });

    test('mantissa=5 produces prices at ×5 multiples', () async {
      final book = await _awaitBook(nSigFigs: 5, mantissa: '5');

      expect(book.bids, isNotEmpty,
          reason: 'mantissa=5 subscription should receive data');

      final intDigits = _intDigits(book.bids.first.price);
      final tick = 5.0 * math.pow(10, intDigits - 5).toDouble();

      print('\n📖 l2Book BTC nSigFigs=5 mantissa=5');
      print('  First bid: ${book.bids.first.price}  tick: $tick');

      for (final level in [...book.bids, ...book.asks]) {
        final px = double.parse(level.price);
        final remainder = (px / tick).round() * tick - px;
        expect(remainder.abs(), lessThan(tick * 0.01),
            reason: 'Price $px should be a multiple of tick $tick (mantissa=5)');
      }
    });

    test('resubscribe after cancel delivers new data', () async {
      // First subscription
      final book1 = await _awaitBook(nSigFigs: 5);
      print('\n📖 First subscription (nSigFigs=5): got ${book1.bids.length} bids');

      // Delay to ensure cancel is clean
      await Future.delayed(const Duration(milliseconds: 300));

      // Second subscription at different aggregation
      final book2 = await _awaitBook(nSigFigs: 3);
      print('📖 Resubscription (nSigFigs=3): got ${book2.bids.length} bids');

      expect(book2.bids, isNotEmpty,
          reason: 'Should receive data after resubscribing with different params');
      print('✓ Resubscribe after cancel works');
    });

    test('cancelled subscription stops receiving data', () async {
      var callCount = 0;
      final completer = Completer<void>();

      final handle = ws.subscribeL2Book('BTC', (book) {
        callCount++;
        if (!completer.isCompleted) completer.complete();
      });

      // Wait for first message to confirm subscription is live
      await completer.future.timeout(const Duration(seconds: 15));
      print('\n📖 Subscription received $callCount update(s) before cancel');

      await handle.cancel();
      final countAtCancel = callCount;

      // Wait and verify no more calls
      await Future.delayed(const Duration(seconds: 3));

      expect(callCount, equals(countAtCancel),
          reason: 'No updates should arrive after cancel');
      print('✓ Handler not called after cancel (count stayed at $countAtCancel)');
    });
  });
}
