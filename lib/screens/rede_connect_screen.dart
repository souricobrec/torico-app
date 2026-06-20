import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class RedeConnectScreen extends StatefulWidget {
  const RedeConnectScreen({super.key});

  @override
  State<RedeConnectScreen> createState() => _RedeConnectScreenState();
}

class _RedeConnectScreenState extends State<RedeConnectScreen> {
  bool solicitando = false;
  bool solicitado = false;

  Future<void> _solicitarAtivacao() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Entre na sua conta para solicitar a ativação da Rede.');
      return;
    }

    setState(() {
      solicitando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('integration_requests')
          .doc('rede')
          .set({
        'platform': 'Rede',
        'platformId': 'rede',
        'status': 'requested',
        'source': 'app',
        'requestType': 'assisted_activation',
        'message': 'Usuário solicitou ativação assistida da integração Rede.',
        'requestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        solicitado = true;
      });

      _showMessage('Solicitação de ativação da Rede registrada.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível registrar a solicitação agora.');
    } finally {
      if (mounted) {
        setState(() {
          solicitando = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF06182C),
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        title: const Text(
          'Conectar Rede',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 18 : 40,
            isMobile ? 10 : 34,
            isMobile ? 18 : 40,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(isMobile: isMobile),
                  const SizedBox(height: 16),
                  const _InfoCard(
                    icon: Icons.verified_user_rounded,
                    title: 'Ativação assistida',
                    text:
                        'A integração com a Rede é feita por API no backend do TORICO. Neste momento, a ativação não usa login ou senha da Rede dentro do app.',
                  ),
                  const SizedBox(height: 10),
                  const _InfoCard(
                    icon: Icons.lock_outline_rounded,
                    title: 'Segurança',
                    text:
                        'O TORICO não solicita senha da Rede e não expõe credenciais no aplicativo. A validação da integração é feita de forma controlada no backend.',
                  ),
                  const SizedBox(height: 10),
                  const _InfoCard(
                    icon: Icons.manage_search_rounded,
                    title: 'Próximo passo',
                    text:
                        'Solicite a ativação para que a integração seja analisada e configurada. Quando estiver pronta, a Rede aparecerá como conectada no painel.',
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: solicitando ? null : _solicitarAtivacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: solicitado
                            ? Colors.greenAccent.withValues(alpha: 0.16)
                            : AppColors.gold,
                        foregroundColor: solicitado ? Colors.greenAccent : Colors.black,
                        elevation: solicitado ? 0 : 10,
                        shadowColor: AppColors.gold.withValues(alpha: 0.22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: solicitando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Icon(
                              solicitado
                                  ? Icons.check_circle_rounded
                                  : Icons.assignment_turned_in_rounded,
                            ),
                      label: Text(
                        solicitado
                            ? 'Solicitação registrada'
                            : 'Solicitar ativação da Rede',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Se a Rede liberar um fluxo oficial de autorização do lojista, esta tela será atualizada para abrir a autorização diretamente na Rede.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 12.5,
                      height: 1.35,
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

class _HeaderCard extends StatelessWidget {
  final bool isMobile;

  const _HeaderCard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.38),
          width: 1.3,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 48 : 58,
            height: isMobile ? 48 : 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
            ),
            child: const Icon(
              Icons.credit_score_rounded,
              color: AppColors.goldLight,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rede',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Integração por ativação assistida, usando a API Gestão de Vendas no backend.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: isMobile ? 13.5 : 15.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
