import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/widgets/torico_account_identity.dart';
import 'package:torico/screens/settings_screen.dart';

class IdentityProvider extends Fake implements UserInfo {
  @override
  final String providerId;
  IdentityProvider(this.providerId);
}

class IdentityUser extends Fake implements User {
  @override
  String get email => 'account@example.invalid';
  @override
  String get displayName => 'Pessoa de teste';
  @override
  List<UserInfo> get providerData => [
    IdentityProvider('google.com'),
    IdentityProvider('password'),
  ];
  @override
  String get uid => throw StateError('Display must not read UID');
}

void main() {
  test('display reads public profile/providers only, never UID', () {
    final identity = ToricoAccountIdentity.fromUser(IdentityUser());
    expect(identity.email, 'account@example.invalid');
    expect(identity.name, 'Pessoa de teste');
    expect(identity.loginMethods, 'Google · E-mail e senha');
    expect(const ToricoAccountIdentity().loginMethods, 'Conta autenticada');
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('account profile wraps at $width without IDs', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToricoAccountIdentityCard(
              identity: ToricoAccountIdentity.fromUser(IdentityUser()),
            ),
          ),
        ),
      );
      expect(find.text('Conta TORICO'), findsOneWidget);
      expect(find.text('account@example.invalid'), findsOneWidget);
      expect(find.text('Pessoa de teste'), findsOneWidget);
      expect(find.textContaining('Google · E-mail e senha'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('missing profile does not invent name/email', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ToricoAccountIdentityCard(identity: null)),
      ),
    );
    expect(find.text('E-mail não disponível'), findsOneWidget);
  });
  testWidgets(
    'account labels cloud connection and OAuth, local actions stay distinct',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            plataforma: 'Mercado Pago',
            platformLoader: () async => ['Mercado Pago'],
            accountIdentityLoader: () =>
                ToricoAccountIdentity.fromUser(IdentityUser()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Conta TORICO'), findsOneWidget);
      expect(find.text('Conectadas à sua conta TORICO'), findsOneWidget);
      expect(find.text('Conectadas neste dispositivo'), findsNothing);
      expect(
        find.textContaining('Conta Mercado Pago autorizada.'),
        findsOneWidget,
      );
      expect(find.textContaining('OAuth e webhooks oficiais'), findsOneWidget);
      await tester.ensureVisible(find.text('Desconectar Mercado Pago'));
      await tester.tap(find.text('Desconectar Mercado Pago'));
      await tester.pumpAndSettle();
      expect(find.textContaining('em todos os dispositivos'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não desconecta Mercado Pago.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mantém as integrações na nuvem.'),
        findsOneWidget,
      );
    },
  );
}
