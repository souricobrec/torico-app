import 'package:flutter/material.dart';
import 'connected_screen.dart';

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
