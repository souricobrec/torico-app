import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/screens/main_navigation_screen.dart';
import 'package:torico/screens/sales_history_screen.dart';
import 'package:torico/screens/settings_screen.dart';
import 'package:torico/screens/pilot_gate.dart';
import 'package:torico/services/local_storage_service.dart';
import 'package:torico/services/pilot_access_service.dart';
import 'package:torico/services/user_plan_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'basic navigation hides history; plus gains it; downgrade removes it',
    (tester) async {
      final plans = StreamController<UserPlan>.broadcast();
      addTearDown(plans.close);
      final built = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreen(
            plataforma: 'Mercado Pago',
            planStream: plans.stream,
            pageBuilder: (_, tab) {
              built.add(tab);
              return Text('$tab conteúdo');
            },
          ),
        ),
      );
      expect(find.text('Histórico'), findsNothing);
      plans.add(UserPlan.basic());
      await tester.pumpAndSettle();
      expect(find.text('Painel'), findsOneWidget);
      expect(find.text('Plano'), findsOneWidget);
      expect(find.text('Conta'), findsOneWidget);
      expect(built, ['Painel']);
      await tester.tap(find.text('Conta'));
      await tester.pumpAndSettle();
      expect(find.text('Conta conteúdo'), findsOneWidget);
      plans.add(const UserPlan(code: 'plus', name: 'TORICO Plus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.text('Histórico conteúdo'), findsOneWidget);
      plans.add(UserPlan.basic());
      await tester.pumpAndSettle();
      expect(find.text('Histórico'), findsNothing);
      expect(find.text('Histórico conteúdo'), findsNothing);
      expect(find.text('Painel conteúdo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('direct history is blocked for basic without querying sales', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SalesHistoryScreen(
          planStream: Stream.value(UserPlan.basic()),
          summaryLoader: (_) => throw StateError('must not query summary'),
          salesLoader: (_, _) => throw StateError('must not query sales'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Histórico de vendas é um recurso do TORICO Plus.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Dia anterior'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clear connections confirms, clears only local caches, signs out and opens login',
    (tester) async {
      final storage = LocalStorageService();
      await storage.saveConnectedPlatforms(['Mercado Pago', 'Rede']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('total_sold', 1);
      await prefs.setString('unrelated_preference', 'keep');
      var signOuts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            plataforma: 'Mercado Pago',
            platformLoader: () async => ['Mercado Pago', 'Rede'],
            signOut: () async {
              signOuts++;
            },
            loginBuilder: (_) => const Scaffold(body: Text('Tela de login')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.text('Limpar conexões deste dispositivo');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.textContaining('encerrará sua sessão'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(signOuts, 0);
      expect(await storage.getConnectedPlatforms(), ['Mercado Pago', 'Rede']);
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpar e sair'));
      await tester.pumpAndSettle();
      expect(signOuts, 1);
      expect(await storage.getConnectedPlatforms(), isEmpty);
      expect(prefs.containsKey('total_sold'), false);
      expect(prefs.getString('unrelated_preference'), 'keep');
      expect(find.text('Tela de login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Google login announces pending state and opens app after sign-in',
    (tester) async {
      final access = PilotAccessService(allowedUids: {'existing-uid'});
      await access.initialize(Uri.parse('https://app.meutorico.com.br'));
      final auth = StreamController<PilotIdentity?>.broadcast();
      addTearDown(auth.close);
      final pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: PilotGate(
            access: access,
            authChanges: auth.stream,
            initialIdentity: null,
            signIn: (_, _) async {},
            signInGoogle: () => pending.future,
            signOut: () async {},
            appBuilder: (_) => const Scaffold(body: Text('App existente')),
          ),
        ),
      );
      final button = find.text('Fazer Login com o Google');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Conectando com Google...'), findsOneWidget);
      expect(find.text('Aguarde a conclusão do login.'), findsOneWidget);
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.readOnly),
        true,
      );
      pending.complete();
      auth.add(const PilotIdentity('existing-uid'));
      await tester.pumpAndSettle();
      expect(find.text('App existente'), findsOneWidget);
      expect(find.text('Sair da conta'), findsNothing);
    },
  );

  testWidgets('Google cancellation shows friendly message and ends loading', (
    tester,
  ) async {
    final access = PilotAccessService(allowedUids: {'uid'});
    await access.initialize(Uri.parse('https://app.meutorico.com.br'));
    await tester.pumpWidget(
      MaterialApp(
        home: PilotGate(
          access: access,
          authChanges: const Stream.empty(),
          initialIdentity: null,
          signIn: (_, _) async {},
          signInGoogle: () async {
            throw FirebaseAuthException(code: 'popup-closed-by-user');
          },
          signOut: () async {},
          appBuilder: (_) => const SizedBox(),
        ),
      ),
    );
    final button = find.text('Fazer Login com o Google');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Login Google cancelado.'), findsOneWidget);
    expect(find.text('Conectando com Google...'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
