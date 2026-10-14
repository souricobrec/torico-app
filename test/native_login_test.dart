import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/services/auth_service.dart';
import 'package:torico/services/domain_block_service.dart';
import 'package:torico/services/pilot_access_service.dart';
import 'package:torico/screens/pilot_gate.dart';

class NativeUser extends Fake implements User {
  @override
  String get uid => 'same-firebase-uid';
}

class NativeResult extends Fake implements UserCredential {
  @override
  User get user => NativeUser();
}

class NativeAuth extends Fake implements FirebaseAuth {
  int nativeCalls = 0;
  int emailCalls = 0;
  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    expect(credential.providerId, 'google.com');
    nativeCalls++;
    return NativeResult();
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async =>
      throw StateError('Native must not use web popup');

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emailCalls++;
    return NativeResult();
  }
}

void main() {
  test(
    'native Google exchanges credential with Firebase, email login unchanged',
    () async {
      final auth = NativeAuth();
      final service = AuthService(
        auth: auth,
        useWebGoogle: false,
        nativeGoogleCredential: () async =>
            GoogleAuthProvider.credential(idToken: 'fixture-only'),
      );
      expect((await service.loginWithGoogle()).user?.uid, 'same-firebase-uid');
      expect(auth.nativeCalls, 1);
      expect(
        (await service.login(
          email: 'fixture@example.invalid',
          password: 'fixture',
        )).user?.uid,
        'same-firebase-uid',
      );
      expect(auth.emailCalls, 1);
    },
  );

  test(
    'native gate enables login but never bypasses UID or verified email',
    () async {
      expect(DomainBlockService.shouldBlock, true);
      final access = PilotAccessService(
        allowedUids: {'permitted-uid'},
        allowedEmails: {'pilot@example.invalid'},
      );
      await access.initializeForPlatform(Uri(), isWeb: false);
      expect(access.official, true);
      expect(access.requested, true);
      expect(access.allows(null), false);
      expect(access.allows('other'), false);
      expect(access.allows('permitted-uid'), true);
      expect(access.allows('other', email: 'pilot@example.invalid'), false);
      expect(
        access.allows(
          'other',
          email: 'PILOT@example.invalid',
          emailVerified: true,
        ),
        true,
      );
      final empty = PilotAccessService(allowedUids: {}, allowedEmails: {});
      await empty.initializeForPlatform(Uri(), isWeb: false);
      expect(empty.allows('permitted-uid'), false);
    },
  );

  for (final identity in [
    null,
    const PilotIdentity('unauthorized'),
    const PilotIdentity('allowed'),
  ]) {
    testWidgets(
      'native login/gate presentation for ${identity?.uid ?? "signed-out"}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final access = PilotAccessService(allowedUids: {'allowed'});
        await access.initializeForPlatform(Uri(), isWeb: false);
        await tester.pumpWidget(
          MaterialApp(
            home: PilotGate(
              access: access,
              authChanges: const Stream.empty(),
              initialIdentity: identity,
              signIn: (_, _) async {},
              signInGoogle: () async {},
              signOut: () async {},
              appBuilder: (_) => const Scaffold(body: Text('Authorized app')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (identity == null) {
          expect(
            find.text('Seu negócio vendendo.\nOnde você estiver.'),
            findsOneWidget,
          );
          expect(find.text('Fazer Login com o Google'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('official-login-card')),
            findsOneWidget,
          );
          expect(find.text('Authorized app'), findsNothing);
        } else if (identity.uid == 'allowed') {
          expect(find.text('Authorized app'), findsOneWidget);
        } else {
          expect(
            find.text('Acesso não liberado. Entre com uma conta autorizada.'),
            findsOneWidget,
          );
          expect(find.text('Authorized app'), findsNothing);
        }
      },
    );
  }
}
