import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/integration_service.dart';
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
  final IntegrationService _integrationService = IntegrationService();

  static const List<_IntegrationInfo> integrationCatalog = [
    _IntegrationInfo(
      platform: 'Mercado Pago',
      platformId: 'mercado_pago',
      status: 'Conectado oficialmente',
      description: 'Integração oficial ativa por autorização segura.',
    ),
    _IntegrationInfo(
      platform: 'Stone',
      platformId: 'stone',
      status: 'Em andamento',
      description: 'Integração futura por canais oficiais.',
    ),
    _IntegrationInfo(
      platform: 'PagBank',
      platformId: 'pagbank',
      status: 'Em andamento',
      description: 'Integração futura por canais oficiais.',
    ),
    _IntegrationInfo(
      platform: 'Cielo',
      platformId: 'cielo',
      status: 'Em andamento',
      description: 'Integração futura por canais oficiais.',
    ),
    _IntegrationInfo(
      platform: 'Rede',
      platformId: 'rede',
      status: 'Ativação assistida',
      description: 'Integração via API Gestão de Vendas, com ativação segura pelo backend.',
    ),
    _IntegrationInfo(
      platform: 'Getnet',
      platformId: 'getnet',
      status: 'Em andamento',
      description: 'Integração futura por canais oficiais.',
    ),
    _IntegrationInfo(
      platform: 'Pagar.me',
      platformId: 'pagarme',
      status: 'Em andamento',
      description: 'Integração futura por canais oficiais.',
    ),
    _IntegrationInfo(
      platform: 'Asaas',
      platformId: 'asaas',
      status: 'Em andamento',
      description: 'Integração futura por canais oficiais.',
    ),
    _IntegrationInfo(
      platform: 'InfinitePay',
      platformId: 'infinitepay',
      status: 'Em análise',
      description: 'Integração em análise para versão futura.',
    ),
  ];

  static List<String> get allPlatforms => integrationCatalog
      .map((integration) => integration.platform)
      .toList(growable: false);

  List<String> connectedPlatforms = [];
  bool carregando = true;
  bool _activeIntegrationsExpanded = true;
  bool _pendingIntegrationsExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    List<String> platforms;

    try {
      platforms = await _integrationService.syncConnectedPlatformsToLocalStorage(
        _storage,
      );
    } catch (_) {
      platforms = await _storage.getConnectedPlatforms();
    }

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

  List<_IntegrationInfo> get activeIntegrations {
    return integrationCatalog
        .where(
          (integration) => connectedPlatforms.contains(integration.platform),
        )
        .toList(growable: false);
  }

  List<_IntegrationInfo> get pendingIntegrations {
    return integrationCatalog
        .where(
          (integration) =>
              integration.platform != 'Mercado Pago' &&
              !connectedPlatforms.contains(integration.platform),
        )
        .toList(growable: false);
  }

  String get _statusText {
    if (connectedPlatforms.isEmpty) {
      return 'Nenhuma plataforma conectada';
    }

    if (connectedPlatforms.length == 1) {
      if (connectedPlatforms.first == 'Mercado Pago') {
        return 'Monitorando Mercado Pago com integração oficial';
      }

      if (connectedPlatforms.first == 'Rede') {
        return 'Monitorando Rede com integração por API';
      }

      return 'Monitorando ${connectedPlatforms.first} em preparação';
    }

    return 'Monitorando ${connectedPlatforms.length} fontes de venda';
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderCard(),

              const SizedBox(height: 14),

              _PlatformsOverviewCard(
                connectedPlatforms: connectedPlatforms,
                disconnectedPlatforms: disconnectedPlatforms,
                carregando: carregando,
              ),

              const SizedBox(height: 6),

              _StatusCard(statusText: _statusText),

              const SizedBox(height: 6),

              const _SimulationInfoCard(),

              const SizedBox(height: 16),

              const _SectionTitle(
                title: 'Integrações',
                subtitle: 'Acompanhe fontes ativas e próximas integrações.',
              ),

              const SizedBox(height: 6),

              _CollapsibleIntegrationsSection(
                title: 'Integrações ativadas',
                subtitle: 'Fontes já conectadas ao painel.',
                expanded: _activeIntegrationsExpanded,
                count: activeIntegrations.length,
                onToggle: () {
                  setState(() {
                    _activeIntegrationsExpanded = !_activeIntegrationsExpanded;
                  });
                },
                children: activeIntegrations.isEmpty
                    ? const [
                        _CompactInfoCard(
                          icon: Icons.info_outline_rounded,
                          text:
                              'Nenhuma integração ativa no momento. Conecte uma plataforma em Gerenciar conexões.',
                        ),
                      ]
                    : activeIntegrations
                          .map(
                            (integration) => _IntegrationStatusCard(
                              platform: integration.platform,
                              platformId: integration.platformId,
                              connected: true,
                              realStatus: integration.status,
                              description: integration.description,
                            ),
                          )
                          .toList(),
              ),

              const SizedBox(height: 8),

              _CollapsibleIntegrationsSection(
                title: 'Integrações em andamento',
                subtitle: 'Plataformas planejadas para próximas versões.',
                expanded: _pendingIntegrationsExpanded,
                count: pendingIntegrations.length,
                onToggle: () {
                  setState(() {
                    _pendingIntegrationsExpanded =
                        !_pendingIntegrationsExpanded;
                  });
                },
                children: pendingIntegrations
                    .map(
                      (integration) => _IntegrationStatusCard(
                        platform: integration.platform,
                        platformId: integration.platformId,
                        connected: false,
                        realStatus: integration.status,
                        description: integration.description,
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 12),

              const _IntegrationSecurityCard(),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Conta e aplicativo',
                subtitle: 'Conta, conexões e informações do app.',
              ),

              const SizedBox(height: 6),

              _SettingsActionTile(
                icon: Icons.hub_rounded,
                title: 'Gerenciar conexões',
                subtitle: 'Conectar ou revisar fontes de venda',
                iconColor: AppColors.goldLight,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );

                  _loadPlatforms();
                },
              ),

              const SizedBox(height: 6),

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

              const SizedBox(height: 6),

              _SettingsActionTile(
                icon: Icons.link_off_rounded,
                title: 'Limpar conexões deste dispositivo',
                subtitle: 'Remove conexões locais deste navegador',
                iconColor: Colors.redAccent,
                danger: true,
                onTap: () {
                  _showDisconnectDialog(context);
                },
              ),

              const SizedBox(height: 6),

              _SettingsActionTile(
                icon: Icons.logout_rounded,
                title: 'Sair da conta',
                subtitle: 'Encerra a sessão neste dispositivo',
                iconColor: Colors.white70,
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),

              const SizedBox(height: 18),

              Center(
                child: Text(
                  'TORICO • Seu negócio vendendo. Onde você estiver.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
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
          title: 'Limpar conexões deste dispositivo?',
          message:
              'Isso removerá as conexões salvas neste dispositivo. O histórico de vendas salvo na nuvem não será apagado.',
          primaryText: 'Limpar',
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

class _IntegrationInfo {
  final String platform;
  final String platformId;
  final String status;
  final String description;

  const _IntegrationInfo({
    required this.platform,
    required this.platformId,
    required this.status,
    required this.description,
  });
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Seu negócio vendendo. Onde você estiver.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.2,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.52),
            fontSize: 12.3,
            height: 1.3,
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: carregando
          ? const LinearProgressIndicator(color: AppColors.goldLight)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        color: AppColors.goldLight,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fontes do negócio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Veja suas fontes de venda conectadas ou em preparação.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.3,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                const _PlatformSectionTitle(
                  title: 'Conectadas neste dispositivo',
                  icon: Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                ),

                const SizedBox(height: 6),

                if (connectedPlatforms.isEmpty)
                  const _EmptyPlatformMessage(
                    text:
                        'Conecte Mercado Pago ou Rede para iniciar o painel.',
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
                  title: 'Disponíveis',
                  icon: Icons.radio_button_unchecked_rounded,
                  color: Colors.white54,
                ),

                const SizedBox(height: 6),

                if (disconnectedPlatforms.isEmpty)
                  const _EmptyPlatformMessage(
                    text:
                        'Todas as fontes disponíveis já estão ativadas neste dispositivo.',
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
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: connected
            ? Colors.greenAccent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: connected
              ? Colors.greenAccent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.12),
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
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            platform,
            style: TextStyle(
              color: connected ? Colors.white : Colors.white70,
              fontSize: 12.3,
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
        color: Colors.white.withValues(alpha: 0.50),
        fontSize: 12.3,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasPlatform
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPlatform
              ? Colors.greenAccent.withValues(alpha: 0.22)
              : AppColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasPlatform
                  ? Colors.greenAccent.withValues(alpha: 0.14)
                  : AppColors.gold.withValues(alpha: 0.12),
            ),
            child: Icon(
              hasPlatform
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: hasPlatform ? Colors.greenAccent : AppColors.goldLight,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status do painel',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
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

class _SimulationInfoCard extends StatelessWidget {
  const _SimulationInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.goldLight,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mercado Pago usa OAuth e webhook oficiais. Demais integrações serão liberadas por canais oficiais.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 12.3,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleIntegrationsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool expanded;
  final int count;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _CollapsibleIntegrationsSection({
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.count,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.20),
                                ),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.goldLight,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CompactInfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldLight, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.2,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationStatusCard extends StatelessWidget {
  final String platform;
  final String platformId;
  final bool connected;
  final String realStatus;
  final String description;

  const _IntegrationStatusCard({
    required this.platform,
    required this.platformId,
    required this.connected,
    required this.realStatus,
    required this.description,
  });

  IconData get _platformIcon {
    if (platformId == 'mercado_pago') {
      return Icons.account_balance_wallet_rounded;
    }

    if (platformId == 'stone') {
      return Icons.credit_card_rounded;
    }

    if (platformId == 'pagbank') {
      return Icons.payments_rounded;
    }

    if (platformId == 'cielo' ||
        platformId == 'rede' ||
        platformId == 'getnet') {
      return Icons.credit_score_rounded;
    }

    if (platformId == 'pagarme' || platformId == 'asaas') {
      return Icons.receipt_long_rounded;
    }

    if (platformId == 'infinitepay') {
      return Icons.contactless_rounded;
    }

    return Icons.hub_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final Color simulationColor = connected
        ? Colors.greenAccent
        : Colors.white54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.24)),
            ),
            child: Icon(_platformIcon, color: AppColors.goldLight, size: 25),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallStatusPill(
                      icon: connected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      text: connected ? 'Conectado' : 'Em andamento',
                      color: simulationColor,
                    ),
                    _SmallStatusPill(
                      icon: Icons.lock_outline_rounded,
                      text: realStatus,
                      color: AppColors.goldLight,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 11.2,
                    height: 1.3,
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

class _SmallStatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SmallStatusPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationSecurityCard extends StatelessWidget {
  const _IntegrationSecurityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Colors.greenAccent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integrações reais com segurança',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'O TORICO não pede senha, 2FA ou cartão de plataformas externas. Integrações reais usam autorização oficial, APIs e webhooks.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 11.2,
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: danger
                ? Colors.redAccent.withValues(alpha: 0.055)
                : Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: danger
                  ? Colors.redAccent.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? Colors.redAccent : Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 11.2,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35),
                size: 22,
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
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
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
