@Tags(['integration'])
library;

import 'dart:async';
import 'dart:io';

import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('WebSocket parity real-time integration', () {
    WebSocketClient? ws;
    late String userAddress;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();

      ws = WebSocketClient();
      await ws!.connect();
      await Future.delayed(const Duration(milliseconds: 500));

      print('\nWebSocket parity integration account: $userAddress');
    });

    tearDownAll(() async {
      await ws?.dispose();
    });

    test('receives real public subscription payloads', () async {
      final received = <String, Map<String, dynamic>>{};
      final handles = <SubscriptionHandle>[];

      void record(String key, Map<String, dynamic> data) {
        received.putIfAbsent(key, () => data);
      }

      handles.add(
        ws!.subscribeActiveAssetCtx(
          'BTC',
          (data) => record('activeAssetCtx', data),
        ),
      );
      handles.add(ws!.subscribeAssetCtxs((data) => record('assetCtxs', data)));
      handles.add(
        ws!.subscribeAllDexsAssetCtxs(
          (data) => record('allDexsAssetCtxs', data),
        ),
      );
      handles.add(
        ws!.subscribeSpotAssetCtxs((data) => record('spotAssetCtxs', data)),
      );
      handles.add(
        ws!.subscribeOutcomeMetaUpdates(
          (data) => record('outcomeMetaUpdates', data),
        ),
      );

      await _waitForAtLeast(received, 3, const Duration(seconds: 20));

      expect(received.length, greaterThanOrEqualTo(3));
      for (final entry in received.entries) {
        expect(entry.value['channel'], isA<String>());
        expect(entry.value.containsKey('data'), isTrue);
        print(
          'Received ${entry.key}: channel=${entry.value['channel']}, '
          'data=${_describePayload(entry.value['data'])}',
        );
      }

      for (final handle in handles) {
        await handle.cancel();
      }
    });

    test('receives real user snapshot payloads for .env account', () async {
      final received = <String, Map<String, dynamic>>{};
      final handles = <SubscriptionHandle>[];

      void record(String key, Map<String, dynamic> data) {
        received.putIfAbsent(key, () => data);
      }

      handles.add(
        ws!.subscribeClearinghouseState(
          userAddress,
          (data) => record('clearinghouseState', data),
        ),
      );
      handles.add(
        ws!.subscribeOpenOrders(
          userAddress,
          (data) => record('openOrders', data),
        ),
      );
      handles.add(
        ws!.subscribeSpotState(
          userAddress,
          (data) => record('spotState', data),
        ),
      );
      handles.add(
        ws!.subscribeAllDexsClearinghouseState(
          userAddress,
          (data) => record('allDexsClearinghouseState', data),
        ),
      );
      handles.add(
        ws!.subscribeWebData2(userAddress, (data) => record('webData2', data)),
      );
      handles.add(
        ws!.subscribeUserHistoricalOrders(
          userAddress,
          (data) => record('userHistoricalOrders', data),
        ),
      );

      await _waitForAtLeast(received, 3, const Duration(seconds: 20));

      expect(received.length, greaterThanOrEqualTo(3));
      for (final entry in received.entries) {
        expect(entry.value['channel'], isA<String>());
        expect(entry.value.containsKey('data'), isTrue);
        print(
          'Received ${entry.key}: channel=${entry.value['channel']}, '
          'data=${_describePayload(entry.value['data'])}',
        );
      }

      for (final handle in handles) {
        await handle.cancel();
      }
    });
  });
}

String _describePayload(Object? payload) {
  if (payload is Map) {
    return 'Map(keys=${payload.keys.take(12).join(', ')})';
  }

  if (payload is List) {
    if (payload.isEmpty) return 'List(length=0)';

    final first = payload.first;
    if (first is Map) {
      return 'List(length=${payload.length}, firstKeys=${first.keys.take(12).join(', ')})';
    }

    return 'List(length=${payload.length}, firstType=${first.runtimeType})';
  }

  return payload.runtimeType.toString();
}

Future<void> _waitForAtLeast(
  Map<String, Map<String, dynamic>> received,
  int count,
  Duration timeout,
) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (received.length >= count) return;
    await Future.delayed(const Duration(milliseconds: 250));
  }

  fail(
    'Timed out waiting for $count real WebSocket payloads '
    '(received ${received.length}: ${received.keys.join(', ')})',
  );
}
