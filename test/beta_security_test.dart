import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/config/firebase_environment.dart';
import 'package:torico/services/local_storage_service.dart';
import 'package:torico/services/domain_block_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'UID/project cache isolation, stale instances, recovery and anonymous legacy cache',
    () async {
      SharedPreferences.setMockInitialValues({
        'total_sold': 900.0,
        'connected_platform': 'Mercado Pago',
      });
      String? identity = 'demo-a/user-a';
      LocalStorageService storage() =>
          LocalStorageService(identity: () => identity);
      final a = storage();
      expect(await a.getTotalSold(), 0);
      expect(await a.getConnectedPlatforms(), isEmpty);
      await a.saveTotalSold(42);
      await a.saveConnectedPlatforms(['Mercado Pago']);
      identity = 'demo-a/user-b';
      final b = storage();
      expect(await b.getTotalSold(), 0);
      expect(await b.getConnectedPlatforms(), isEmpty);
      expect(await a.getTotalSold(), 0);
      await a.saveTotalSold(999); // late callback from disposed user A
      await b.saveTotalSold(7);
      identity = null;
      expect(await b.getTotalSold(), 0);
      expect(await storage().getConnectedPlatforms(), isEmpty);
      identity = 'demo-a/user-a';
      expect(await storage().getTotalSold(), 42);
      identity = 'demo-b/user-a';
      expect(await storage().getTotalSold(), 0);
      identity = 'demo-a/user-b';
      expect(await storage().getTotalSold(), 7);
      await storage().clearDeviceData();
      identity = 'demo-a/user-a';
      expect(await storage().getTotalSold(), 0);
      expect(await storage().getConnectedPlatforms(), isEmpty);
    },
  );

  const production = FirebaseOptions(
    apiKey: 'public',
    appId: 'public',
    messagingSenderId: '123',
    projectId: 'production-fixture',
  );
  test(
    'production cannot use emulator overrides; local demo cannot use production Firebase/API',
    () {
      FirebaseOptions resolve(
        String env,
        String project,
        String host,
        String api,
      ) => FirebaseEnvironment.resolve(
        environment: env,
        project: project,
        emulatorHost: host,
        apiBaseUrl: api,
        production: production,
      );
      expect(
        resolve('production', '', '', 'https://api.meutorico.com.br'),
        production,
      );
      expect(
        () => resolve(
          'production',
          'demo-local',
          'localhost',
          'http://localhost:3333',
        ),
        throwsStateError,
      );
      expect(
        () => resolve(
          'development',
          'torico-ca479',
          'localhost',
          'http://localhost:3333',
        ),
        throwsStateError,
      );
      expect(
        () => resolve(
          'development',
          'demo-local',
          'localhost',
          'https://api.meutorico.com.br',
        ),
        throwsStateError,
      );
      expect(
        resolve(
          'development',
          'demo-local',
          '10.0.2.2',
          'http://10.0.2.2:3333',
        ).projectId,
        'demo-local',
      );
    },
  );

  test('no host name bypasses the authenticated pilot gate', () {
    for (final host in [
      'localhost',
      'unknown.example',
      'x--visual-pre-lojas.evil',
      'app.meutorico.com.br',
    ]) {
      expect(DomainBlockService.shouldBlockHost(host), true);
    }
  });
}
