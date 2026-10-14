import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final bool _useWebGoogle;
  final Future<AuthCredential> Function() _nativeGoogleCredential;
  AuthService({
    FirebaseAuth? auth,
    bool? useWebGoogle,
    Future<AuthCredential> Function()? nativeGoogleCredential,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _useWebGoogle = useWebGoogle ?? kIsWeb,
       _nativeGoogleCredential = nativeGoogleCredential ?? _googleCredential;
  static Future<void>? _googleInitialization;

  static Future<AuthCredential> _googleCredential() async {
    try {
      // On Android, serverClientId comes from Google Services' default_web_client_id.
      await (_googleInitialization ??= GoogleSignIn.instance.initialize());
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'google-missing-id-token');
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      throw FirebaseAuthException(
        code: switch (e.code) {
          GoogleSignInExceptionCode.canceled => 'google-sign-in-cancelled',
          GoogleSignInExceptionCode.clientConfigurationError =>
            'google-client-configuration',
          _ => 'google-sign-in-failed',
        },
      );
    }
  }

  AuthCredential? _pendingGoogleCredential;
  String? _pendingGoogleEmail;

  /// Firebase's one-account-per-email setting must remain enabled.
  Future<UserCredential> loginWithGoogle() async {
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    AuthCredential? nativeCredential;
    try {
      if (!_useWebGoogle) {
        nativeCredential = await _nativeGoogleCredential();
        return await _auth.signInWithCredential(nativeCredential);
      }
      return await _auth.signInWithPopup(
        GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = e.credential ?? nativeCredential;
        _pendingGoogleEmail = e.email?.trim().toLowerCase();
      }
      rethrow;
    }
  }

  static String googleErrorMessage(String code) => switch (code) {
    'account-exists-with-different-credential' =>
      'Este e-mail já possui conta. Entre com e-mail e senha para vincular o Google à mesma conta.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' ||
    'google-sign-in-cancelled' => 'Login Google cancelado.',
    'popup-blocked' => 'Permita pop-ups neste navegador e tente novamente.',
    'operation-not-allowed' =>
      'Login Google ainda não está habilitado neste ambiente.',
    'unauthorized-domain' =>
      'Este domínio ainda não está autorizado para login Google.',
    'google-client-configuration' =>
      'Não foi possível validar o login Google deste app. Use e-mail e senha ou entre em contato com o suporte.',
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
    if (!_useWebGoogle && _googleInitialization != null) {
      // Firebase session is already closed even if the provider cleanup fails.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // No account data or tokens are logged.
      }
    }
  }

  User? get currentUser => _auth.currentUser;
}
