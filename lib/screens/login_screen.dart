import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_texts.dart';
import '../services/local_storage_service.dart';
import 'auth_screen.dart';
import 'connected_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalStorageService _storage = LocalStorageService();

  List<String> connectedPlatforms = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedPlatforms();
  }

  Future<void> _loadConnectedPlatforms() async {
    final platforms = await _storage.getConnectedPlatforms();

    if (!mounted) return;

    setState(() {
      connectedPlatforms = platforms;
      carregando = false;
    });
  }

  bool _isConnected(String plataforma) {
    return connectedPlatforms.contains(plataforma);
  }

  void _openPlatform(String plataforma) {
    if (_isConnected(plataforma)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConnectedScreen(plataforma: plataforma),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(plataforma: plataforma)),
    ).then((_) {
      _loadConnectedPlatforms();
    });
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

                  _IntroCard(connectedPlatforms: connectedPlatforms),

                  SizedBox(height: isMobile ? 22 : 30),

                  if (carregando)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                        color: AppColors.goldLight,
                      ),
                    )
                  else ...[
                    _PlatformCard(
                      plataforma: 'Mercado Pago',
                      subtitle:
                          'Ative uma conexão simulada do Mercado Pago para testar o painel',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.lightBlueAccent,
                      conectado: _isConnected('Mercado Pago'),
                      onTap: () => _openPlatform('Mercado Pago'),
                    ),

                    const SizedBox(height: 14),

                    _PlatformCard(
                      plataforma: 'Stone',
                      subtitle:
                          'Ative uma conexão simulada da Stone para testar o painel',
                      icon: Icons.payments_rounded,
                      color: Colors.greenAccent,
                      conectado: _isConnected('Stone'),
                      onTap: () => _openPlatform('Stone'),
                    ),

                    const SizedBox(height: 14),

                    _PlatformCard(
                      plataforma: 'PagBank',
                      subtitle:
                          'Ative uma conexão simulada do PagBank para testar o painel',
                      icon: Icons.credit_card_rounded,
                      color: Colors.orangeAccent,
                      conectado: _isConnected('PagBank'),
                      onTap: () => _openPlatform('PagBank'),
                    ),
                  ],

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
  final List<String> connectedPlatforms;

  const _IntroCard({required this.connectedPlatforms});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    final hasConnected = connectedPlatforms.isNotEmpty;
    final title = hasConnected
        ? 'Plataformas do negócio'
        : 'Comece conectando sua primeira plataforma';
    final subtitle = hasConnected
        ? 'O TORICO já está com conexão simulada ativa para ${connectedPlatforms.join(', ')}. As vendas de teste já podem aparecer no painel.'
        : 'Escolha onde suas vendas acontecem. Nesta versão, a conexão é simulada para você testar o painel do TORICO.';

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
            child: Icon(
              hasConnected ? Icons.hub_rounded : Icons.link_rounded,
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
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 21 : 26,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  subtitle,
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
  final bool conectado;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.plataforma,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.conectado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    final Color statusColor = conectado ? Colors.greenAccent : Colors.white54;
    final String statusText = conectado ? 'Conectado' : 'Desconectado';

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
            color: conectado
                ? color.withOpacity(0.075)
                : Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: conectado
                  ? color.withOpacity(0.70)
                  : Colors.white.withOpacity(0.12),
              width: conectado ? 1.6 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 52 : 62,
                height: isMobile ? 52 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: conectado
                      ? color.withOpacity(0.13)
                      : Colors.white.withOpacity(0.055),
                  border: Border.all(
                    color: conectado
                        ? color.withOpacity(0.32)
                        : Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Icon(
                  icon,
                  color: conectado ? color : Colors.white54,
                  size: isMobile ? 28 : 34,
                ),
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

                    const SizedBox(height: 7),

                    _StatusBadge(
                      text: statusText,
                      color: statusColor,
                      connected: conectado,
                    ),

                    const SizedBox(height: 7),

                    Text(
                      conectado
                          ? 'Esta fonte está vinculada em modo simulado. A integração real será liberada em uma próxima etapa.'
                          : subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontSize: isMobile ? 13 : 15,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                conectado
                    ? Icons.dashboard_customize_rounded
                    : Icons.chevron_right_rounded,
                color: conectado ? color : Colors.white54,
                size: isMobile ? 30 : 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool connected;

  const _StatusBadge({
    required this.text,
    required this.color,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: connected
            ? Colors.greenAccent.withOpacity(0.12)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: connected
              ? Colors.greenAccent.withOpacity(0.35)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
              'Nesta versão de teste, a conexão é simulada. Vendas reais ainda não são recebidas automaticamente. Na integração real, cada plataforma exigirá autorização própria antes de enviar vendas ao TORICO.',
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
