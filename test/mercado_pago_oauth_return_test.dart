import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/screens/auth_screen.dart';
import 'package:torico/screens/connected_screen.dart';
import 'package:torico/services/integration_service.dart';
import 'package:torico/services/mercado_pago_oauth_return.dart';

class FakeReturnIntegration extends IntegrationService {
  final bool connected;
  int checks = 0;
  FakeReturnIntegration(this.connected);
  @override
  Future<bool> connect(String plataforma) async => true;
  @override
  Future<bool> isPlatformConnected(String plataforma) async {
    checks++;
    return connected;
  }
}

void main() {
  testWidgets('original OAuth tab verifies automatically when resumed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeReturnIntegration(true);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          plataforma: 'Mercado Pago',
          integrationService: service,
        ),
      ),
    );
    await tester.ensureVisible(find.text('Abrir Mercado Pago'));
    await tester.tap(find.text('Abrir Mercado Pago'));
    await tester.pumpAndSettle();
    expect(service.checks, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(service.checks, 1);
    expect(find.byType(ConnectedScreen), findsOneWidget);
  });

  testWidgets(
    'OAuth error offers manual verification without claiming success',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeReturnIntegration(false);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            plataforma: 'Mercado Pago',
            oauthReturn: const MercadoPagoOAuthReturn(reportedConnected: false),
            integrationService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.checks, 0);
      expect(find.byType(ConnectedScreen), findsNothing);
      expect(find.text('Verificar conexão'), findsOneWidget);
      expect(
        find.textContaining('Não foi possível concluir a autorização.'),
        findsOneWidget,
      );
    },
  );
  test('parses return and clears only callback parameters', () {
    final uri = Uri.parse(
      'https://app.meutorico.com.br/?integration=mercado_pago&status=connected&v=123#app',
    );
    expect(MercadoPagoOAuthReturn.parse(uri)?.reportedConnected, isTrue);
    expect(
      MercadoPagoOAuthReturn.cleanedUrl(uri).toString(),
      'https://app.meutorico.com.br/?v=123#app',
    );
    expect(
      MercadoPagoOAuthReturn.cleanedUrl(
        Uri.parse(
          'https://app.meutorico.com.br/?integration=mercado_pago&status=connected',
        ),
      ).hasQuery,
      isFalse,
    );
    expect(
      MercadoPagoOAuthReturn.parse(
        Uri.parse(
          'https://app.meutorico.com.br/?integration=mercado_pago&status=error',
        ),
      )?.reportedConnected,
      isFalse,
    );
    for (final query in [
      'integration=rede&status=connected',
      'integration=mercado_pago&status=connected&status=error',
      'integration=mercado_pago',
    ]) {
      expect(
        MercadoPagoOAuthReturn.parse(
          Uri.parse('https://app.meutorico.com.br/?$query'),
        ),
        isNull,
      );
    }
  });

  for (final connected in [true, false]) {
    testWidgets('return checks saved integration, connected=$connected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeReturnIntegration(connected);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            plataforma: 'Mercado Pago',
            oauthReturn: const MercadoPagoOAuthReturn(reportedConnected: true),
            integrationService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.checks, 1);
      expect(
        find.byType(ConnectedScreen),
        connected ? findsOneWidget : findsNothing,
      );
      if (!connected) {
        expect(find.text('Verificar conexão'), findsOneWidget);
        expect(
          find.textContaining('Integração ainda não concluída.'),
          findsWidgets,
        );
      }
    });
  }
}
