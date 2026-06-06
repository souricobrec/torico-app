import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const ToricoApp());
}

class ToricoApp extends StatelessWidget {
  const ToricoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TORICO',
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF031226),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/torico_logo.png',
                width: largura < 600 ? largura * 0.75 : 420,
              ),

              const SizedBox(height: 25),

              const Text(
                'Seu negócio vendendo. Onde você estiver.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),

              const SizedBox(height: 60),

              _platformButton(context, 'Mercado Pago', Colors.lightBlue),

              const SizedBox(height: 15),

              _platformButton(context, 'Stone', Colors.green),

              const SizedBox(height: 15),

              _platformButton(context, 'PagBank', Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _platformButton(BuildContext context, String plataforma, Color color) {
    final largura = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      height: largura < 600 ? 60 : 75,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuthScreen(plataforma: plataforma),
            ),
          );
        },
        child: Text(
          plataforma,
          style: TextStyle(
            fontSize: largura < 600 ? 22 : 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  final String plataforma;

  const AuthScreen({super.key, required this.plataforma});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF031226),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFFD4AF37),
                size: 70,
              ),

              const SizedBox(height: 30),

              Text(
                plataforma,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: largura < 600 ? 34 : 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Aguardando autorização...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 20),
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: largura < 600 ? 60 : 75,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConnectedScreen(plataforma: plataforma),
                      ),
                    );
                  },
                  child: const Text(
                    'Simular Conexão',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectedScreen extends StatelessWidget {
  final String plataforma;

  const ConnectedScreen({super.key, required this.plataforma});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF031226),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),

              const SizedBox(height: 25),

              Text(
                'Conectado com sucesso',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: largura < 600 ? 32 : 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '$plataforma conectado',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: largura < 600 ? 60 : 75,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PainelScreen()),
                    );
                  },
                  child: const Text(
                    'Entrar no Painel',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  double totalVendido = 5348.00;

  bool mostrarMoedas = false;
  bool mostrarGanho = false;

  int vendaId = 0;

  void novaVenda() {
    vendaId++;

    setState(() {
      totalVendido += 10.00;
      mostrarMoedas = true;
      mostrarGanho = true;
    });

    final vendaAtual = vendaId;

    Future.delayed(const Duration(seconds: 35), () {
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
      const SnackBar(content: Text('Nova venda recebida! + R\$ 10,00')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final altura = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF031226),
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
                    color: Color(0xFFD4AF37),
                    letterSpacing: 3,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 40,
                  child: mostrarGanho
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey(vendaId),
                          duration: const Duration(seconds: 15),
                          tween: Tween(begin: 0, end: 1),
                          builder: (context, value, child) {
                            final opacity = value < 0.75
                                ? 1.0
                                : 1.0 - ((value - 0.75) / 0.25);

                            return Transform.translate(
                              offset: Offset(0, -20 * value),
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: const Text(
                            '+ R\$ 10,00',
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
                      color: const Color(0xFFFFD54F),
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

          if (mostrarMoedas)
            IgnorePointer(
              child: Stack(
                key: ValueKey(vendaId),
                children: List.generate(28, (index) {
                  final random = Random(vendaId * 1000 + index);
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;

                  final left = random.nextDouble() * (screenWidth + 160) - 80;

                  final inicio = -20.0 - random.nextInt(260);
                  final fim = screenHeight + 120;

                  final duracao = 29000 + random.nextInt(25000);
                  final tamanho = 38.0 + random.nextInt(24);

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
                          child: Transform.rotate(
                            angle: value / 160,
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/coin.png',
                        width: tamanho,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
