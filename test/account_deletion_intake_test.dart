import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/services/account_deletion_intake_service.dart';
import 'package:torico/screens/account_deletion_screen.dart';
import 'package:torico/services/auth_service.dart';
import 'package:torico/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

String received() => jsonEncode({
  'ok': true,
  'requestId': 'fixture-request',
  'protocol': 'TORICO-FIXTURE',
  'status': 'received',
  'receivedAt': '2026-10-15T12:00:00Z',
  'revision': 1,
  'completedAt': null,
});
AccountDeletionIntakeService service(
  http.Client client, {
  String Function()? uid,
  Future<String?> Function()? token,
}) => AccountDeletionIntakeService(
  enabled: true,
  client: client,
  baseUrl: 'http://127.0.0.1:12345',
  uidLoader: uid ?? () => 'fixture-owner',
  tokenLoader: token ?? () async => 'fixture-id-token',
);

class Provider extends Fake implements UserInfo {
  @override
  final String providerId;
  Provider(this.providerId);
}

class ReauthUser extends Fake implements User {
  @override
  String get uid => 'same-uid';
  @override
  String get email => 'fixture@example.invalid';
  final String provider;
  ReauthUser(this.provider);
  int calls = 0;
  @override
  List<UserInfo> get providerData => [Provider(provider)];
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async {
    expect(provider.providerId, 'google.com');
    calls++;
    return ReauthResult(this);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    expect(credential.providerId, provider);
    calls++;
    return ReauthResult(this);
  }
}

class ReauthResult extends Fake implements UserCredential {
  @override
  final User user;
  ReauthResult(this.user);
}

class ReauthAuth extends Fake implements FirebaseAuth {
  @override
  final User currentUser;
  ReauthAuth(this.currentUser);
  @override
  Future<UserCredential> signInWithCredential(
    AuthCredential credential,
  ) async => throw StateError('Must reauthenticate, not sign in');
}

void main() {
  test(
    'clear device removes all account-linked intake keys; server status remains recoverable',
    () async {
      SharedPreferences.setMockInitialValues({
        'torico_deletion_intake_key_fixtureA': 'key-a',
        'torico_deletion_intake_key_fixtureB': 'key-b',
        'unrelated_preference': true,
      });
      await LocalStorageService().clearDeviceData();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where(
          (key) => key.startsWith('torico_deletion_intake_key_'),
        ),
        isEmpty,
      );
      expect(prefs.getBool('unrelated_preference'), true);
      final recovered = await service(
        MockClient((_) async => http.Response(received(), 200)),
      ).current();
      expect(recovered!.protocol, 'TORICO-FIXTURE');
    },
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('default disabled does not authenticate or call HTTP', () async {
    var calls = 0;
    final s = AccountDeletionIntakeService(
      client: MockClient((_) async {
        calls++;
        return http.Response(received(), 202);
      }),
      uidLoader: () => throw StateError('must not read Auth'),
    );
    expect(s.enabled, false);
    await expectLater(s.submit(), throwsA(isA<DeletionIntakeException>()));
    expect(calls, 0);
  });
  test(
    'key saved before POST, retry after uncertain response reuses key; body has no UID',
    () async {
      final keys = <String>[];
      var calls = 0;
      final client = MockClient((req) async {
        expect(req.url.host, '127.0.0.1');
        expect(req.url.path, '/v1/account-deletion/requests');
        expect(req.headers['Authorization'], 'Bearer fixture-id-token');
        final b = jsonDecode(req.body);
        expect(
          b.keys,
          unorderedEquals(['confirmation', 'noticeVersion', 'policyVersion']),
        );
        keys.add(req.headers['Idempotency-Key']!);
        expect((await SharedPreferences.getInstance()).getKeys(), isNotEmpty);
        if (calls++ == 0) throw http.ClientException('fixture lost response');
        return http.Response(received(), 202);
      });
      await expectLater(service(client).submit(), throwsException);
      expect((await service(client).submit()).status, 'received');
      expect(keys[0], keys[1]);
    },
  );
  test(
    'status comes from server, only specific not-found yields no request',
    () async {
      final s = service(
        MockClient((req) async {
          expect(req.method, 'GET');
          expect(req.url.path, endsWith('/current'));
          return http.Response(received(), 200);
        }),
      );
      expect((await s.current())!.protocol, 'TORICO-FIXTURE');
      expect(
        await service(
          MockClient(
            (_) async => http.Response('{"code":"request_not_found"}', 404),
          ),
        ).current(),
        isNull,
      );
      await expectLater(
        service(
          MockClient(
            (_) async => http.Response('{"code":"feature_disabled"}', 404),
          ),
        ).current(),
        throwsA(isA<DeletionIntakeException>()),
      );
      for (final status in [401, 403, 429, 503]) {
        await expectLater(
          service(
            MockClient(
              (_) async => http.Response('{"code":"unavailable"}', status),
            ),
          ).submit(),
          throwsA(isA<DeletionIntakeException>()),
        );
      }
    },
  );
  test(
    'different UID gets a different key, changed session cannot submit',
    () async {
      final keys = <String>[];
      var uid = 'fixture-a';
      final client = MockClient((req) async {
        keys.add(req.headers['Idempotency-Key']!);
        return http.Response(received(), 202);
      });
      await service(client, uid: () => uid).submit();
      uid = 'fixture-b';
      await service(client, uid: () => uid).submit();
      expect(keys[0], isNot(keys[1]));
      final before = keys.length;
      await expectLater(
        service(
          client,
          uid: () => uid,
          token: () async {
            uid = 'other';
            return 'fixture';
          },
        ).submit(),
        throwsA(isA<DeletionIntakeException>()),
      );
      expect(keys.length, before);
    },
  );
  for (final provider in ['google.com', 'password']) {
    for (final web in [true, false]) {
      test(
        'recent auth uses Firebase reauthenticate for $provider on web=$web and keeps UID',
        () async {
          final user = ReauthUser(provider);
          final s = AuthService(
            auth: ReauthAuth(user),
            useWebGoogle: web,
            nativeGoogleCredential: () async =>
                GoogleAuthProvider.credential(idToken: 'fixture'),
          );
          expect(s.requiresPasswordReauthentication, provider == 'password');
          await s.reauthenticateCurrentUser(
            password: provider == 'password' ? 'fixture-secret' : null,
          );
          expect(user.calls, 1);
          expect(s.currentUser!.uid, 'same-uid');
        },
      );
    }
  }
  testWidgets(
    'explicit confirmation + reauth registers and shows received, not completed',
    (tester) async {
      final calls = <String>[];
      final s = service(
        MockClient((_) async {
          calls.add('http');
          return http.Response(received(), 202);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AccountDeletionScreen(
            intakeEnabled: true,
            intakeService: s,
            reauthenticate: () async {
              calls.add('reauth');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.text('Registrar solicitação autenticada'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(
        find.text('Registrar solicitação autenticada'),
      );
      await tester.tap(find.text('Registrar solicitação autenticada'));
      await tester.pumpAndSettle();
      expect(calls, ['reauth', 'http']);
      expect(find.text('Protocolo: TORICO-FIXTURE'), findsOneWidget);
      expect(find.text('Estado: Recebido'), findsOneWidget);
      expect(find.text('Conta excluída'), findsNothing);
    },
  );
  testWidgets('reauth failure and network failure do not show fake protocol', (
    tester,
  ) async {
    for (final reauthFails in [true, false]) {
      var calls = 0;
      final s = service(
        MockClient((_) async {
          calls++;
          throw http.ClientException('fixture');
        }),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: AccountDeletionScreen(
            intakeEnabled: true,
            intakeService: s,
            reauthenticate: () async {
              if (reauthFails) throw StateError('fixture');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(
        find.text('Registrar solicitação autenticada'),
      );
      await tester.tap(find.text('Registrar solicitação autenticada'));
      await tester.pumpAndSettle();
      expect(calls, reauthFails ? 0 : 1);
      expect(find.textContaining('Protocolo:'), findsNothing);
      expect(
        find.textContaining(
          reauthFails
              ? 'Não foi possível confirmar sua identidade.'
              : 'Recebimento não confirmado.',
        ),
        findsOneWidget,
      );
    }
  });
  testWidgets('read refresh shows server protocol without reauthentication', (
    tester,
  ) async {
    var calls = 0;
    final s = service(
      MockClient((req) async {
        expect(req.method, 'GET');
        calls++;
        return http.Response(received(), 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AccountDeletionScreen(
          intakeEnabled: true,
          intakeService: s,
          reauthenticate: () async =>
              throw StateError('should not reauth read'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Consultar minha solicitação'));
    await tester.tap(find.text('Consultar minha solicitação'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Estado: Recebido'), findsOneWidget);
  });

  test(
    'session changing while response arrives cannot expose another session protocol',
    () async {
      var uid = 'fixture-a';
      final s = service(
        MockClient((_) async {
          uid = 'fixture-b';
          return http.Response(received(), 202);
        }),
        uid: () => uid,
      );
      await expectLater(s.submit(), throwsA(isA<DeletionIntakeException>()));
    },
  );
  testWidgets(
    'double action while reauth pending performs one authentication and request',
    (tester) async {
      final pending = Completer<void>();
      var reauthCalls = 0, httpCalls = 0;
      final s = service(
        MockClient((_) async {
          httpCalls++;
          return http.Response(received(), 202);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AccountDeletionScreen(
            intakeEnabled: true,
            intakeService: s,
            reauthenticate: () {
              reauthCalls++;
              return pending.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      final action = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .onPressed!;
      action();
      action();
      await tester.pump();
      expect(reauthCalls, 1);
      expect(httpCalls, 0);
      pending.complete();
      await tester.pumpAndSettle();
      expect(httpCalls, 1);
    },
  );
}
