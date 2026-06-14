import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_texts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        title: const Text(
          'Sobre o TORICO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 22 : 40,
            12,
            isMobile ? 22 : 40,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(isMobile: isMobile),

              const SizedBox(height: 22),

              const _SectionTitle('O que é o TORICO?'),

              const SizedBox(height: 10),

              const _TextBlock(
                'O TORICO é uma plataforma SaaS simples para pequenos e médios comerciantes acompanharem vendas em tempo real, mesmo quando não estão no local.',
              ),

              const SizedBox(height: 16),

              const _TextBlock(
                'A ideia é direta: o dono do negócio abre o app e vê quanto vendeu hoje, sem precisar ligar para funcionários, conferir maquininha ou estar presencialmente no ponto de venda.',
              ),

              const SizedBox(height: 24),

              const _SectionTitle('Para quem é?'),

              const SizedBox(height: 12),

              const _BenefitTile(
                icon: Icons.storefront_rounded,
                title: 'Comerciantes',
                text:
                    'Ideal para quem vende em loja, barraca, quiosque, delivery, eventos ou ponto físico.',
              ),

              const SizedBox(height: 12),

              const _BenefitTile(
                icon: Icons.phone_iphone_rounded,
                title: 'Donos que acompanham de longe',
                text:
                    'Veja o movimento do negócio pelo celular, de onde estiver.',
              ),

              const SizedBox(height: 12),

              const _BenefitTile(
                icon: Icons.trending_up_rounded,
                title: 'Decisões mais rápidas',
                text:
                    'Acompanhe o desempenho do dia e perceba rapidamente se as vendas estão boas ou fracas.',
              ),

              const SizedBox(height: 24),

              const _InfoCard(),

              const SizedBox(height: 26),

              Center(
                child: Text(
                  'TORICO • ${AppTexts.slogan}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isMobile;

  const _HeroCard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.045),
          ],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/torico_logo.png',
            width: isMobile ? 210 : 260,
          ),

          const SizedBox(height: 24),

          const Text(
            AppTexts.slogan,
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Venda acompanhada em tempo real, com uma experiência simples, visual e pensada para o comerciante.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.goldLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String text;

  const _TextBlock(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.72),
        fontSize: 16,
        height: 1.55,
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.13),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: AppColors.goldLight, size: 24),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: 14,
                    height: 1.35,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.goldLight,
            size: 28,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              'O TORICO já recebe vendas aprovadas do Mercado Pago por integração oficial via OAuth, API e webhook. Stone e PagBank serão adicionados futuramente por integrações oficiais.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
