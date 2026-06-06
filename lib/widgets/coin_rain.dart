import 'dart:math';
import 'package:flutter/material.dart';

class CoinRain extends StatelessWidget {
  final int vendaId;

  const CoinRain({super.key, required this.vendaId});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        key: ValueKey(vendaId),
        children: List.generate(18, (index) {
          final random = Random(vendaId * 1000 + index);
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          final left = random.nextDouble() * (screenWidth + 160) - 80;
          final inicio = -20.0 - random.nextInt(260);
          final fim = screenHeight + 120;

          final duracao = 28000 + random.nextInt(15000);
          final tamanho = 45.0 + random.nextInt(24);

          return Positioned(
            left: left,
            top: 0,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$vendaId-$index'),
              duration: Duration(milliseconds: duracao),
              tween: Tween(begin: inicio, end: fim),
              builder: (context, value, child) {
                final movimentoLateral = sin(value / 55 + index) * 45;

                return Transform.translate(
                  offset: Offset(movimentoLateral, value),
                  child: Transform.rotate(angle: value / 160, child: child),
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
