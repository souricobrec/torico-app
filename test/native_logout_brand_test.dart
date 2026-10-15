import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:torico/services/auth_service.dart';
import 'package:torico/screens/pilot_gate.dart';
import 'package:torico/services/pilot_access_service.dart';
import 'package:torico/widgets/torico_panel_brand.dart';

class SessionUser extends Fake implements User {
  @override
  String get uid => 'allowed';
}

class Result extends Fake implements UserCredential {
  @override
  User get user => SessionUser();
}

class SessionAuth extends Fake implements FirebaseAuth {
  User? user = SessionUser();
  int signOuts = 0, signIns = 0;
  Completer<UserCredential>? pending;
  @override
  User? get currentUser => user;
  @override
  Future<void> signOut() async {
    signOuts++;
    user = null;
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential c) async {
    signIns++;
    final result = pending == null ? Result() : await pending!.future;
    user = result.user;
    return result;
  }
}

void main() {
  test(
    'cold-start logout clears Firebase and native Google without authenticating',
    () async {
      final auth = SessionAuth();
      var googleLogouts = 0, googleLogins = 0;
      AuthService service() => AuthService(
        auth: auth,
        useWebGoogle: false,
        nativeGoogleCredential: () async {
          googleLogins++;
          return GoogleAuthProvider.credential(idToken: 'fixture');
        },
        nativeGoogleSignOut: () async {
          expect(auth.currentUser, isNull);
          googleLogouts++;
        },
      );
      expect(service().currentUser?.uid, 'allowed');
      expect(
        service().currentUser?.uid,
        'allowed',
      ); // Reopen without logout retains Firebase session.
      expect(googleLogins, 0);
      await service().logout();
      expect(
        service().currentUser,
        isNull,
      ); // Fresh service after voluntary logout stays signed out.
      expect(googleLogouts, 1);
      expect(googleLogins, 0);
      await service()
          .loginWithGoogle(); // Only an explicit action may start Google.
      expect(googleLogins, 1);
      expect(service().currentUser?.uid, 'allowed');
    },
  );
  test('provider cleanup failure cannot restore Firebase session', () async {
    final auth = SessionAuth();
    await AuthService(
      auth: auth,
      useWebGoogle: false,
      nativeGoogleSignOut: () async => throw StateError('fixture'),
    ).logout();
    expect(auth.currentUser, isNull);
  });
  test(
    'logout invalidates Google UI request still waiting for a credential',
    () async {
      final auth = SessionAuth();
      final credential = Completer<AuthCredential>();
      final service = AuthService(
        auth: auth,
        useWebGoogle: false,
        nativeGoogleCredential: () => credential.future,
        nativeGoogleSignOut: () async {},
      );
      final request = service.loginWithGoogle();
      final rejected = expectLater(
        request,
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'session-ended',
          ),
        ),
      );
      await service.logout();
      credential.complete(GoogleAuthProvider.credential(idToken: 'fixture'));
      await rejected;
      expect(auth.signIns, 0);
      expect(auth.currentUser, isNull);
    },
  );
  test(
    'Firebase login completing after logout cannot reopen session',
    () async {
      final auth = SessionAuth()..pending = Completer<UserCredential>();
      final service = AuthService(
        auth: auth,
        useWebGoogle: false,
        nativeGoogleCredential: () async =>
            GoogleAuthProvider.credential(idToken: 'fixture'),
        nativeGoogleSignOut: () async {},
      );
      final request = service.loginWithGoogle();
      final rejected = expectLater(
        request,
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'session-ended',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await service.logout();
      auth.pending!.complete(Result());
      await rejected;
      expect(auth.currentUser, isNull);
      expect(auth.signOuts, 2);
    },
  );
  test(
    'native failures and SDK interruption are not called voluntary cancellation',
    () async {
      for (final code in GoogleSignInExceptionCode.values) {
        final mapped = AuthService.nativeGoogleErrorCode(code);
        expect(mapped, isNot('google-sign-in-cancelled'));
        expect(
          AuthService.googleErrorMessage(mapped),
          isNot('Login Google cancelado.'),
        );
      }
      final service = AuthService(
        auth: SessionAuth(),
        useWebGoogle: false,
        nativeGoogleCredential: () async => throw GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      );
      await expectLater(
        service.loginWithGoogle(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'google-client-configuration',
          ),
        ),
      );
    },
  );
  testWidgets(
    'restored Firebase session persists, signed-out gate reopens login without Google click',
    (tester) async {
      final changes = StreamController<PilotIdentity?>.broadcast();
      addTearDown(changes.close);
      final access = PilotAccessService(allowedUids: {'allowed'});
      await access.initializeForPlatform(Uri(), isWeb: false);
      var googleCalls = 0;
      Widget app(PilotIdentity? initial) => MaterialApp(
        home: PilotGate(
          access: access,
          authChanges: changes.stream,
          initialIdentity: initial,
          signIn: (_, _) async {},
          signInGoogle: () async {
            googleCalls++;
          },
          signOut: () async {},
          appBuilder: (_) => const Text('Persisted panel'),
        ),
      );
      await tester.pumpWidget(app(const PilotIdentity('allowed')));
      await tester.pumpAndSettle();
      expect(find.text('Persisted panel'), findsOneWidget);
      expect(googleCalls, 0);
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Fazer Login com o Google'), findsOneWidget);
      expect(find.text('Persisted panel'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(null));
      await tester.pumpAndSettle();
      expect(find.text('Fazer Login com o Google'), findsOneWidget);
      expect(googleCalls, 0);
    },
  );
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('panel reuses complete official artwork at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: ToricoPanelBrand())),
        ),
      );
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/torico_logo.png',
      );
      expect(image.fit, BoxFit.contain);
      expect(find.text('TORICO'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
