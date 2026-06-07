import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/user_plan_service.dart';
import '../widgets/app_snackbar.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userPlanService = UserPlanService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Meu Plano',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<UserPlan>(
          stream: userPlanService.watchCurrentPlan(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.goldLight),
              );
            }

            if (snapshot.hasError) {
              return const _PlanErrorState();
            }

            final plan = snapshot.data ?? UserPlan.basic();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CurrentPlanCard(plan: plan),

                  const SizedBox(height: 22),

                  _SectionTitle(
                    plan.isPlus
                        ? 'Recursos disponíveis no seu plano'
                        : 'Incluído no Plano Básico',
                  ),

                  const SizedBox(height: 12),

                  const _FeatureTile(
                    icon: Icons.today_rounded,
                    title: 'Vendido hoje em tempo real',
                    text: 'Acompanhe o total vendido no dia atual.',
                  ),

                  const SizedBox(height: 10),

                  const _FeatureTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Histórico das vendas de hoje',
                    text:
                        'Veja as vendas registradas no dia, com valor e horário.',
                  ),

                  const SizedBox(height: 10),

                  const _FeatureTile(
                    icon: Icons.filter_alt_rounded,
                    title: 'Filtro por plataforma',
                    text: 'Filtre vendas por Mercado Pago, Stone ou PagBank.',
                  ),

                  const SizedBox(height: 10),

                  const _FeatureTile(
                    icon: Icons.hub_rounded,
                    title: 'Múltiplas plataformas',
                    text:
                        'Conecte mais de uma fonte de vendas ao mesmo negócio.',
                  ),

                  const SizedBox(height: 10),

                  const _FeatureTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Alertas visuais e sonoros',
                    text: 'Receba sinais quando uma nova venda entrar.',
                  ),

                  const SizedBox(height: 26),

                  _PlusCard(plan: plan),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        AppSnackBar.show(
                          context,
                          plan.isPlus
                              ? 'Você já está no TORICO Plus.'
                              : 'O TORICO Plus estará disponível em breve.',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        elevation: 8,
                        shadowColor: AppColors.gold.withOpacity(0.30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        plan.isPlus
                            ? 'Plano Plus ativo'
                            : 'Conhecer o TORICO Plus',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'Básico = tempo real do dia atual • Plus = relatórios e análise histórica',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.42),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final UserPlan plan;

  const _CurrentPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final bool isPlus = plan.isPlus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gold.withOpacity(0.46), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(color: AppColors.gold.withOpacity(0.055), blurRadius: 34),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLANO ATUAL',
            style: TextStyle(
              color: AppColors.gold,
              letterSpacing: 3,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.13),
                  border: Border.all(color: AppColors.gold.withOpacity(0.28)),
                ),
                child: Icon(
                  isPlus
                      ? Icons.diamond_rounded
                      : Icons.workspace_premium_rounded,
                  color: AppColors.goldLight,
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isPlus
                          ? 'Relatórios, comparativos e análise histórica.'
                          : 'Focado no acompanhamento do dia atual.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const _PlanBadge(text: 'Tempo real'),
          const SizedBox(height: 8),
          const _PlanBadge(text: 'Histórico de hoje'),
          const SizedBox(height: 8),
          const _PlanBadge(text: 'Múltiplas plataformas'),

          if (isPlus) ...[
            const SizedBox(height: 8),
            const _PlanBadge(text: 'Relatórios avançados'),
          ],
        ],
      ),
    );
  }
}

class _PlusCard extends StatelessWidget {
  final UserPlan plan;

  const _PlusCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final bool isPlus = plan.isPlus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withOpacity(0.18),
            Colors.white.withOpacity(0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold.withOpacity(0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPlus ? 'TORICO Plus ativo' : 'TORICO Plus',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isPlus
                ? 'Você já tem acesso aos recursos avançados quando eles forem liberados no app.'
                : 'Para quem quer analisar desempenho e tomar decisões com histórico.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 18),

          const _PlusFeature(text: 'Relatórios dos últimos 7 dias'),
          const _PlusFeature(text: 'Relatórios mensais'),
          const _PlusFeature(text: 'Comparativos por período'),
          const _PlusFeature(text: 'Gráficos de desempenho'),
          const _PlusFeature(text: 'Exportação de dados'),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.12),
            ),
            child: Icon(icon, color: AppColors.goldLight, size: 24),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 13.5,
                    height: 1.3,
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

class _PlusFeature extends StatelessWidget {
  final String text;

  const _PlusFeature({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.goldLight, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String text;

  const _PlanBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.gold.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.76),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.goldLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PlanErrorState extends StatelessWidget {
  const _PlanErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Não foi possível carregar o plano agora.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 16),
        ),
      ),
    );
  }
}
