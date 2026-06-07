import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_texts.dart';
import '../services/local_storage_service.dart';
import 'connected_screen.dart';
import 'login_screen.dart';
import 'owner_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalStorageService _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    verificarFluxoInicial();
  }

  Future<void> verificarFluxoInicial() async {
    await Future.delayed(const Duration(seconds: 3));

    final usuario = FirebaseAuth.instance.currentUser;
    final plataforma = await _storage.getConnectedPlatform();

    if (!mounted) return;

    if (usuario == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerLoginScreen()),
      );
      return;
    }

    if (plataforma != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConnectedScreen(plataforma: plataforma),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/torico_logo.png',
                width: largura < 600 ? largura * 0.75 : 420,
              ),

              const SizedBox(height: 20),

              const Text(
                AppTexts.slogan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 50),

              const CircularProgressIndicator(color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
