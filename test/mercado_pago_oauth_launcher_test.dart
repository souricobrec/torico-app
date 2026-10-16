import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/screens/auth_screen.dart';
import 'package:torico/services/mercado_pago_oauth_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test(
    'OAuth quota does not misclassify a valid session as invalid login',
    () async {
      final launcher = MercadoPagoOAuthLauncher(
        client: MockClient((_) async => http.Response('{}', 429)),
      );
      await expectLater(
        launcher.prepare('fixture'),
        throwsA(
          predicate<Object>(
            (error) =>
                error.toString().contains('Muitas tentativas') &&
                !error.toString().contains('Entre novamente'),
          ),
        ),
      );
    },
  );
  testWidgets('Mercado Pago explains external camera flow before opening', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AuthScreen(plataforma: 'Mercado Pago')),
    );
    expect(
      find.text(
        'Você será direcionado ao Mercado Pago para autorizar a integração. Se for solicitada verificação por câmera, conclua pelo navegador externo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Abrir Mercado Pago'), findsOneWidget);
  });
  test(
    'authenticates preparation then opens trusted OAuth in explicit user gesture',
    () async {
      Uri? opened;
      LaunchMode? usedMode;
      String? window;
      final launcher = MercadoPagoOAuthLauncher(
        apiBaseUrl: 'https://api.meutorico.com.br',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.queryParameters, isEmpty);
          expect(request.headers['Authorization'], 'Bearer fixture-token');
          return http.Response(
            '{"authorizationUrl":"https://auth.mercadopago.com.br/authorization?state=fixture"}',
            200,
          );
        }),
        launcher:
            (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) {
              opened = uri;
              usedMode = mode;
              window = webOnlyWindowName;
              return Future.value(true);
            },
      );
      final uri = await launcher.prepare('fixture-token');
      expect(opened, isNull);
      final result = launcher.open(uri);
      // Opening must start synchronously, before losing browser user activation.
      expect(opened?.origin, 'https://auth.mercadopago.com.br');
      expect(opened?.path, '/authorization');
      expect(opened?.queryParameters, {'state': 'fixture'});
      expect(usedMode, LaunchMode.externalApplication);
      expect(window, '_blank');
      expect(await result, isTrue);
    },
  );

  test('does not claim success when external browser cannot open', () async {
    final launcher = MercadoPagoOAuthLauncher(
      launcher: (_, {mode = LaunchMode.platformDefault, webOnlyWindowName}) =>
          Future.value(false),
    );
    expect(
      await launcher.open(
        Uri.parse('https://auth.mercadopago.com.br/authorization'),
      ),
      isFalse,
    );
  });
  test(
    'invalid preparation never opens a browser or leaks response content',
    () async {
      for (final response in [
        http.Response('private upstream detail', 401),
        http.Response('private upstream detail', 200),
        http.Response(
          '{"authorizationUrl":"https://attacker.example/authorization"}',
          200,
        ),
        http.Response(
          '{"authorizationUrl":"https://auth.mercadopago.com.br:444/authorization"}',
          200,
        ),
      ]) {
        final launcher = MercadoPagoOAuthLauncher(
          client: MockClient((_) async => response),
          launcher:
              (
                _, {
                mode = LaunchMode.platformDefault,
                webOnlyWindowName,
              }) async => fail('must not launch'),
        );
        await expectLater(
          launcher.prepare('fixture'),
          throwsA(
            predicate<Object>(
              (error) => !error.toString().contains('private upstream detail'),
            ),
          ),
        );
      }
    },
  );
}
