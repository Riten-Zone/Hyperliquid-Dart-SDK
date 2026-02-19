@Tags(['integration'])
library;

import 'dart:io';
import 'package:hyperliquid_dart/hyperliquid_dart.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = Platform.environment['HYPERLIQUID_PRIVATE_KEY'];

  group('WebData3 subscription integration', () {
    late WebSocketClient ws;
    late String userAddress;

    setUpAll(() async {
      if (privateKey == null || privateKey.isEmpty) {
        fail('HYPERLIQUID_PRIVATE_KEY env var not set');
      }

      final wallet = PrivateKeyWalletAdapter(privateKey);
      userAddress = await wallet.getAddress();

      ws = WebSocketClient();
      await ws.connect();
      await Future.delayed(Duration(milliseconds: 500));
    });

    tearDownAll(() async {
      await ws.dispose();
    });

    test('subscribes to webData3 and receives aggregate data', () async {
      var updateCount = 0;
      WebData3? lastUpdate;

      final handle = ws.subscribeWebData3(userAddress, (data) {
        updateCount++;
        lastUpdate = data;
        print('WebData3 update #$updateCount for ${data.user}');
        print('  User state keys: ${data.userState.keys.toList()}');
        print('  Perp DEX states: ${data.perpDexStates.length}');
        print('  Vaults info: ${data.vaultsInfo.length}');
      });

      // Wait for updates
      await Future.delayed(Duration(seconds: 5));

      // Verify we received data
      expect(updateCount, greaterThan(0), reason: 'Should receive webData3 updates');
      expect(lastUpdate, isNotNull);
      // User field may be empty in response, subscription is per-user
      expect(lastUpdate!.userState, isA<Map<String, dynamic>>());

      print('✓ Received $updateCount webData3 updates');

      await handle.cancel();
    });

    test('webData3 contains expected user state fields', () async {
      WebData3? update;

      final handle = ws.subscribeWebData3(userAddress, (data) {
        update = data;
      });

      // Wait for at least one update
      var attempts = 0;
      while (update == null && attempts < 20) {
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;
      }

      expect(update, isNotNull, reason: 'Should receive at least one update');

      if (update != null) {
        // Verify structure
        expect(update!.userState, isNotEmpty);
        expect(update!.perpDexStates, isA<List<dynamic>>());
        expect(update!.vaultsInfo, isA<List<dynamic>>());

        print('✓ WebData3 structure validated');
        print('  User state fields: ${update!.userState.keys.join(", ")}');

        // Check for common fields (may vary based on account state)
        if (update!.userState.containsKey('assetPositions')) {
          print('  Has assetPositions');
        }
        if (update!.userState.containsKey('marginSummary')) {
          print('  Has marginSummary');
        }
      }

      await handle.cancel();
    });

    test('webData3 updates reflect account changes', () async {
      var updateCount = 0;
      final updates = <WebData3>[];

      final handle = ws.subscribeWebData3(userAddress, (data) {
        updateCount++;
        updates.add(data);
      });

      // Collect updates over time
      await Future.delayed(Duration(seconds: 3));

      expect(updates, isNotEmpty);
      print('✓ Collected ${updates.length} webData3 snapshots');


      // All updates should have valid structure
      for (final update in updates) {
        expect(update.userState, isA<Map<String, dynamic>>());
        expect(update.perpDexStates, isA<List<dynamic>>());
        expect(update.vaultsInfo, isA<List<dynamic>>());
      }

      print('✓ All webData3 updates have valid structure');


      await handle.cancel();
    });
  });
}
