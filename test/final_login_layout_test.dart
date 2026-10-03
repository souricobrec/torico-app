import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/widgets/official_login_layout.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('official login order, callbacks and scrolling at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final email = TextEditingController();
      final password = TextEditingController();
      addTearDown(email.dispose);
      addTearDown(password.dispose);
      var google = 0;
      var login = 0;
      var reset = 0;
      var register = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: OfficialLoginLayout(
            email: email,
            password: password,
            busy: false,
            onLogin: () => login++,
            onGoogle: () => google++,
            onResetPassword: () => reset++,
            onCreateAccount: () => register++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('official-login-card'));
      final googleButton = find.byKey(const ValueKey('official-google-button'));
      final createCard = find.byKey(
        const ValueKey('official-create-account-card'),
      );
      final slogan = find.byKey(const ValueKey('official-login-slogan'));
      expect(
        find.text('Seu negócio vendendo.\nOnde você estiver.'),
        findsOneWidget,
      );
      expect(find.text('OU'), findsOneWidget);
      expect(find.descendant(of: card, matching: googleButton), findsNothing);
      expect(
        tester.getTopLeft(slogan).dy,
        lessThan(tester.getTopLeft(card).dy),
      );
      expect(
        tester.getBottomLeft(card).dy,
        lessThan(tester.getTopLeft(find.text('OU')).dy),
      );
      expect(
        tester.getTopLeft(googleButton).dy,
        greaterThan(tester.getBottomLeft(find.text('OU')).dy),
      );
      expect(
        tester.getTopLeft(createCard).dy,
        greaterThan(tester.getBottomLeft(googleButton).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'pilot@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Senha'),
        'fixture-password',
      );
      await tester.ensureVisible(find.text('Entrar no TORICO →'));
      await tester.tap(find.text('Entrar no TORICO →'));
      expect(login, 1);
      await tester.ensureVisible(find.text('Esqueci minha senha'));
      await tester.tap(find.text('Esqueci minha senha'));
      expect(reset, 1);
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      expect(google, 1);
      await tester.ensureVisible(createCard);
      await tester.tap(find.text('Criar conta grátis'));
      expect(register, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
