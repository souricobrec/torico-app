import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/local_storage_service.dart';
import 'main_navigation_screen.dart';

class ConnectedScreen extends StatefulWidget {
  final String plataforma;

  const ConnectedScreen({super.key, required this.plataforma});

  @override
  State<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends State<ConnectedScreen> {
  final LocalStorageService _storage = LocalStorageService();

  List<String> connectedPlatforms = [];

  @override
  void initState() {
    super.initState();
    _loadConnectedPlatforms();
  }

  Future<void> _loadConnectedPlatforms() async {
    final platforms = await _storage.getConnectedPlatforms();

    if (!mounted) return;

    setState(() {
      connectedPlatforms = platforms;
    });
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    final totalPlatforms = connectedPlatforms.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24 : 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: isMobile ? 112 : 140,
                    height: isMobile ? 112 : 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent.withOpacity(0.10),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.18),
                          blurRadius: 34,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      size: 82,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Plataforma conectada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 32 : 42,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '${widget.plataforma} foi adicionada ao seu negócio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: isMobile ? 17 : 20,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.045),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hub_rounded,
                          color: AppColors.goldLight,
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            totalPlatforms <= 1
                                ? '1 plataforma conectada'
                                : '$totalPlatforms plataformas conectadas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 46),

                  SizedBox(
                    width: double.infinity,
                    height: isMobile ? 60 : 72,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        elevation: 10,
                        shadowColor: AppColors.gold.withOpacity(0.30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MainNavigationScreen(plataforma: widget.plataforma),
                          ),
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
        ),
      ),
    );
  }
}
