import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/integration_service.dart';
import 'connected_screen.dart';

class AuthScreen extends StatefulWidget {
  final String plataforma;

  const AuthScreen({super.key, required this.plataforma});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final IntegrationService _integrationService = IntegrationService();

  bool carregando = false;

  Future<void> conectar() async {
    setState(() {
      carregando = true;
    });

    final conectado = await _integrationService.connect(widget.plataforma);

    if (conectado && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConnectedScreen(plataforma: widget.plataforma),
        ),
      );
    }

    if (mounted) {
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.gold, size: 70),

              const SizedBox(height: 30),

              Text(
                widget.plataforma,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: largura < 600 ? 34 : 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                carregando
                    ? 'Conectando com ${widget.plataforma}...'
                    : 'Aguardando autorização...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: largura < 600 ? 60 : 75,
                child: ElevatedButton(
                  onPressed: carregando ? null : conectar,
                  child: carregando
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
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
