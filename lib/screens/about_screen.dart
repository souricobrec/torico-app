import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_texts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Sobre o TORICO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/torico_logo.png', width: 220),

            const SizedBox(height: 30),

            const Text(
              AppTexts.slogan,
              style: TextStyle(
                color: AppColors.goldLight,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'O TORICO é um monitor de vendas em tempo real para comerciantes acompanharem seus negócios de qualquer lugar.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'A ideia é simples: abrir o app e saber imediatamente se sua barraca, maquininha ou ponto de venda está vendendo.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
