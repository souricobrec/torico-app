import 'package:flutter/material.dart';

class LaunchBlockScreen extends StatelessWidget {
  const LaunchBlockScreen({super.key});

  static const Color _background = Color(0xFF031226);
  static const Color _backgroundBottom = Color(0xFF020B16);
  static const Color _card = Color(0xFF06182C);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _background,
              Color(0xFF05172D),
              _backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
                  decoration: BoxDecoration(
                    color: _card.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.62),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.38),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/app_icon.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 88,
                            height: 88,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _gold.withValues(alpha: 0.12),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.55),
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              'T',
                              style: TextStyle(
                                color: _goldLight,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'TORICO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _goldLight,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Estamos preparando o lançamento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'O acesso público ficará disponível em breve. Nesta fase, o TORICO está em preparação para lançamento nas lojas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 15.5,
                          height: 1.42,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              color: _goldLight,
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                'Em breve disponível nas lojas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _goldLight,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Seu negócio vendendo. Onde você estiver.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 68,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: const LinearGradient(
                            colors: [
                              _gold,
                              _goldLight,
                              _gold,
                            ],
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
      ),
    );
  }
}
