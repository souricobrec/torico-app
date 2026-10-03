import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/screens/pilot_gate.dart';
import 'package:torico/services/domain_block_service.dart';
import 'package:torico/services/pilot_access_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'official host requests login without parameter but never bypasses allowlists',
    () async {
      expect(DomainBlockService.shouldBlockHost('app.meutorico.com.br'), true);
      final access = PilotAccessService(
        allowedUids: {'existing-uid'},
        allowedEmails: {'pilot@example.com'},
      );
      await access.initialize(Uri.parse('https://app.meutorico.com.br'));
      expect(access.official, true);
      expect(access.requested, true);
      expect(access.allows(null), false);
      expect(access.allows('stranger'), false);
      expect(access.allows('existing-uid'), true);
      expect(
        access.allows(
          'email-uid',
          email: 'PILOT@example.com',
          emailVerified: true,
        ),
        true,
      );
      expect(access.allows('email-uid', email: 'pilot@example.com'), false);
      await access.initialize(
        Uri.parse('https://app.meutorico.com.br/?pilot=0'),
      );
      expect(access.requested, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(PilotAccessService.storageKey), false);
      final empty = PilotAccessService(allowedUids: {}, allowedEmails: {});
      await empty.initialize(Uri.parse('https://app.meutorico.com.br'));
      expect(empty.requested, true);
      expect(empty.allows('existing-uid'), false);
    },
  );

  test(
    'technical Firebase host retains public default and explicit pilot flow',
    () async {
      expect(DomainBlockService.shouldBlockHost('torico-ca479.web.app'), true);
      final access = PilotAccessService(allowedUids: {'existing-uid'});
      await access.initialize(Uri.parse('https://torico-ca479.web.app'));
      expect(access.requested, false);
      await access.initialize(
        Uri.parse('https://torico-ca479.web.app/?pilot=1'),
      );
      expect(access.official, false);
      expect(access.allows('existing-uid'), true);
      expect(access.allows('stranger'), false);
      await access.initialize(
        Uri.parse('https://torico-ca479.web.app/?pilot=0'),
      );
      expect(access.requested, false);
    },
  );

  testWidgets(
    'official login uses merchant wording, rejects stranger and preserves authorized UID',
    (tester) async {
      final access = PilotAccessService(allowedUids: {'existing-uid'});
      await access.initialize(Uri.parse('https://app.meutorico.com.br'));
      final auth = StreamController<PilotIdentity?>.broadcast();
      addTearDown(auth.close);
      await tester.pumpWidget(
        MaterialApp(
          home: PilotGate(
            access: access,
            authChanges: auth.stream,
            initialIdentity: null,
            signIn: (_, _) async {},
            signInGoogle: () async {},
            signOut: () async {
              auth.add(null);
            },
            appBuilder: (_) => const Scaffold(body: Text('Existing user app')),
          ),
        ),
      );
      expect(find.text('Acesse o TORICO'), findsOneWidget);
      expect(find.text('TORICO'), findsOneWidget);
      expect(
        find.text('Seu negócio vendendo.\nOnde você estiver.'),
        findsOneWidget,
      );
      expect(find.text('Sair da conta'), findsNothing);
      expect(find.text('Fazer Login com o Google'), findsOneWidget);
      expect(find.text('Sair do modo piloto'), findsNothing);
      auth.add(const PilotIdentity('stranger'));
      await tester.pumpAndSettle();
      expect(
        find.text('Acesso não liberado. Entre com uma conta autorizada.'),
        findsOneWidget,
      );
      expect(find.text('Existing user app'), findsNothing);
      auth.add(const PilotIdentity('existing-uid'));
      await tester.pumpAndSettle();
      expect(find.text('Existing user app'), findsOneWidget);
      expect(find.text('Sair da conta'), findsNothing);
      auth.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Existing user app'), findsNothing);
      expect(find.text('Acesse o TORICO'), findsOneWidget);
    },
  );
}
