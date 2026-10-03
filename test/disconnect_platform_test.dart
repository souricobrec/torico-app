import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/screens/settings_screen.dart';
import 'package:torico/services/local_storage_service.dart';
import 'package:torico/services/platform_disconnect_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('disconnect sends Firebase token and never sends client UID', () async {
    final service = PlatformDisconnectService(
      tokenLoader: () async => 'firebase-id-token',
      client: MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/integrations/mercado_pago/disconnect');
        expect(req.url.query, isEmpty);
        expect(req.body, isEmpty);
        expect(req.headers['Authorization'], 'Bearer firebase-id-token');
        return http.Response('{"ok":true}', 200);
      }),
    );
    await service.disconnect('mercado_pago');
    await expectLater(service.disconnect('rede'), throwsException);
  });

  test(
    'missing token and backend failure cannot report successful disconnect',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('', 503);
      });
      await expectLater(
        PlatformDisconnectService(
          client: client,
          tokenLoader: () async => null,
        ).disconnect('mercado_pago'),
        throwsException,
      );
      expect(requests, 0);
      await expectLater(
        PlatformDisconnectService(
          client: client,
          tokenLoader: () async => 'token',
        ).disconnect('mercado_pago'),
        throwsException,
      );
    },
  );

  testWidgets(
    'logout preserves local connected status and never disconnects cloud platform',
    (tester) async {
      final storage = LocalStorageService();
      await storage.saveConnectedPlatforms(['Mercado Pago']);
      var logouts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            plataforma: 'Mercado Pago',
            platformLoader: () async => ['Mercado Pago'],
            signOut: () async {
              logouts++;
            },
            disconnectPlatform: (_) async => fail('logout must not disconnect'),
            loginBuilder: (_) => const Scaffold(body: Text('Login')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sair da conta'));
      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(logouts, 1);
      expect(await storage.getConnectedPlatforms(), ['Mercado Pago']);
      expect(find.text('Login'), findsOneWidget);
    },
  );

  testWidgets(
    'platform disconnect confirms, clears only that platform and opens connection choice',
    (tester) async {
      final storage = LocalStorageService();
      await storage.saveConnectedPlatforms(['Mercado Pago']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('total_sold', 1);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            plataforma: 'Mercado Pago',
            platformLoader: () async => ['Mercado Pago', 'Rede'],
            disconnectPlatform: (platform) async {
              expect(platform, 'mercado_pago');
              calls++;
            },
            signOut: () async => fail('disconnect must keep TORICO login'),
            connectionBuilder: (_) =>
                const Scaffold(body: Text('Escolher conexão')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.text('Desconectar Mercado Pago');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('histórico já salvo será mantido'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desconectar'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(await storage.getConnectedPlatforms(), isEmpty);
      expect(prefs.getDouble('total_sold'), 1);
      expect(find.text('Escolher conexão'), findsOneWidget);
      expect(find.text('Desconectar Mercado Pago'), findsNothing);
    },
  );

  testWidgets(
    'failed disconnect retains connected platform and shows friendly error',
    (tester) async {
      final storage = LocalStorageService();
      await storage.saveConnectedPlatforms(['Mercado Pago']);
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            plataforma: 'Mercado Pago',
            platformLoader: () async => ['Mercado Pago'],
            disconnectPlatform: (_) async => throw Exception('private error'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Desconectar Mercado Pago'));
      await tester.tap(find.text('Desconectar Mercado Pago'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desconectar'));
      await tester.pumpAndSettle();
      expect(await storage.getConnectedPlatforms(), ['Mercado Pago']);
      expect(
        find.text(
          'Não foi possível desconectar Mercado Pago. Tente novamente.',
        ),
        findsOneWidget,
      );
    },
  );
}
