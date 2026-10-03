import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'config/api_config.dart';
import 'screens/pilot_gate.dart';
import 'services/pilot_access_service.dart';
import 'screens/splash_screen.dart';
import 'services/domain_block_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Validate build configuration before opening the app, including release.
  ApiConfig.baseUrl;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final pilotAccess = PilotAccessService();
  if (DomainBlockService.shouldBlock) await pilotAccess.initialize(Uri.base);
  runApp(ToricoApp(pilotAccess: pilotAccess));
}

class ToricoApp extends StatelessWidget {
  final PilotAccessService pilotAccess;
  const ToricoApp({super.key, required this.pilotAccess});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TORICO',
      home: DomainBlockService.shouldBlock
          ? PilotGate(
              access: pilotAccess,
              authChanges: FirebaseAuth.instance.authStateChanges().map(
                (user) => user?.uid,
              ),
              initialUid: FirebaseAuth.instance.currentUser?.uid,
              signIn: (email, password) async {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
              },
              signOut: FirebaseAuth.instance.signOut,
              appBuilder: (_) => const SplashScreen(),
            )
          : const SplashScreen(),
    );
  }
}
