import 'dart:math';
import 'package:flutter/material.dart';

class CoinRain extends StatelessWidget {
  final int vendaId;

  const CoinRain({super.key, required this.vendaId});

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;
    final screenWidth = tamanhoTela.width;
    final screenHeight = tamanhoTela.height;
    final bool isMobile = screenWidth < 600;

    return IgnorePointer(
      child: Stack(
        key: ValueKey(vendaId),
        children: List.generate(isMobile ? 18 : 20, (index) {
          final random = Random(vendaId * 1000 + index);

          final left = random.nextDouble() * (screenWidth + 120) - 60;

          final inicio = isMobile
              ? -40.0 - random.nextInt(220)
              : -40.0 - random.nextInt(300);

          final fim = screenHeight + 120;

          final duracao = isMobile
              ? 5200 + random.nextInt(2600)
              : 14000 + random.nextInt(7000);

          final tamanho = isMobile
              ? 34.0 + random.nextInt(18)
              : 45.0 + random.nextInt(24);

          final deslocamentoHorizontal = isMobile ? 26.0 : 45.0;
          final velocidadeGiro = isMobile ? 105.0 : 145.0;

          return Positioned(
            left: left,
            top: 0,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$vendaId-$index'),
              duration: Duration(milliseconds: duracao),
              tween: Tween(begin: inicio, end: fim),
              curve: Curves.linear,
              builder: (context, value, child) {
                final movimentoLateral =
                    sin(value / 55 + index) * deslocamentoHorizontal;

                return Transform.translate(
                  offset: Offset(movimentoLateral, value),
                  child: Transform.rotate(
                    angle: value / velocidadeGiro,
                    child: child,
                  ),
                );
              },
              child: Image.asset('assets/images/coin.png', width: tamanho),
            ),
          );
        }),
      ),
    );
  }
}
