import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/currency_formatter.dart';
import '../controllers/sales_controller.dart';
import '../services/audio_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/coin_rain.dart';

class PainelScreen extends StatefulWidget {
  final String plataforma;

  const PainelScreen({super.key, required this.plataforma});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  final SalesController _salesController = SalesController();
  final AudioService _audioService = AudioService();
  final LocalStorageService _storage = LocalStorageService();

  bool mostrarMoedas = false;
  bool mostrarGanho = false;
  bool _totalInicializado = false;

  int vendaId = 0;
  double _ultimoTotalObservado = 0.0;
  double _ultimoGanho = 0.0;

  List<String> connectedPlatforms = [];

  @override
  void initState() {
    super.initState();

    _salesController.addListener(_atualizarTela);

    carregarPlataformas();
    carregarTotalSalvo();
    _salesController.startWatchingTodayTotal();
  }

  void _atualizarTela() {
    if (!mounted) return;

    final totalAtual = _salesController.totalSold;

    if (!_totalInicializado) {
      _ultimoTotalObservado = totalAtual;
      _totalInicializado = true;

      setState(() {});
      return;
    }

    final diferenca = totalAtual - _ultimoTotalObservado;
    _ultimoTotalObservado = totalAtual;

    if (diferenca > 0.009) {
      _dispararEfeitoNovaVenda(diferenca);
      return;
    }

    setState(() {});
  }

  void _dispararEfeitoNovaVenda(double valor) {
    vendaId++;
    _ultimoGanho = valor;

    // No iPhone/Safari, o som pode depender de permissão/interação prévia do usuário.
    _audioService.playCashSound();

    setState(() {
      mostrarMoedas = true;
      mostrarGanho = true;
    });

    final vendaAtual = vendaId;

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && vendaAtual == vendaId) {
        setState(() {
          mostrarGanho = false;
        });
      }
    });

    Future.delayed(const Duration(seconds: 9), () {
      if (mounted && vendaAtual == vendaId) {
        setState(() {
          mostrarMoedas = false;
        });
      }
    });
  }

  Future<void> carregarPlataformas() async {
    final platforms = await _storage.getConnectedPlatforms();

    if (!mounted) return;

    setState(() {
      connectedPlatforms = platforms;
    });
  }

  Future<void> carregarTotalSalvo() async {
    await _salesController.loadTotalSold();

    if (mounted) {
      setState(() {});
    }
  }

  String get _fonteVendas {
    if (connectedPlatforms.isEmpty) {
      return widget.plataforma;
    }

    if (connectedPlatforms.length == 1) {
      return connectedPlatforms.first;
    }

    return connectedPlatforms.join(' + ');
  }

  @override
  void dispose() {
    _salesController.removeListener(_atualizarTela);
    _audioService.dispose();
    _salesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;
    final largura = tamanhoTela.width;
    final bool isMobile = largura < 600;

    final double logoSize = isMobile ? largura * 0.075 : 44;
    final double cardWidth = isMobile
        ? (largura * 0.74).clamp(300.0, 410.0).toDouble()
        : 560;
    final double valorSize = isMobile
        ? (largura * 0.105).clamp(40.0, 56.0).toDouble()
        : 64;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _audioService.unlockCashSound(),
        onPanDown: (_) => _audioService.unlockCashSound(),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 40),
                child: Column(
                  children: [
                    SizedBox(height: isMobile ? 14 : 22),

                    Text(
                      'TORICO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: logoSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    SizedBox(height: isMobile ? 24 : 38),

                    Container(
                      width: cardWidth,
                      constraints: BoxConstraints(
                        minHeight: isMobile ? 150 : 190,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 28,
                        vertical: isMobile ? 18 : 28,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06182C),
                        borderRadius: BorderRadius.circular(isMobile ? 34 : 42),
                        border: Border.all(
                          color: const Color(
                            0xFFF3D77A,
                          ).withValues(alpha: 0.92),
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFFF3D77A,
                            ).withValues(alpha: 0.18),
                            blurRadius: 32,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'VENDIDO HOJE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFE7C35A),
                              letterSpacing: isMobile ? 4.2 : 6,
                              fontSize: isMobile ? 12.5 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: isMobile ? 12 : 24),

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
                            child: FittedBox(
                              key: ValueKey(_salesController.totalSold),
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(
                                  _salesController.totalSold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  color: const Color(0xFFF7D65C),
                                  fontSize: valorSize,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          _SourceBadge(
                            text: connectedPlatforms.length <= 1
                                ? 'Fonte: $_fonteVendas'
                                : 'Todas as plataformas: $_fonteVendas',
                          ),

                          SizedBox(height: isMobile ? 4 : 8),

                          SizedBox(
                            height: 22,
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
                                        offset: Offset(0, -14 * value),
                                        child: Opacity(
                                          opacity: opacity.clamp(0.0, 1.0),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '+ ${CurrencyFormatter.format(_ultimoGanho)}',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 12 : 24),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (_salesController.totalSold == 0) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.insights_rounded,
                                    color: AppColors.gold.withValues(
                                      alpha: 0.65,
                                    ),
                                    size: isMobile ? 42 : 56,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Nenhuma venda registrada hoje.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 17,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Quando a primeira venda entrar, o valor aparece aqui e o TORICO avisa você.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.48,
                                      ),
                                      fontSize: 13.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Center(
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: Image.asset(
                                'assets/images/money_bag.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: isMobile ? 18 : 24),
                  ],
                ),
              ),
            ),

            if (mostrarMoedas) CoinRain(vendaId: vendaId),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String text;

  const _SourceBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
    );
  }
}
