import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

const Set<String> _blockedPublicHosts = {
  'www.meutorico.com.br',
  'meutorico.com.br',
  'torico-ca479.web.app',
  'torico-ca479.firebaseapp.com',
};

bool get _isPublicHostBlocked {
  if (!kIsWeb) return false;

  final host = Uri.base.host.toLowerCase();
  return _blockedPublicHosts.contains(host);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ToricoApp());
}

class ToricoApp extends StatelessWidget {
  const ToricoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TORICO',
      home: _isPublicHostBlocked
          ? const LaunchHoldScreen()
          : const SplashScreen(),
    );
  }
}

class LaunchHoldScreen extends StatelessWidget {
  const LaunchHoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF031226);
    const card = Color(0xFF06182C);
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFFD54F);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: gold.withValues(alpha: 0.42),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/app_icon.png', width: 82),
                    const SizedBox(height: 18),
                    const Text(
                      'TORICO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: goldLight,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Estamos preparando o lançamento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'O acesso público ficará disponível em breve nas lojas. Obrigado pela compreensão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: gold.withValues(alpha: 0.24)),
                      ),
                      child: const Text(
                        'Seu negócio vendendo. Onde você estiver.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: goldLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
