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
        children: List.generate(isMobile ? 16 : 20, (index) {
          final random = Random(vendaId * 1000 + index);

          final left = random.nextDouble() * (screenWidth + 140) - 70;
          final inicio = -30.0 - random.nextInt(isMobile ? 180 : 260);
          final fim = screenHeight + 100;

          final duracao = isMobile
              ? 8500 + random.nextInt(4500)
              : 22000 + random.nextInt(12000);

          final tamanho = isMobile
              ? 34.0 + random.nextInt(18)
              : 45.0 + random.nextInt(24);

          final atraso = random.nextInt(isMobile ? 900 : 1800);

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
                    sin(value / 55 + index) * (isMobile ? 28 : 45);

                return FutureBuilder(
                  future: Future.delayed(Duration(milliseconds: atraso)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }

                    return Transform.translate(
                      offset: Offset(movimentoLateral, value),
                      child: Transform.rotate(angle: value / 135, child: child),
                    );
                  },
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
