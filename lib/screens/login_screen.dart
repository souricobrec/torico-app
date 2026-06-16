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

  static const Color _inProgressOrange = Color(0xFFFFA726);
  static const Color _availableGreen = Color(0xFF00FF66);

  static const List<_PaymentPlatformOption> _platformOptions = [
    _PaymentPlatformOption(
      id: 'mercado_pago',
      name: 'Mercado Pago',
      available: true,
    ),
    _PaymentPlatformOption(id: 'pagbank', name: 'PagBank', available: false),
    _PaymentPlatformOption(id: 'stone', name: 'Stone', available: false),
    _PaymentPlatformOption(id: 'cielo', name: 'Cielo', available: false),
    _PaymentPlatformOption(id: 'rede', name: 'Rede', available: false),
    _PaymentPlatformOption(id: 'getnet', name: 'Getnet', available: false),
    _PaymentPlatformOption(id: 'pagar_me', name: 'Pagar.me', available: false),
    _PaymentPlatformOption(id: 'asaas', name: 'Asaas', available: false),
  ];

  List<String> connectedPlatforms = [];
  bool carregando = true;
  String selectedPlatformId = 'mercado_pago';

  @override
  void initState() {
    super.initState();
    _loadConnectedPlatforms();
  }

  Future<void> _loadConnectedPlatforms() async {
    final platforms = await _storage.getConnectedPlatforms();

    if (!mounted) return;

    String nextSelectedPlatformId = selectedPlatformId;

    for (final platform in _platformOptions) {
      if (platforms.contains(platform.name)) {
        nextSelectedPlatformId = platform.id;
        break;
      }
    }

    setState(() {
      connectedPlatforms = platforms;
      selectedPlatformId = nextSelectedPlatformId;
      carregando = false;
    });
  }

  bool _isConnected(String plataforma) {
    return connectedPlatforms.contains(plataforma);
  }

  _PaymentPlatformOption get _selectedPlatform {
    return _platformOptions.firstWhere(
      (platform) => platform.id == selectedPlatformId,
      orElse: () => _platformOptions.first,
    );
  }

  void _handlePrimaryAction() {
    final platform = _selectedPlatform;

    if (_isConnected(platform.name)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConnectedScreen(plataforma: platform.name),
        ),
      );
      return;
    }

    if (platform.available) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(plataforma: platform.name),
        ),
      ).then((_) {
        _loadConnectedPlatforms();
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF06182C),
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${platform.name} está com integração em andamento e será liberado em uma próxima versão do TORICO.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    final selected = _selectedPlatform;
    final selectedConnected = _isConnected(selected.name);
    final selectedInProgress = !selected.available && !selectedConnected;

    final Color actionColor = selectedConnected
        ? Colors.greenAccent
        : selected.available
        ? AppColors.gold
        : _inProgressOrange;

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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _Header(isMobile: isMobile),

                  SizedBox(height: isMobile ? 24 : 38),

                  _IntroCard(connectedPlatforms: connectedPlatforms),

                  SizedBox(height: isMobile ? 16 : 24),

                  if (carregando)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                        color: AppColors.goldLight,
                      ),
                    )
                  else ...[
                    _PlatformMenu(
                      options: _platformOptions,
                      selectedPlatformId: selectedPlatformId,
                      connectedPlatforms: connectedPlatforms,
                      inProgressColor: _inProgressOrange,
                      availableColor: _availableGreen,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedPlatformId = value;
                        });
                      },
                    ),

                    SizedBox(height: isMobile ? 56 : 70),

                    SizedBox(
                      width: double.infinity,
                      height: isMobile ? 54 : 62,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedConnected
                              ? Colors.greenAccent.withValues(alpha: 0.16)
                              : selected.available
                              ? AppColors.gold
                              : _inProgressOrange.withValues(alpha: 0.16),
                          foregroundColor: selectedConnected
                              ? Colors.greenAccent
                              : selected.available
                              ? Colors.black
                              : _inProgressOrange,
                          elevation: selected.available || selectedConnected
                              ? 10
                              : 0,
                          shadowColor: selectedInProgress
                              ? _inProgressOrange.withValues(alpha: 0.18)
                              : actionColor.withValues(alpha: 0.22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selectedConnected
                                  ? Colors.greenAccent.withValues(alpha: 0.42)
                                  : selected.available
                                  ? AppColors.goldLight.withValues(alpha: 0.42)
                                  : _inProgressOrange.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                          ),
                        ),
                        onPressed: _handlePrimaryAction,
                        icon: Icon(
                          selectedConnected
                              ? Icons.dashboard_customize_rounded
                              : selected.available
                              ? Icons.link_rounded
                              : Icons.schedule_rounded,
                        ),
                        label: Text(
                          selectedConnected
                              ? 'Abrir painel'
                              : selected.available
                              ? 'Conectar ${selected.name}'
                              : 'Integração em andamento',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: isMobile ? 16 : 24),

                  const _IntegrationNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentPlatformOption {
  final String id;
  final String name;
  final bool available;

  const _PaymentPlatformOption({
    required this.id,
    required this.name,
    required this.available,
  });
}

class _Header extends StatelessWidget {
  final bool isMobile;

  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/images/app_icon.png', width: isMobile ? 72 : 112),

        SizedBox(height: isMobile ? 8 : 14),

        Text(
          'TORICO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldLight,
            fontSize: isMobile ? 38 : 54,
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
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: isMobile ? 15.5 : 21,
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.38),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 46 : 56,
            height: isMobile ? 46 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
            ),
            child: Icon(
              hasConnected ? Icons.hub_rounded : Icons.add_link_rounded,
              color: AppColors.goldLight,
              size: 27,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasConnected
                      ? 'Escolha uma plataforma'
                      : 'Conecte sua primeira plataforma',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 21 : 25,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  hasConnected
                      ? 'O TORICO já monitora ${connectedPlatforms.join(', ')}. Você pode abrir o painel ou preparar novas integrações.'
                      : 'Selecione onde suas vendas acontecem e conecte pelo fluxo oficial disponível.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
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

class _PlatformMenu extends StatelessWidget {
  final List<_PaymentPlatformOption> options;
  final String selectedPlatformId;
  final List<String> connectedPlatforms;
  final Color inProgressColor;
  final Color availableColor;
  final ValueChanged<String?> onChanged;

  const _PlatformMenu({
    required this.options,
    required this.selectedPlatformId,
    required this.connectedPlatforms,
    required this.inProgressColor,
    required this.availableColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.goldLight.withValues(alpha: 0.32),
          width: 1.4,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPlatformId,
          isExpanded: true,
          dropdownColor: const Color(0xFF06182C),
          iconEnabledColor: AppColors.goldLight,
          style: const TextStyle(color: Colors.white),
          onChanged: onChanged,
          items: options.map((platform) {
            final connected = connectedPlatforms.contains(platform.name);

            return DropdownMenuItem<String>(
              value: platform.id,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      platform.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MiniStatusBadge(
                    text: connected
                        ? 'Conectado'
                        : platform.available
                        ? 'Disponível'
                        : 'Em andamento',
                    color: connected
                        ? Colors.greenAccent
                        : platform.available
                        ? availableColor
                        : inProgressColor,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniStatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        boxShadow: color == const Color(0xFF00FF66)
            ? [BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 10)]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _IntegrationNotice extends StatelessWidget {
  const _IntegrationNotice();

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
        color: AppColors.gold.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.20)),
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
              'O TORICO só libera integrações reais quando houver conexão oficial, segura e validada no backend. Mercado Pago já está disponível; as demais plataformas estão com integração em andamento.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
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
