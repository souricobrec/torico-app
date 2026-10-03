import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'config/api_config.dart';
import 'config/firebase_auth_config.dart';
import 'screens/pilot_gate.dart';
import 'services/pilot_access_service.dart';
import 'screens/splash_screen.dart';
import 'services/domain_block_service.dart';
import 'services/auth_service.dart';
import 'services/mercado_pago_oauth_return.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialUri = Uri.base;
  final oauthReturn = kIsWeb ? MercadoPagoOAuthReturn.parse(initialUri) : null;
  // Validate build configuration before opening the app, including release.
  ApiConfig.baseUrl;

  final baseOptions = DefaultFirebaseOptions.currentPlatform;
  final firebaseOptions = kIsWeb
      ? FirebaseAuthConfig.resolveWebOptions(baseOptions, Uri.base)
      : baseOptions;
  await Firebase.initializeApp(options: firebaseOptions);

  final pilotAccess = PilotAccessService();
  if (DomainBlockService.shouldBlock) await pilotAccess.initialize(Uri.base);
  if (oauthReturn != null) MercadoPagoOAuthReturn.clearUrl(initialUri);
  runApp(ToricoApp(pilotAccess: pilotAccess, oauthReturn: oauthReturn));
}

class ToricoApp extends StatelessWidget {
  final PilotAccessService pilotAccess;
  final AuthService auth = AuthService();
  final MercadoPagoOAuthReturn? oauthReturn;
  ToricoApp({super.key, required this.pilotAccess, this.oauthReturn});

  @override
  Widget build(BuildContext context) {
    PilotIdentity? identity(User? user) => user == null
        ? null
        : PilotIdentity(
            user.uid,
            email: user.email,
            emailVerified: user.emailVerified,
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TORICO',
      home: DomainBlockService.shouldBlock
          ? PilotGate(
              access: pilotAccess,
              authChanges: FirebaseAuth.instance.userChanges().map(identity),
              initialIdentity: identity(FirebaseAuth.instance.currentUser),
              signIn: (email, password) async {
                await auth.login(email: email, password: password);
              },
              signInGoogle: () async {
                await auth.loginWithGoogle();
              },
              resetPassword: (email) => auth.resetPassword(email: email),
              createAccount: (email, password) async {
                await auth.register(email: email, password: password);
              },
              signOut: auth.logout,
              appBuilder: (_) => SplashScreen(oauthReturn: oauthReturn),
            )
          : SplashScreen(oauthReturn: oauthReturn),
    );
  }
}
