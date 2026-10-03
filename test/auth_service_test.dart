import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/services/auth_service.dart';

class TestUser extends Fake implements User {
  @override
  final String uid = 'existing-uid';
  @override
  final String email;
  int links = 0;
  TestUser(this.email);
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    links++;
    return TestCredential(this);
  }
}

class TestCredential extends Fake implements UserCredential {
  @override
  final User user;
  TestCredential(this.user);
}

class TestAuth extends Fake implements FirebaseAuth {
  final TestUser user;
  bool conflict = false;
  TestAuth(this.user);
  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    if (conflict) {
      throw FirebaseAuthException(
        code: 'account-exists-with-different-credential',
        email: 'existing@example.com',
        credential: GoogleAuthProvider.credential(idToken: 'test-fixture'),
      );
    }
    return TestCredential(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => TestCredential(user);
}

void main() {
  test(
    'provider conflict links only after login to the matching existing account',
    () async {
      final user = TestUser('existing@example.com');
      final service = AuthService(auth: TestAuth(user)..conflict = true);
      await expectLater(
        service.loginWithGoogle(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(user.links, 0);
      final result = await service.login(
        email: user.email,
        password: 'fixture',
      );
      expect(result.user?.uid, 'existing-uid');
      expect(user.links, 1);
      await service.login(email: user.email, password: 'fixture');
      expect(user.links, 1);
    },
  );

  test(
    'different account cannot consume Google credential from a conflict',
    () async {
      final user = TestUser('different@example.com');
      final service = AuthService(auth: TestAuth(user)..conflict = true);
      await expectLater(
        service.loginWithGoogle(),
        throwsA(isA<FirebaseAuthException>()),
      );
      await service.login(email: user.email, password: 'fixture');
      expect(user.links, 0);
    },
  );

  test(
    'Google sign in uses Firebase identity without creating app records',
    () async {
      final user = TestUser('existing@example.com');
      final result = await AuthService(auth: TestAuth(user)).loginWithGoogle();
      expect(result.user?.uid, 'existing-uid');
      expect(user.links, 0);
    },
  );
}
