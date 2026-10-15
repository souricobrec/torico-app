import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final bool _useWebGoogle;
  final Future<AuthCredential> Function() _nativeGoogleCredential;
  final Future<void> Function() _nativeGoogleSignOut;
  static int _logoutGeneration = 0;
  AuthService({
    FirebaseAuth? auth,
    bool? useWebGoogle,
    Future<AuthCredential> Function()? nativeGoogleCredential,
    Future<void> Function()? nativeGoogleSignOut,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _useWebGoogle = useWebGoogle ?? kIsWeb,
       _nativeGoogleCredential = nativeGoogleCredential ?? _googleCredential,
       _nativeGoogleSignOut = nativeGoogleSignOut ?? _signOutGoogle;
  static Future<void>? _googleInitialization;

  static Future<void> _initializeGoogle() async {
    try {
      await (_googleInitialization ??= GoogleSignIn.instance.initialize());
    } catch (_) {
      _googleInitialization =
          null; // A transient initialization failure is retryable.
      rethrow;
    }
  }

  static Future<void> _signOutGoogle() async {
    // Firebase may restore a session in a fresh process, before any Google login.
    // Initialization alone never calls authenticate/lightweight authentication.
    await _initializeGoogle();
    await GoogleSignIn.instance.signOut();
  }

  static Future<AuthCredential> _googleCredential() async {
    await _initializeGoogle();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(code: 'google-missing-id-token');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  static String nativeGoogleErrorCode(GoogleSignInExceptionCode code) =>
      switch (code) {
        // Android SDK can report canceled for interrupted/failed credential UI.
        // Do not assert that the user voluntarily canceled it.
        GoogleSignInExceptionCode.canceled => 'google-sign-in-interrupted',
        GoogleSignInExceptionCode.clientConfigurationError =>
          'google-client-configuration',
        _ => 'google-sign-in-failed',
      };

  Future<UserCredential> _finishLogin(
    Future<UserCredential> request,
    int generation,
  ) async {
    final result = await request;
    if (generation != _logoutGeneration) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'session-ended');
    }
    return result;
  }

  AuthCredential? _pendingGoogleCredential;
  String? _pendingGoogleEmail;
  int? _pendingGoogleGeneration;

  /// Firebase's one-account-per-email setting must remain enabled.
  Future<UserCredential> loginWithGoogle() async {
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    final generation = _logoutGeneration;
    AuthCredential? nativeCredential;
    try {
      if (!_useWebGoogle) {
        nativeCredential = await _nativeGoogleCredential();
        if (generation != _logoutGeneration) {
          throw FirebaseAuthException(code: 'session-ended');
        }
        return await _finishLogin(
          _auth.signInWithCredential(nativeCredential),
          generation,
        );
      }
      return await _finishLogin(
        _auth.signInWithPopup(
          GoogleAuthProvider()
            ..setCustomParameters({'prompt': 'select_account'}),
        ),
        generation,
      );
    } on GoogleSignInException catch (e) {
      throw FirebaseAuthException(code: nativeGoogleErrorCode(e.code));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = e.credential ?? nativeCredential;
        _pendingGoogleEmail = e.email?.trim().toLowerCase();
        _pendingGoogleGeneration = generation;
      }
      rethrow;
    }
  }

  static String googleErrorMessage(String code) => switch (code) {
    'account-exists-with-different-credential' =>
      'Este e-mail já possui conta. Entre com e-mail e senha para vincular o Google à mesma conta.',
    'popup-closed-by-user' ||
    'google-sign-in-cancelled' => 'Login Google cancelado.',
    'cancelled-popup-request' || 'google-sign-in-interrupted' =>
      'Login Google não concluído. Se você não cancelou, tente novamente ou use e-mail e senha.',
    'session-ended' =>
      'Sessão encerrada. Toque em entrar para iniciar um novo login.',
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
    final generation = _logoutGeneration;
    final result = await _finishLogin(
      _auth.signInWithEmailAndPassword(email: email, password: password),
      generation,
    );
    final pending = _pendingGoogleCredential;
    final pendingEmail = _pendingGoogleEmail;
    final pendingGeneration = _pendingGoogleGeneration;
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    if (pendingGeneration == _logoutGeneration &&
        pending != null &&
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
    final generation = _logoutGeneration;
    final credential = await _finishLogin(
      _auth.createUserWithEmailAndPassword(email: email, password: password),
      generation,
    );

    await credential.user?.sendEmailVerification();

    return credential;
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    _logoutGeneration++;
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    await _auth.signOut();
    if (!_useWebGoogle) {
      // Firebase session is already closed even if the provider cleanup fails.
      try {
        await _nativeGoogleSignOut();
      } catch (_) {
        // Firebase stays signed out; never start authentication as recovery.
        debugPrint(
          'TORICO: sessão Firebase encerrada; limpeza local Google falhou.',
        );
      }
    }
  }

  User? get currentUser => _auth.currentUser;
}
