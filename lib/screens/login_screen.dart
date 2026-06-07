import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_texts.dart';
import 'auth_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;
    final largura = tamanhoTela.width;
    final bool isMobile = largura < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 22 : 40,
            isMobile ? 18 : 46,
            isMobile ? 22 : 40,
            26,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  _Header(isMobile: isMobile),

                  SizedBox(height: isMobile ? 28 : 44),

                  const _IntroCard(),

                  SizedBox(height: isMobile ? 22 : 30),

                  _PlatformCard(
                    plataforma: 'Mercado Pago',
                    subtitle: 'Conecte suas vendas feitas pelo Mercado Pago',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.lightBlueAccent,
                    onTap: () => _abrirConexao(context, 'Mercado Pago'),
                  ),

                  const SizedBox(height: 14),

                  _PlatformCard(
                    plataforma: 'Stone',
                    subtitle: 'Acompanhe vendas da sua maquininha Stone',
                    icon: Icons.payments_rounded,
                    color: Colors.greenAccent,
                    onTap: () => _abrirConexao(context, 'Stone'),
                  ),

                  const SizedBox(height: 14),

                  _PlatformCard(
                    plataforma: 'PagBank',
                    subtitle: 'Monitore vendas conectadas ao PagBank',
                    icon: Icons.credit_card_rounded,
                    color: Colors.orangeAccent,
                    onTap: () => _abrirConexao(context, 'PagBank'),
                  ),

                  SizedBox(height: isMobile ? 20 : 30),

                  const _SimulationNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirConexao(BuildContext context, String plataforma) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(plataforma: plataforma)),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;

  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/images/app_icon.png', width: isMobile ? 76 : 120),

        SizedBox(height: isMobile ? 10 : 16),

        Text(
          'TORICO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldLight,
            fontSize: isMobile ? 38 : 56,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            height: 1,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),

        SizedBox(height: isMobile ? 8 : 14),

        Text(
          AppTexts.slogan,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.76),
            fontSize: isMobile ? 16 : 22,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 26),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold.withOpacity(0.40), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(color: AppColors.gold.withOpacity(0.055), blurRadius: 36),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 48 : 58,
            height: isMobile ? 48 : 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.12),
              border: Border.all(color: AppColors.gold.withOpacity(0.28)),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: AppColors.goldLight,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conecte sua plataforma',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 21 : 26,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Escolha onde suas vendas acontecem para o TORICO acompanhar tudo em tempo real.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: isMobile ? 14 : 16,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String plataforma;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.plataforma,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 22,
            vertical: isMobile ? 16 : 22,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.36), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 52 : 62,
                height: isMobile ? 52 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.13),
                  border: Border.all(color: color.withOpacity(0.32)),
                ),
                child: Icon(icon, color: color, size: isMobile ? 28 : 34),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plataforma,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 21 : 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontSize: isMobile ? 13 : 15,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: isMobile ? 30 : 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 15 : 18,
        vertical: isMobile ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.075),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.goldLight,
            size: isMobile ? 23 : 26,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Nesta versão de teste, a conexão é simulada para demonstrar o fluxo do TORICO.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: isMobile ? 13 : 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
