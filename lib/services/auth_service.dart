import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  AuthCredential? _pendingGoogleCredential;
  String? _pendingGoogleEmail;

  /// Firebase's one-account-per-email setting must remain enabled.
  Future<UserCredential> loginWithGoogle() async {
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    try {
      return await _auth.signInWithPopup(
        GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = e.credential;
        _pendingGoogleEmail = e.email?.trim().toLowerCase();
      }
      rethrow;
    }
  }

  static String googleErrorMessage(String code) => switch (code) {
    'account-exists-with-different-credential' =>
      'Este e-mail já possui conta. Entre com e-mail e senha para vincular o Google à mesma conta.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' => 'Login Google cancelado.',
    'popup-blocked' => 'Permita pop-ups neste navegador e tente novamente.',
    'operation-not-allowed' =>
      'Login Google ainda não está habilitado neste ambiente.',
    'unauthorized-domain' =>
      'Este domínio ainda não está autorizado para login Google.',
    _ =>
      'Não foi possível entrar com Google. Tente novamente ou use e-mail e senha.',
  };

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final pending = _pendingGoogleCredential;
    final pendingEmail = _pendingGoogleEmail;
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    if (pending != null &&
        pendingEmail != null &&
        result.user?.email?.trim().toLowerCase() == pendingEmail) {
      // Link only after authenticating the existing account. Never migrate data
      // or create a second Firebase user to resolve provider conflicts.
      await result.user!.linkWithCredential(pending);
    }
    return result;
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.sendEmailVerification();

    return credential;
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
