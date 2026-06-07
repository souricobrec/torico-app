import 'package:flutter/material.dart';
import 'package:torico/models/sale.dart';
import '../core/app_colors.dart';
import '../widgets/coin_rain.dart';
import '../services/sale_simulator_service.dart';
import '../services/audio_service.dart';
import '../core/currency_formatter.dart';
import 'package:torico/controllers/sales_controller.dart';
import 'settings_screen.dart';

class PainelScreen extends StatefulWidget {
  final String plataforma;

  const PainelScreen({super.key, required this.plataforma});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  final SalesController _salesController = SalesController();
  final AudioService _audioService = AudioService();

  bool mostrarMoedas = false;
  bool mostrarGanho = false;

  int vendaId = 0;

  @override
  void initState() {
    super.initState();
    carregarTotalSalvo();
  }

  Future<void> carregarTotalSalvo() async {
    await _salesController.loadTotalSold();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> novaVenda() async {
    vendaId++;
    final Sale venda = SaleSimulatorService.generateSale();

    await _salesController.addSale(venda);

    if (!mounted) return;

    setState(() {
      mostrarMoedas = true;
      mostrarGanho = true;
    });

    _audioService.playCashSound();

    final vendaAtual = vendaId;

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && vendaAtual == vendaId) {
        setState(() {
          mostrarGanho = false;
        });
      }
    });

    Future.delayed(const Duration(seconds: 14), () {
      if (mounted && vendaAtual == vendaId) {
        setState(() {
          mostrarMoedas = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nova venda recebida! + ${CurrencyFormatter.format(venda.amount)}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _salesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;
    final largura = tamanhoTela.width;
    final altura = tamanhoTela.height;
    final bool isMobile = largura < 600;

    final double logoSize = isMobile ? largura * 0.075 : 44;
    final double valorSize = isMobile ? largura * 0.095 : 56;
    final double sacoMoedasSize = isMobile ? altura * 0.24 : altura * 0.30;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
              child: Column(
                children: [
                  SizedBox(height: isMobile ? 14 : 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        'TORICO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: logoSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      _SettingsButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SettingsScreen(plataforma: widget.plataforma),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 26 : 38),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 18 : 28,
                      vertical: isMobile ? 22 : 30,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.035),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.28),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'VENDIDO HOJE',
                          style: TextStyle(
                            color: AppColors.gold,
                            letterSpacing: 3,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          height: 38,
                          child: mostrarGanho
                              ? TweenAnimationBuilder<double>(
                                  key: ValueKey(vendaId),
                                  duration: const Duration(seconds: 5),
                                  tween: Tween(begin: 0, end: 1),
                                  builder: (context, value, child) {
                                    final opacity = value < 0.75
                                        ? 1.0
                                        : 1.0 - ((value - 0.75) / 0.25);

                                    return Transform.translate(
                                      offset: Offset(0, -18 * value),
                                      child: Opacity(
                                        opacity: opacity.clamp(0.0, 1.0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '+ ${CurrencyFormatter.format(_salesController.lastSale?.amount ?? 0)}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        ),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            CurrencyFormatter.format(
                              _salesController.totalSold,
                            ),
                            key: ValueKey(_salesController.totalSold),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: valorSize,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 20 : 32),

                  Expanded(
                    child: Center(
                      child: _salesController.totalSold == 0
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.insights_rounded,
                                  color: AppColors.gold.withOpacity(0.65),
                                  size: isMobile ? 46 : 58,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aguardando a primeira venda...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            )
                          : Image.asset(
                              'assets/images/money_bag.png',
                              height: sacoMoedasSize,
                            ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      bottom: isMobile ? 18 : 24,
                      top: 10,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: isMobile ? 58 : 70,
                      child: ElevatedButton(
                        onPressed: novaVenda,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: AppColors.gold.withOpacity(0.30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          '+ Nova Venda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (mostrarMoedas) CoinRain(vendaId: vendaId),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.055),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: AppColors.goldLight,
            size: 24,
          ),
        ),
      ),
    );
  }
}
