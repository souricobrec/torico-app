import '../core/app_colors.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/torico_logo.png',
                width: largura < 600 ? largura * 0.75 : 420,
              ),

              const SizedBox(height: 25),

              const Text(
                'Seu negócio vendendo. Onde você estiver.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),

              const SizedBox(height: 60),

              _platformButton(context, 'Mercado Pago', Colors.lightBlue),

              const SizedBox(height: 15),

              _platformButton(context, 'Stone', Colors.green),

              const SizedBox(height: 15),

              _platformButton(context, 'PagBank', Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _platformButton(BuildContext context, String plataforma, Color color) {
    final largura = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      height: largura < 600 ? 60 : 75,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuthScreen(plataforma: plataforma),
            ),
          );
        },
        child: Text(
          plataforma,
          style: TextStyle(
            fontSize: largura < 600 ? 22 : 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
