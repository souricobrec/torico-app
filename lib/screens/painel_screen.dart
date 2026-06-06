import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:torico/models/sale.dart';
import '../core/app_colors.dart';
import '../widgets/coin_rain.dart';
import '../services/sale_simulator_service.dart';

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  double totalVendido = 0.00;
  Sale? ultimaVenda;

  bool mostrarMoedas = false;
  bool mostrarGanho = false;

  int vendaId = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void novaVenda() {
    vendaId++;
    final venda = SaleSimulatorService.generateSale();

    setState(() {
      totalVendido += venda.amount;
      ultimaVenda = venda;
      mostrarMoedas = true;
      mostrarGanho = true;
    });
    _audioPlayer.play(AssetSource('sounds/cash.mp3'));
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
          'Nova venda recebida! + R\$ ${venda.amount.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final altura = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                            '+ R\$ ${ultimaVenda?.amount.toStringAsFixed(2) ?? '0.00'}',
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
                    'R\$ ${totalVendido.toStringAsFixed(2)}',
                    key: ValueKey(totalVendido),
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
                    child: Image.asset(
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
