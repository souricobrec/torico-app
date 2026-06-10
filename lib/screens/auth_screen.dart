import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/integration_service.dart';
import '../services/local_storage_service.dart';
import 'connected_screen.dart';

class AuthScreen extends StatefulWidget {
  final String plataforma;

  const AuthScreen({super.key, required this.plataforma});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final IntegrationService _integrationService = IntegrationService();
  final LocalStorageService _localStorageService = LocalStorageService();

  bool carregando = false;

  Future<void> conectar() async {
    setState(() {
      carregando = true;
    });

    final conectado = await _integrationService.connect(widget.plataforma);

    if (conectado && mounted) {
      await _localStorageService.addConnectedPlatform(widget.plataforma);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConnectedScreen(plataforma: widget.plataforma),
        ),
      );
    }

    if (mounted) {
      setState(() {
        carregando = false;
      });
    }
  }

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
            isMobile ? 22 : 48,
            isMobile ? 22 : 40,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  _Header(isMobile: isMobile),

                  SizedBox(height: isMobile ? 28 : 44),

                  _ConnectionCard(
                    plataforma: widget.plataforma,
                    carregando: carregando,
                  ),

                  SizedBox(height: isMobile ? 24 : 34),

                  _StepsCard(
                    plataforma: widget.plataforma,
                    carregando: carregando,
                  ),

                  SizedBox(height: isMobile ? 24 : 34),

                  SizedBox(
                    width: double.infinity,
                    height: isMobile ? 58 : 70,
                    child: ElevatedButton(
                      onPressed: carregando ? null : conectar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.gold.withValues(
                          alpha: 0.45,
                        ),
                        elevation: 10,
                        shadowColor: AppColors.gold.withValues(alpha: 0.30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: carregando
                          ? const SizedBox(
                              width: 27,
                              height: 27,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.black,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Autorizar conexão',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 26),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const _SimulationNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
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
        Image.asset('assets/images/app_icon.png', width: isMobile ? 74 : 112),

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
          'Conecte suas vendas ao painel',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: isMobile ? 16 : 22,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final String plataforma;
  final bool carregando;

  const _ConnectionCard({required this.plataforma, required this.carregando});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.46),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.06),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: isMobile ? 76 : 92,
            height: isMobile ? 76 : 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: carregando
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : AppColors.gold.withValues(alpha: 0.11),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.36)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(
                    alpha: carregando ? 0.28 : 0.10,
                  ),
                  blurRadius: carregando ? 28 : 14,
                ),
              ],
            ),
            child: Icon(
              carregando ? Icons.sync_rounded : Icons.add_link_rounded,
              color: AppColors.goldLight,
              size: isMobile ? 38 : 46,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            plataforma,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: isMobile ? 34 : 42,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            carregando
                ? 'Conectando ao $plataforma...'
                : 'Autorize esta plataforma para adicioná-la às fontes de venda do seu negócio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: isMobile ? 16 : 18,
              height: 1.4,
            ),
          ),

          if (carregando) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.goldLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final String plataforma;
  final bool carregando;

  const _StepsCard({required this.plataforma, required this.carregando});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          _StepItem(
            icon: Icons.verified_user_rounded,
            title: '1. Autorização segura',
            text: 'Você confirma a plataforma que deseja conectar.',
            active: true,
          ),

          const SizedBox(height: 16),

          _StepItem(
            icon: Icons.hub_rounded,
            title: '2. Adicionar $plataforma',
            text: carregando
                ? 'Estamos preparando esta fonte de vendas.'
                : 'O TORICO adicionará esta plataforma ao seu negócio.',
            active: carregando,
          ),

          const SizedBox(height: 16),

          _StepItem(
            icon: Icons.insights_rounded,
            title: '3. Painel consolidado',
            text: 'O painel mostrará o total vendido do negócio no dia.',
            active: false,
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final bool active;

  const _StepItem({
    required this.icon,
    required this.title,
    required this.text,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.gold.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.055),
            border: Border.all(
              color: active
                  ? AppColors.gold.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            color: active ? AppColors.goldLight : Colors.white54,
            size: 23,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: active ? AppColors.goldLight : Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 13.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Nesta versão de teste, a autorização é simulada. Na integração real, cada plataforma exigirá login/autorização própria.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.46),
        fontSize: 12.5,
        height: 1.35,
      ),
    );
  }
}
