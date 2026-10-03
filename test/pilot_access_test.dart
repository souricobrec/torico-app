import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/screens/pilot_gate.dart';
import 'package:torico/services/pilot_access_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'public is blocked, pilot persists, clear resets without removing other data',
    () async {
      final access = PilotAccessService(allowedUids: {'invited'});
      await access.initialize(Uri.parse('https://torico-ca479.web.app'));
      expect(access.requested, false);
      await access.initialize(
        Uri.parse('https://torico-ca479.web.app/?pilot=1'),
      );
      expect(access.requested, true);
      expect(access.allows(null), false);
      expect(access.allows('other'), false);
      expect(access.allows('invited'), true);
      final restarted = PilotAccessService(allowedUids: {'invited'});
      await restarted.initialize(Uri.parse('https://torico-ca479.web.app'));
      expect(restarted.allows('invited'), true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('unrelated', 'kept');
      await restarted.initialize(
        Uri.parse('https://torico-ca479.web.app/?pilot=0'),
      );
      expect(restarted.requested, false);
      expect(prefs.getString('unrelated'), 'kept');
    },
  );

  test('empty allowlist and invalid/repeated flags fail closed', () async {
    final empty = PilotAccessService(allowedUids: {});
    await empty.initialize(Uri.parse('https://torico-ca479.web.app/?pilot=1'));
    expect(empty.requested, false);
    for (final query in [
      'pilot=true',
      'pilot=1&pilot=1',
      'pilot=',
      'pilot=0',
    ]) {
      final access = PilotAccessService(allowedUids: {'invited'});
      await access.initialize(
        Uri.parse('https://torico-ca479.web.app/?$query'),
      );
      expect(access.requested, false);
    }
    expect(PilotAccessService.parseUids(' a, b ,a,, '), {'a', 'b'});
  });

  testWidgets('URL flag alone never shows app; logout closes nested routes', (
    tester,
  ) async {
    final access = PilotAccessService(allowedUids: {'invited'});
    await access.initialize(Uri.parse('https://torico-ca479.web.app/?pilot=1'));
    final auth = StreamController<String?>.broadcast();
    addTearDown(auth.close);
    await tester.pumpWidget(
      MaterialApp(
        home: PilotGate(
          access: access,
          authChanges: auth.stream,
          initialUid: null,
          signIn: (_, _) async {},
          signOut: () async {},
          appBuilder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const Scaffold(body: Text('Private nested route')),
                ),
              ),
              child: const Text('Private app'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Acesso piloto TORICO'), findsOneWidget);
    expect(find.text('Private app'), findsNothing);
    auth.add('other');
    await tester.pumpAndSettle();
    expect(find.text('Private app'), findsNothing);
    auth.add('invited');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private app'));
    await tester.pumpAndSettle();
    expect(find.text('Private nested route'), findsOneWidget);
    auth.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Private nested route'), findsNothing);
    expect(find.text('Acesso piloto TORICO'), findsOneWidget);
    await tester.tap(find.text('Sair do modo piloto'));
    await tester.pumpAndSettle();
    expect(access.requested, false);
    expect(find.text('Acesso piloto TORICO'), findsNothing);
  });
}
