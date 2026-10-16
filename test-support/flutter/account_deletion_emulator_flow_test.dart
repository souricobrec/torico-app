// Opt-in integration target, intentionally outside automatic test discovery.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/screens/account_deletion_screen.dart';
import 'package:torico/services/account_deletion_intake_service.dart';
import 'package:torico/services/auth_service.dart';
import 'package:torico/services/local_storage_service.dart';

const project = String.fromEnvironment('TORICO_TEST_PROJECT');
const outage = bool.fromEnvironment('TORICO_TEST_OUTAGE');
const api = 'http://127.0.0.1:18893';
const password = 'emulator-fixture-only-123';

class _RealHttp extends HttpOverrides {}

// A real TCP transport, with an explicit host/port allowlist. No remote fallback.
class _LocalClient extends http.BaseClient {
  final http.Client inner = HttpOverrides.runWithHttpOverrides(
    () => IOClient(HttpClient()),
    _RealHttp(),
  );
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.scheme != 'http' ||
        request.url.host != '127.0.0.1' ||
        ![18893, 19099].contains(request.url.port)) {
      throw StateError('Integration test refuses non-loopback service');
    }
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}

class _Session {
  final _LocalClient transport;
  String? uid, token;
  String identity = 'integrated-a';
  int reauthentications = 0;
  _Session(this.transport);
  Future<void> login([String? name]) async {
    identity = name ?? identity;
    final response = await transport.post(
      Uri.parse(
        'http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-only',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': '$identity@example.invalid',
        'password': password,
        'returnSecureToken': true,
      }),
    );
    expect(response.statusCode, 200); // Never print the response body/token.
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    uid = data['localId'] as String;
    token = data['idToken'] as String;
  }

  void signOut() {
    uid = null;
    token = null;
  }

  AccountDeletionIntakeService service([http.Client? client]) =>
      AccountDeletionIntakeService(
        enabled: true,
        baseUrl: api,
        client: client ?? transport,
        uidLoader: () => uid,
        tokenLoader: () async => token,
      );
}

class _Provider extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

class _User extends Fake implements User {
  final _Session session;
  final String owner;
  _User(this.session) : owner = session.uid!;
  @override
  String get uid => owner;
  @override
  String get email => '${session.identity}@example.invalid';
  @override
  List<UserInfo> get providerData => [_Provider()];
  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    expect(credential.providerId, 'password');
    await session
        .login(); // Real Auth Emulator REST call behind the SDK adapter.
    expect(session.uid == owner, true);
    session.reauthentications++;
    return _Credential(this);
  }
}

class _Credential extends Fake implements UserCredential {
  @override
  final User user;
  _Credential(this.user);
}

class _Auth extends Fake implements FirebaseAuth {
  final _Session session;
  _Auth(this.session);
  @override
  User? get currentUser => session.uid == null ? null : _User(session);
  @override
  Future<void> signOut() async => session.signOut();
}

// Faults are explicit and test-only. Normal mode delegates every call over TCP.
class _FaultClient extends http.BaseClient {
  final http.Client real;
  String mode = 'normal';
  Completer<void>? observed;
  void Function()? afterResponse;
  _FaultClient(this.real);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      if (mode == 'network') {
        throw const SocketException('local simulated network failure');
      }
      if (mode == 'invalid') {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{invalid')),
          202,
        );
      }
      final response = await real.send(request);
      final bytes = await response.stream.toBytes();
      afterResponse?.call();
      if (mode == 'lost-response') {
        throw const SocketException(
          'local simulated lost response after server commit',
        );
      }
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
      );
    } finally {
      if (observed != null && !observed!.isCompleted) observed!.complete();
    }
  }
}

Future<void> _clickAndWait(
  WidgetTester tester,
  Finder button,
  _FaultClient client,
) async {
  await tester.ensureVisible(button);
  await tester.runAsync(() async {
    // Bind this future to the real I/O zone. A completer created in FakeAsync
    // cannot wake runAsync until the fake zone is pumped, causing a deadlock.
    final response = Completer<void>();
    client.observed = response;
    await tester.tap(button);
    await response.future.timeout(const Duration(seconds: 25));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
  expect(find.byType(LinearProgressIndicator), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (project != 'demo-torico-intake') {
    throw StateError(
      'Run only through the isolated emulator launcher with explicit demo project',
    );
  }
  // This opt-in test lives outside test/ to prevent unintended emulator access.
  // ignore: invalid_use_of_visible_for_testing_member
  setUp(() => SharedPreferences.setMockInitialValues({}));

  if (outage) {
    test(
      'real Firestore outage cannot confirm a request',
      () async {
        final transport = _LocalClient();
        addTearDown(transport.close);
        final session = _Session(transport);
        await session.login();
        await expectLater(
          session.service().submit(),
          throwsA(
            anyOf(
              isA<TimeoutException>(),
              isA<DeletionIntakeException>().having(
                (error) => error.code,
                'code',
                'service_unavailable',
              ),
              isA<http.ClientException>(),
            ),
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
    return;
  }

  test(
    'Flutter service -> real API -> emulators: concurrent/repeated requests, recovery, ownership',
    () async {
      final transport = _LocalClient();
      addTearDown(transport.close);
      final a = _Session(transport), b = _Session(transport);
      await a.login();
      final first = await a.service().submit();
      expect(first.status, 'received');
      final concurrent = await Future.wait([
        a.service().submit(),
        a.service().submit(),
      ]);
      expect(concurrent.every((item) => item.protocol == first.protocol), true);
      await LocalStorageService().clearDeviceData();
      expect(
        (await SharedPreferences.getInstance()).getKeys().where(
          (key) => key.startsWith('torico_deletion_intake_key_'),
        ),
        isEmpty,
      );
      expect((await a.service().current())!.protocol, first.protocol);
      expect((await a.service().submit()).protocol, first.protocol);

      await b.login('integrated-b');
      final lost = _FaultClient(transport)..mode = 'lost-response';
      await expectLater(
        b.service(lost).submit(),
        throwsA(isA<SocketException>()),
      );
      final recovered = await b.service().submit();
      expect((await b.service().current())!.protocol, recovered.protocol);
      expect(recovered.protocol == first.protocol, false);
      final foreign = await transport.get(
        Uri.parse('$api/v1/account-deletion/requests/${recovered.requestId}'),
        headers: {'Authorization': 'Bearer ${a.token}'},
      );
      expect(foreign.statusCode, 404);
    },
  );

  testWidgets(
    'actual deletion screen reauthenticates, registers and consults a real protocol',
    (tester) async {
      final transport = _LocalClient();
      addTearDown(transport.close);
      final session = _Session(transport);
      await tester.runAsync(session.login);
      final auth = AuthService(auth: _Auth(session), useWebGoogle: true);
      final client = _FaultClient(transport);
      await tester.pumpWidget(
        MaterialApp(
          home: AccountDeletionScreen(
            intakeEnabled: true,
            intakeService: session.service(client),
            reauthenticate: () =>
                auth.reauthenticateCurrentUser(password: password),
          ),
        ),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await _clickAndWait(
        tester,
        find.text('Registrar solicitação autenticada'),
        client,
      );
      expect(session.reauthentications, 1);
      expect(find.text('Estado: Recebido'), findsOneWidget);
      expect(find.textContaining('Protocolo: TORICO-'), findsOneWidget);
      expect(
        find.text(
          'Pedido recebido pelo servidor. Sua conta ainda não foi excluída.',
        ),
        findsOneWidget,
      );
      await _clickAndWait(
        tester,
        find.text('Consultar minha solicitação'),
        client,
      );
      expect(
        find.textContaining('Estado consultado no servidor.'),
        findsOneWidget,
      );
    },
  );

  test(
    'logout and session changes cannot expose in-flight status; re-login recovers request',
    () async {
      final transport = _LocalClient();
      addTearDown(transport.close);
      final session = _Session(transport);
      await session.login();
      final auth = AuthService(auth: _Auth(session), useWebGoogle: true);
      final before = await session.service().current();
      await auth.logout();
      await expectLater(
        session.service().current(),
        throwsA(isA<DeletionIntakeException>()),
      );
      await session.login();
      expect((await session.service().current())!.protocol, before!.protocol);
      final switcher = _FaultClient(transport)..afterResponse = session.signOut;
      await expectLater(
        session.service(switcher).current(),
        throwsA(isA<DeletionIntakeException>()),
      );
      await session.login('integrated-b');
      expect(
        (await session.service().current())!.protocol == before.protocol,
        false,
      );
      final stale = _FaultClient(transport)
        ..afterResponse = () {
          session.uid = 'simulated-other-session';
        };
      await expectLater(
        session.service(stale).current(),
        throwsA(isA<DeletionIntakeException>()),
      );
    },
  );

  for (final mode in ['network', 'invalid']) {
    testWidgets('UI never confirms receipt on $mode response fault', (
      tester,
    ) async {
      final transport = _LocalClient();
      addTearDown(transport.close);
      final session = _Session(transport);
      await tester.runAsync(session.login);
      final auth = AuthService(auth: _Auth(session), useWebGoogle: true);
      final client = _FaultClient(transport)..mode = mode;
      await tester.pumpWidget(
        MaterialApp(
          home: AccountDeletionScreen(
            intakeEnabled: true,
            intakeService: session.service(client),
            reauthenticate: () =>
                auth.reauthenticateCurrentUser(password: password),
          ),
        ),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await _clickAndWait(
        tester,
        find.text('Registrar solicitação autenticada'),
        client,
      );
      expect(
        find.textContaining('Recebimento não confirmado.'),
        findsOneWidget,
      );
      expect(find.textContaining('Protocolo: TORICO-'), findsNothing);
    });
  }
}
