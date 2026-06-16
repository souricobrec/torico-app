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
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('PLANO ATUAL', small: true),

                  const SizedBox(height: 10),

                  _CurrentPlanCompact(plan: plan),

                  const SizedBox(height: 18),

                  const _SectionTitle('RECURSOS INCLUÍDOS NO BÁSICO'),

                  const SizedBox(height: 10),

                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _FeatureChip(
                        icon: Icons.schedule_rounded,
                        text: 'Tempo real',
                      ),
                      _FeatureChip(
                        icon: Icons.receipt_long_rounded,
                        text: 'Histórico de hoje',
                      ),
                      _FeatureChip(
                        icon: Icons.filter_alt_rounded,
                        text: 'Filtro por plataforma',
                      ),
                      _FeatureChip(
                        icon: Icons.layers_rounded,
                        text: 'Múltiplas plataformas',
                      ),
                      _FeatureChip(
                        icon: Icons.notifications_active_rounded,
                        text: 'Alertas de venda',
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle('TORICO PLUS'),

                  const SizedBox(height: 10),

                  _PlusCompactCard(plan: plan),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        AppSnackBar.show(
                          context,
                          plan.isPlus
                              ? 'Você já está no TORICO Plus.'
                              : 'O TORICO Plus estará disponível em breve com relatórios e análises avançadas.',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldLight,
                        foregroundColor: Colors.black,
                        elevation: 10,
                        shadowColor: AppColors.gold.withValues(alpha: 0.30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            plan.isPlus
                                ? Icons.check_circle_rounded
                                : Icons.workspace_premium_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            plan.isPlus
                                ? 'Plano Plus ativo'
                                : 'Conhecer TORICO Plus',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!plan.isPlus) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ],
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

class _CurrentPlanCompact extends StatelessWidget {
  final UserPlan plan;

  const _CurrentPlanCompact({required this.plan});

  @override
  Widget build(BuildContext context) {
    final bool isPlus = plan.isPlus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.46),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.055),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  isPlus
                      ? Icons.diamond_rounded
                      : Icons.workspace_premium_rounded,
                  color: AppColors.goldLight,
                  size: 31,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              height: 1.08,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _StatusPill(text: 'Ativo'),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isPlus
                          ? 'Relatórios, comparativos e análise histórica.'
                          : 'Acompanhamento em tempo real do dia atual.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13.5,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),

          const SizedBox(height: 14),

          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isPlus ? 'Plus' : 'R\$ 39,90',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isPlus)
                      TextSpan(
                        text: ' / mês',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Plano atual',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.goldLight, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusCompactCard extends StatelessWidget {
  final UserPlan plan;

  const _PlusCompactCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final bool isPlus = plan.isPlus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  isPlus
                      ? Icons.check_circle_rounded
                      : Icons.workspace_premium_rounded,
                  color: AppColors.goldLight,
                  size: 31,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isPlus ? 'TORICO Plus ativo' : 'TORICO Plus',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.08,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(text: isPlus ? 'Ativo' : 'Em breve'),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isPlus
                          ? 'Recursos avançados habilitados no app.'
                          : 'Relatórios avançados, comparativos e gráficos de desempenho.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13.5,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),

          const SizedBox(height: 12),

          const Row(
            children: [
              Expanded(
                child: _PlusMiniFeature(
                  icon: Icons.bar_chart_rounded,
                  text: 'Relatórios Plus',
                ),
              ),
              Expanded(
                child: _PlusMiniFeature(
                  icon: Icons.compare_arrows_rounded,
                  text: 'Comparativos',
                ),
              ),
              Expanded(
                child: _PlusMiniFeature(
                  icon: Icons.pie_chart_rounded,
                  text: 'Gráficos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlusMiniFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PlusMiniFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.goldLight, size: 16),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final bool active = text == 'Ativo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? Colors.greenAccent.withValues(alpha: 0.12)
            : AppColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: active
              ? Colors.greenAccent.withValues(alpha: 0.28)
              : AppColors.gold.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.greenAccent : AppColors.goldLight,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool small;

  const _SectionTitle(this.text, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.goldLight,
        fontSize: small ? 13 : 16,
        fontWeight: FontWeight.bold,
        letterSpacing: small ? 3 : 1.8,
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
