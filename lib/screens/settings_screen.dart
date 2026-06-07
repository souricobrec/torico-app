import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'owner_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String plataforma;

  const SettingsScreen({super.key, required this.plataforma});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalStorageService _storage = LocalStorageService();

  static const List<String> allPlatforms = ['Mercado Pago', 'Stone', 'PagBank'];

  List<String> connectedPlatforms = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    final platforms = await _storage.getConnectedPlatforms();

    if (!mounted) return;

    setState(() {
      connectedPlatforms = platforms;
      carregando = false;
    });
  }

  List<String> get disconnectedPlatforms {
    return allPlatforms
        .where((platform) => !connectedPlatforms.contains(platform))
        .toList();
  }

  String get _statusText {
    if (connectedPlatforms.isEmpty) {
      return 'Nenhuma plataforma conectada';
    }

    if (connectedPlatforms.length == 1) {
      return 'Monitorando ${connectedPlatforms.first}';
    }

    return 'Monitorando ${connectedPlatforms.length} plataformas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        title: const Text(
          'Conta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderCard(),

              const SizedBox(height: 22),

              _PlatformsOverviewCard(
                connectedPlatforms: connectedPlatforms,
                disconnectedPlatforms: disconnectedPlatforms,
                carregando: carregando,
              ),

              const SizedBox(height: 18),

              _StatusCard(statusText: _statusText),

              const SizedBox(height: 28),

              const Text(
                'Conta e aplicativo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 12),

              _SettingsActionTile(
                icon: Icons.hub_rounded,
                title: 'Gerenciar plataformas',
                subtitle: 'Conectar ou revisar Mercado Pago, Stone e PagBank',
                iconColor: AppColors.goldLight,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );

                  _loadPlatforms();
                },
              ),

              const SizedBox(height: 12),

              _SettingsActionTile(
                icon: Icons.info_outline_rounded,
                title: 'Sobre o TORICO',
                subtitle: 'Conheça a proposta do aplicativo',
                iconColor: AppColors.goldLight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),

              const SizedBox(height: 12),

              _SettingsActionTile(
                icon: Icons.link_off_rounded,
                title: 'Desconectar plataformas',
                subtitle: 'Remove as conexões locais deste dispositivo',
                iconColor: Colors.redAccent,
                danger: true,
                onTap: () {
                  _showDisconnectDialog(context);
                },
              ),

              const SizedBox(height: 12),

              _SettingsActionTile(
                icon: Icons.logout_rounded,
                title: 'Sair da conta',
                subtitle: 'Encerra sua sessão neste dispositivo',
                iconColor: Colors.white70,
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),

              const SizedBox(height: 28),

              Center(
                child: Text(
                  'TORICO • Seu negócio vendendo. Onde você estiver.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
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

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return _ToricoDialog(
          title: 'Desconectar plataformas?',
          message:
              'Isso removerá as plataformas conectadas neste dispositivo. O histórico de vendas salvo na nuvem não será apagado.',
          primaryText: 'Desconectar',
          primaryColor: Colors.redAccent,
          onPrimary: () async {
            await _storage.clearConnectedPlatform();
            await _storage.clearTotalSold();

            if (!context.mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return _ToricoDialog(
          title: 'Sair da conta?',
          message:
              'Você deseja sair da sua conta TORICO? Os dados locais deste dispositivo serão limpos.',
          primaryText: 'Sair',
          primaryColor: AppColors.goldLight,
          onPrimary: () async {
            final authService = AuthService();

            await _storage.clearConnectedPlatform();
            await _storage.clearTotalSold();
            await authService.logout();

            if (!context.mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const OwnerLoginScreen()),
              (route) => false,
            );
          },
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withOpacity(0.22),
            Colors.white.withOpacity(0.045),
          ],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TORICO',
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Seu negócio vendendo. Onde você estiver.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PlatformsOverviewCard extends StatelessWidget {
  final List<String> connectedPlatforms;
  final List<String> disconnectedPlatforms;
  final bool carregando;

  const _PlatformsOverviewCard({
    required this.connectedPlatforms,
    required this.disconnectedPlatforms,
    required this.carregando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: carregando
          ? const LinearProgressIndicator(color: AppColors.goldLight)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withOpacity(0.14),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        color: AppColors.goldLight,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plataformas do negócio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Controle quais fontes de venda estão vinculadas ao TORICO.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const _PlatformSectionTitle(
                  title: 'Conectadas',
                  icon: Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                ),

                const SizedBox(height: 10),

                if (connectedPlatforms.isEmpty)
                  const _EmptyPlatformMessage(
                    text: 'Nenhuma plataforma conectada ainda.',
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: connectedPlatforms.map((platform) {
                      return _PlatformChip(platform: platform, connected: true);
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                const _PlatformSectionTitle(
                  title: 'Desconectadas',
                  icon: Icons.radio_button_unchecked_rounded,
                  color: Colors.white54,
                ),

                const SizedBox(height: 10),

                if (disconnectedPlatforms.isEmpty)
                  const _EmptyPlatformMessage(
                    text: 'Todas as plataformas disponíveis estão conectadas.',
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: disconnectedPlatforms.map((platform) {
                      return _PlatformChip(
                        platform: platform,
                        connected: false,
                      );
                    }).toList(),
                  ),
              ],
            ),
    );
  }
}

class _PlatformSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _PlatformSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PlatformChip extends StatelessWidget {
  final String platform;
  final bool connected;

  const _PlatformChip({required this.platform, required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.greenAccent : Colors.white54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: connected
            ? Colors.greenAccent.withOpacity(0.10)
            : Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: connected
              ? Colors.greenAccent.withOpacity(0.28)
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
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            platform,
            style: TextStyle(
              color: connected ? Colors.white : Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlatformMessage extends StatelessWidget {
  final String text;

  const _EmptyPlatformMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.50),
        fontSize: 13.5,
        height: 1.3,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String statusText;

  const _StatusCard({required this.statusText});

  @override
  Widget build(BuildContext context) {
    final bool hasPlatform = !statusText.contains('Nenhuma');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasPlatform
            ? Colors.greenAccent.withOpacity(0.08)
            : AppColors.gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasPlatform
              ? Colors.greenAccent.withOpacity(0.22)
              : AppColors.gold.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasPlatform
                  ? Colors.greenAccent.withOpacity(0.14)
                  : AppColors.gold.withOpacity(0.12),
            ),
            child: Icon(
              hasPlatform
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: hasPlatform ? Colors.greenAccent : AppColors.goldLight,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status do painel',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
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

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool danger;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: danger
                ? Colors.redAccent.withOpacity(0.055)
                : Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: danger
                  ? Colors.redAccent.withOpacity(0.20)
                  : Colors.white.withOpacity(0.09),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? Colors.redAccent : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.52),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToricoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryText;
  final Color primaryColor;
  final Future<void> Function() onPrimary;

  const _ToricoDialog({
    required this.title,
    required this.message,
    required this.primaryText,
    required this.primaryColor,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.gold.withOpacity(0.25)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white70, height: 1.35),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: onPrimary,
          child: Text(
            primaryText,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
