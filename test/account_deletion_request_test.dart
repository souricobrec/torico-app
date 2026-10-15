import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/screens/account_deletion_screen.dart';
import 'package:torico/screens/settings_screen.dart';
import 'package:torico/services/account_deletion_contact.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('contact is fixed, minimal and contains no authentication or UID', () {
    final draft = AccountDeletionContact.emailDraft;
    expect(draft.scheme, 'mailto');
    expect(draft.path, AccountDeletionContact.email);
    expect(draft.queryParameters['subject'], AccountDeletionContact.subject);
    expect(draft.queryParameters['body'], contains('[preencher]'));
    expect(draft.queryParameters.keys, unorderedEquals(['subject', 'body']));
    expect(draft.toString(), isNot(contains('+')));
    expect(
      AccountDeletionContact.publicPage.toString(),
      'https://www.meutorico.com.br/exclusao-de-conta',
    );
  });
  testWidgets(
    'Conta exposes deletion separately, back does not log out or disconnect',
    (tester) async {
      var logouts = 0, disconnects = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            plataforma: 'Mercado Pago',
            platformLoader: () async => ['Mercado Pago'],
            accountIdentityLoader: () => null,
            signOut: () async {
              logouts++;
            },
            disconnectPlatform: (_) async {
              disconnects++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Excluir minha conta'));
      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountDeletionScreen), findsOneWidget);
      expect(find.text('Solicitação com atendimento manual'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(logouts, 0);
      expect(disconnects, 0);
      expect(find.text('Limpar dados deste dispositivo'), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);
    },
  );
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'manual request at $width requires consent and never claims registration',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final opened = <Uri>[];
        await tester.pumpWidget(
          MaterialApp(
            home: AccountDeletionScreen(
              openExternal: (uri) async {
                opened.add(uri);
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(opened, isEmpty);
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
        expect(find.text('Possíveis retenções'), findsOneWidget);
        expect(find.text('Como acompanhar'), findsOneWidget);
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.ensureVisible(
          find.text('Preparar solicitação por e-mail'),
        );
        await tester.tap(find.text('Preparar solicitação por e-mail'));
        await tester.pumpAndSettle();
        expect(opened.single.scheme, 'mailto');
        expect(find.textContaining('Envio não confirmado'), findsOneWidget);
        expect(find.text('Conta excluída'), findsNothing);
        expect(find.text('Solicitação registrada'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final throwsError in [false, true]) {
    testWidgets(
      'email launch failure ($throwsError) leaves fallback and no submitted state',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AccountDeletionScreen(
              openExternal: (_) async {
                if (throwsError) throw StateError('fixture');
                return false;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.ensureVisible(
          find.text('Preparar solicitação por e-mail'),
        );
        await tester.tap(find.text('Preparar solicitação por e-mail'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Não foi possível abrir.'), findsOneWidget);
        expect(find.text(AccountDeletionContact.email), findsOneWidget);
        expect(find.text('Copiar e-mail de suporte'), findsOneWidget);
        expect(find.text('Conta excluída'), findsNothing);
      },
    );
  }
  testWidgets(
    'public page can be opened without consent; in-flight draft is not duplicated',
    (tester) async {
      final opened = <Uri>[];
      final pending = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: AccountDeletionScreen(
            openExternal: (uri) {
              opened.add(uri);
              return uri.scheme == 'mailto'
                  ? pending.future
                  : Future.value(true);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver página pública de exclusão'));
      await tester.tap(find.text('Ver página pública de exclusão'));
      await tester.pumpAndSettle();
      expect(opened.single, AccountDeletionContact.publicPage);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.text('Preparar solicitação por e-mail'));
      await tester.tap(find.text('Preparar solicitação por e-mail'));
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(opened.length, 2);
      pending.complete(true);
      await tester.pumpAndSettle();
    },
  );
}
