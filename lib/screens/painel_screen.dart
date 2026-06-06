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

  @override
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

  bool mostrarMoedas = false;
  bool mostrarGanho = false;

  int vendaId = 0;
  final AudioService _audioService = AudioService();

  Future<void> novaVenda() async {
    vendaId++;
    final venda = SaleSimulatorService.generateSale();

    await _salesController.addSale(venda);

    setState(() {
      mostrarMoedas = true;
      mostrarGanho = true;
    });
    _audioService.playCashSound();
    final vendaAtual = vendaId;

    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && vendaAtual == vendaId) {
        setState(() {
          mostrarGanho = false;
        });
      }
    });

    Future.delayed(const Duration(seconds: 35), () {
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

  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final altura = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(plataforma: widget.plataforma),
            ),
          );
        },
        child: const Icon(Icons.settings, color: Colors.black),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                Text(
                  'TORICO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: largura < 600 ? largura * 0.08 : 46,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'VENDIDO HOJE',
                  style: TextStyle(
                    color: AppColors.gold,
                    letterSpacing: 3,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 45,
                  child: mostrarGanho
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey(vendaId),
                          duration: const Duration(seconds: 12),
                          tween: Tween(begin: 0, end: 1),
                          builder: (context, value, child) {
                            final opacity = value < 0.90
                                ? 1.0
                                : 1.0 - ((value - 0.90) / 0.10);

                            return Transform.translate(
                              offset: Offset(0, -20 * value),
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            '+ ${CurrencyFormatter.format(_salesController.lastSale?.amount ?? 0)}',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    CurrencyFormatter.format(_salesController.totalSold),
                    key: ValueKey(_salesController.totalSold),
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontSize: largura < 600 ? largura * 0.10 : 58,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: Center(
                    child: _salesController.totalSold == 0
                        ? const Text(
                            'Aguardando a primeira venda...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          )
                        : Image.asset(
                            'assets/images/money_bag.png',
                            height: altura * 0.30,
                          ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: largura < 600 ? 60 : 75,
                    child: ElevatedButton(
                      onPressed: novaVenda,
                      child: const Text(
                        '+ Nova Venda',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (mostrarMoedas) CoinRain(vendaId: vendaId),
        ],
      ),
    );
  }
}
