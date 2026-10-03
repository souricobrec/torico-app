import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/screens/auth_screen.dart';
import 'package:torico/services/mercado_pago_oauth_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
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
    'opens OAuth immediately in external browser/new tab with Firebase UID',
    () async {
      Uri? opened;
      LaunchMode? usedMode;
      String? window;
      final launcher = MercadoPagoOAuthLauncher(
        apiBaseUrl: 'https://api.meutorico.com.br',
        launcher:
            (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) {
              opened = uri;
              usedMode = mode;
              window = webOnlyWindowName;
              return Future.value(true);
            },
      );
      final result = launcher.open('firebase-uid');
      // Opening must start synchronously, before losing browser user activation.
      expect(opened?.origin, 'https://api.meutorico.com.br');
      expect(opened?.path, '/integrations/mercado-pago/connect');
      expect(opened?.queryParameters, {'userId': 'firebase-uid'});
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
    expect(await launcher.open('firebase-uid'), isFalse);
  });
}
