import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/currency_formatter.dart';
import '../services/firestore_sales_service.dart';
import '../widgets/app_snackbar.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final FirestoreSalesService _salesService = FirestoreSalesService();

  static const String allFilter = 'Todas';
  static const int basicSalesLimit = 10;

  static const List<_PlatformFilterOption> platformOptions = [
    _PlatformFilterOption(
      name: allFilter,
      status: 'Todos os canais',
      enabled: true,
    ),
    _PlatformFilterOption(
      name: 'Mercado Pago',
      status: 'Conectado',
      enabled: true,
    ),
    _PlatformFilterOption(name: 'Stone', status: 'Em andamento'),
    _PlatformFilterOption(name: 'PagBank', status: 'Em andamento'),
    _PlatformFilterOption(name: 'Cielo', status: 'Em andamento'),
    _PlatformFilterOption(
      name: 'Rede',
      status: 'Conectado',
      enabled: true,
    ),
    _PlatformFilterOption(name: 'Getnet', status: 'Em andamento'),
    _PlatformFilterOption(name: 'Pagar.me', status: 'Em andamento'),
    _PlatformFilterOption(name: 'Asaas', status: 'Em andamento'),
    _PlatformFilterOption(name: 'InfinitePay', status: 'Em análise'),
  ];

  String selectedFilter = allFilter;

  String? get _selectedPlatform {
    if (selectedFilter == allFilter) {
      return null;
    }

    return selectedFilter;
  }

  double _fallbackTotal(List<ToricoSaleRecord> sales) {
    return sales.fold<double>(0, (sum, sale) => sum + sale.amount);
  }

  Map<String, double> _fallbackTotalsByPlatform(List<ToricoSaleRecord> sales) {
    final totals = <String, double>{};

    for (final sale in sales) {
      totals[sale.platform] = (totals[sale.platform] ?? 0) + sale.amount;
    }

    return totals;
  }

  double _selectedTotalFromSummary(DailySalesSummary summary) {
    if (selectedFilter == allFilter) {
      return summary.totalSold;
    }

    final platformId = _salesService.platformIdFromName(selectedFilter);
    return summary.platforms[platformId]?.totalSold ?? 0.0;
  }

  int _selectedSalesCountFromSummary(DailySalesSummary summary) {
    if (selectedFilter == allFilter) {
      return summary.salesCount;
    }

    final platformId = _salesService.platformIdFromName(selectedFilter);
    return summary.platforms[platformId]?.salesCount ?? 0;
  }

  Map<String, double> _totalsByPlatformFromSummary(DailySalesSummary summary) {
    return {
      for (final platform in summary.platforms.values)
        platform.platform: platform.totalSold,
    };
  }

  Future<void> _showPlatformFilterSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _PlatformFilterSheet(
          selectedFilter: selectedFilter,
          options: platformOptions,
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      selectedFilter = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Histórico',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DailySalesSummary>(
          stream: _salesService.watchTodaySummary(),
          builder: (context, summarySnapshot) {
            final summary =
                summarySnapshot.data ??
                DailySalesSummary.empty(DateTime.now().toIso8601String());

            return StreamBuilder<List<ToricoSaleRecord>>(
              stream: _salesService.watchTodaySales(
                platform: _selectedPlatform,
                limit: basicSalesLimit,
              ),
              builder: (context, salesSnapshot) {
                if ((summarySnapshot.connectionState ==
                            ConnectionState.waiting ||
                        salesSnapshot.connectionState ==
                            ConnectionState.waiting) &&
                    !summarySnapshot.hasData &&
                    !salesSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }

                if (summarySnapshot.hasError || salesSnapshot.hasError) {
                  return const _ErrorState();
                }

                final sales = salesSnapshot.data ?? [];
                final hasSummary =
                    summary.salesCount > 0 || summary.totalSold > 0;

                final total = hasSummary
                    ? _selectedTotalFromSummary(summary)
                    : _fallbackTotal(sales);
                final salesCount = hasSummary
                    ? _selectedSalesCountFromSummary(summary)
                    : sales.length;
                final totalsByPlatform = hasSummary
                    ? _totalsByPlatformFromSummary(summary)
                    : _fallbackTotalsByPlatform(sales);
                final hiddenSalesCount = salesCount > sales.length
                    ? salesCount - sales.length
                    : 0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HistoryPlatformFilters(
                        selectedFilter: selectedFilter,
                        onSelected: (filter) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                        onOpenPlatforms: _showPlatformFilterSheet,
                      ),

                      const SizedBox(height: 8),

                      _SummaryCard(
                        total: total,
                        salesCount: salesCount,
                        platformsCount: totalsByPlatform.length,
                        selectedFilter: selectedFilter,
                      ),

                      const SizedBox(height: 8),

                      const _SectionTitle('Resumo por plataforma'),

                      const SizedBox(height: 8),

                      if (totalsByPlatform.isEmpty)
                        _EmptyCard(
                          icon: Icons.hub_rounded,
                          title: selectedFilter == allFilter
                              ? 'Nenhuma plataforma vendeu hoje ainda'
                              : 'Nenhuma venda em $selectedFilter hoje',
                          text: selectedFilter == allFilter
                              ? 'Assim que uma venda entrar, o resumo por plataforma será atualizado automaticamente.'
                              : 'Quando houver uma venda em $selectedFilter, ela aparecerá neste resumo.',
                        )
                      else
                        ...totalsByPlatform.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PlatformTotalTile(
                              platform: entry.key,
                              total: entry.value,
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      const _SectionTitle('Últimas vendas'),

                      const SizedBox(height: 8),

                      if (sales.isEmpty)
                        _EmptyCard(
                          icon: Icons.receipt_long_rounded,
                          title: selectedFilter == allFilter
                              ? 'Nenhuma venda registrada hoje'
                              : 'Nenhuma venda de $selectedFilter hoje',
                          text: selectedFilter == allFilter
                              ? 'As vendas do dia aparecerão aqui com valor, plataforma e horário.'
                              : 'As vendas dessa plataforma aparecerão aqui com valor e horário.',
                        )
                      else ...[
                        ...sales.map(
                          (sale) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SaleTile(sale: sale),
                          ),
                        ),
                        if (hiddenSalesCount > 0)
                          _PlusHistoryButton(
                            hiddenCount: hiddenSalesCount,
                            onPressed: () {
                              AppSnackBar.show(
                                context,
                                'Histórico completo disponível no TORICO Plus.',
                              );
                            },
                          ),
                      ],

                      const SizedBox(height: 8),

                      const _SectionTitle('Relatórios Plus'),

                      const SizedBox(height: 8),

                      const _PlusReportsSection(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PlatformFilterOption {
  final String name;
  final String status;
  final bool enabled;

  const _PlatformFilterOption({
    required this.name,
    required this.status,
    this.enabled = false,
  });
}

class _HistoryPlatformFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onSelected;
  final VoidCallback onOpenPlatforms;

  const _HistoryPlatformFilters({
    required this.selectedFilter,
    required this.onSelected,
    required this.onOpenPlatforms,
  });

  @override
  Widget build(BuildContext context) {
    final moreSelected =
        selectedFilter != _SalesHistoryScreenState.allFilter &&
        selectedFilter != 'Mercado Pago' &&
        selectedFilter != 'Rede';

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _CompactFilterChip(
            text: 'Todas',
            selected: selectedFilter == _SalesHistoryScreenState.allFilter,
            onTap: () => onSelected(_SalesHistoryScreenState.allFilter),
          ),
          const SizedBox(width: 8),
          _CompactFilterChip(
            text: 'Mercado Pago',
            selected: selectedFilter == 'Mercado Pago',
            onTap: () => onSelected('Mercado Pago'),
          ),
          const SizedBox(width: 8),
          _CompactFilterChip(
            text: 'Rede',
            selected: selectedFilter == 'Rede',
            onTap: () => onSelected('Rede'),
          ),
          const SizedBox(width: 8),
          _CompactFilterChip(
            text: moreSelected ? selectedFilter : 'Plataformas',
            selected: moreSelected,
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: onOpenPlatforms,
          ),
        ],
      ),
    );
  }
}

class _CompactFilterChip extends StatelessWidget {
  final String text;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _CompactFilterChip({
    required this.text,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? AppColors.goldLight.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ??
                  (selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded),
              color: selected ? AppColors.goldLight : Colors.white54,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: selected ? AppColors.goldLight : Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformFilterSheet extends StatelessWidget {
  final String selectedFilter;
  final List<_PlatformFilterOption> options;

  const _PlatformFilterSheet({
    required this.selectedFilter,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Selecionar plataforma',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'O histórico filtra plataformas conectadas. As demais estão em preparação.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = selectedFilter == option.name;

                  return _PlatformFilterTile(
                    option: option,
                    selected: selected,
                    onTap: option.enabled
                        ? () => Navigator.of(context).pop(option.name)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformFilterTile extends StatelessWidget {
  final _PlatformFilterOption option;
  final bool selected;
  final VoidCallback? onTap;

  const _PlatformFilterTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = option.enabled;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.goldLight.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : enabled
                    ? Icons.radio_button_unchecked_rounded
                    : Icons.schedule_rounded,
                color: selected
                    ? AppColors.goldLight
                    : enabled
                    ? Colors.white54
                    : Colors.orangeAccent.withValues(alpha: 0.78),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white70,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _PlatformStatusPill(
                text: option.status,
                enabled: enabled,
                selected: selected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformStatusPill extends StatelessWidget {
  final String text;
  final bool enabled;
  final bool selected;

  const _PlatformStatusPill({
    required this.text,
    required this.enabled,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.goldLight
        : enabled
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;
  final int salesCount;
  final int platformsCount;
  final String selectedFilter;

  const _SummaryCard({
    required this.total,
    required this.salesCount,
    required this.platformsCount,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = salesCount == 1
        ? '1 venda hoje'
        : '$salesCount vendas hoje';

    final sourceText = selectedFilter == _SalesHistoryScreenState.allFilter
        ? 'Todas as plataformas'
        : selectedFilter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.38),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.055),
            blurRadius: 34,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO DE HOJE',
            style: TextStyle(
              color: AppColors.gold,
              letterSpacing: 3,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(total),
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                height: 1,
                letterSpacing: -1.2,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(text: sourceText),
              _Badge(text: subtitle),
              if (selectedFilter == _SalesHistoryScreenState.allFilter)
                _Badge(
                  text: platformsCount == 1
                      ? '1 plataforma'
                      : '$platformsCount plataformas',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformTotalTile extends StatelessWidget {
  final String platform;
  final double total;

  const _PlatformTotalTile({required this.platform, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.11),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.24)),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.goldLight,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              platform,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final ToricoSaleRecord sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final time = sale.createdAt == null
        ? '--:--'
        : '${sale.createdAt!.hour.toString().padLeft(2, '0')}:'
              '${sale.createdAt!.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.greenAccent,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(sale.amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '${sale.platform} • $time',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle_rounded,
            color: Colors.greenAccent,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _PlusHistoryButton extends StatelessWidget {
  final int hiddenCount;
  final VoidCallback onPressed;

  const _PlusHistoryButton({
    required this.hiddenCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final text = hiddenCount == 1
        ? 'Ver mais 1 venda no Plus'
        : 'Ver mais $hiddenCount vendas no Plus';

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          backgroundColor: AppColors.gold.withValues(alpha: 0.06),
          side: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.42)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.workspace_premium_rounded, size: 18),
        label: Text(
          text,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PlusReportsSection extends StatelessWidget {
  const _PlusReportsSection();

  void _showPlusMessage(BuildContext context) {
    AppSnackBar.show(
      context,
      'Este relatório faz parte do TORICO Plus e estará disponível em breve.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LockedPlusTile(
          icon: Icons.calendar_view_week_rounded,
          title: 'Últimos 7 dias',
          text: 'Evolução das vendas da semana.',
          onTap: () => _showPlusMessage(context),
        ),

        const SizedBox(height: 8),

        _LockedPlusTile(
          icon: Icons.calendar_month_rounded,
          title: 'Relatório mensal',
          text: 'Desempenho acumulado do mês.',
          onTap: () => _showPlusMessage(context),
        ),

        const SizedBox(height: 8),

        _LockedPlusTile(
          icon: Icons.compare_arrows_rounded,
          title: 'Comparativos por período',
          text: 'Compare períodos e plataformas.',
          onTap: () => _showPlusMessage(context),
        ),

        const SizedBox(height: 8),

        _LockedPlusTile(
          icon: Icons.bar_chart_rounded,
          title: 'Gráficos de desempenho',
          text: 'Gráficos e tendências das vendas.',
          onTap: () => _showPlusMessage(context),
        ),
      ],
    );
  }
}

class _LockedPlusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  const _LockedPlusTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(icon, color: AppColors.goldLight, size: 19),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                color: AppColors.goldLight,
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Plus',
                                style: TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      text,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold.withValues(alpha: 0.68), size: 32),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Não foi possível carregar o histórico agora.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}
