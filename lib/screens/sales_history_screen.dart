import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/currency_formatter.dart';
import '../services/firestore_sales_service.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final FirestoreSalesService _salesService = FirestoreSalesService();

  static const String allFilter = 'Todas';

  final List<String> filters = const [
    allFilter,
    'Mercado Pago',
    'Stone',
    'PagBank',
  ];

  String selectedFilter = allFilter;

  List<ToricoSaleRecord> _filteredSales(List<ToricoSaleRecord> sales) {
    if (selectedFilter == allFilter) {
      return sales;
    }

    return sales.where((sale) => sale.platform == selectedFilter).toList();
  }

  Map<String, double> _totalsByPlatform(List<ToricoSaleRecord> sales) {
    final totals = <String, double>{};

    for (final sale in sales) {
      totals[sale.platform] = (totals[sale.platform] ?? 0) + sale.amount;
    }

    return totals;
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
        child: StreamBuilder<List<ToricoSaleRecord>>(
          stream: _salesService.watchTodaySales(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }

            if (snapshot.hasError) {
              return const _ErrorState();
            }

            final allSales = snapshot.data ?? [];
            final sales = _filteredSales(allSales);

            final total = sales.fold<double>(
              0,
              (sum, sale) => sum + sale.amount,
            );

            final totalsByPlatform = _totalsByPlatform(sales);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterChips(
                    filters: filters,
                    selectedFilter: selectedFilter,
                    onSelected: (filter) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  _SummaryCard(
                    total: total,
                    salesCount: sales.length,
                    platformsCount: totalsByPlatform.length,
                    selectedFilter: selectedFilter,
                  ),

                  const SizedBox(height: 22),

                  const _SectionTitle('Resumo por plataforma'),

                  const SizedBox(height: 12),

                  if (totalsByPlatform.isEmpty)
                    _EmptyCard(
                      icon: Icons.hub_rounded,
                      title: selectedFilter == allFilter
                          ? 'Nenhuma plataforma com venda hoje'
                          : 'Nenhuma venda em $selectedFilter hoje',
                      text: selectedFilter == allFilter
                          ? 'As vendas simuladas aparecerão aqui separadas por plataforma.'
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

                  const SizedBox(height: 16),

                  const _SectionTitle('Últimas vendas'),

                  const SizedBox(height: 12),

                  if (sales.isEmpty)
                    _EmptyCard(
                      icon: Icons.receipt_long_rounded,
                      title: selectedFilter == allFilter
                          ? 'Nenhuma venda registrada hoje'
                          : 'Nenhuma venda de $selectedFilter hoje',
                      text: selectedFilter == allFilter
                          ? 'Quando uma venda entrar, ela será exibida aqui com valor, plataforma e horário.'
                          : 'As vendas dessa plataforma aparecerão aqui com valor e horário.',
                    )
                  else
                    ...sales.map(
                      (sale) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SaleTile(sale: sale),
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

class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const _FilterChips({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == selectedFilter;

          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.gold.withOpacity(0.22)
                    : Colors.white.withOpacity(0.045),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected
                      ? AppColors.goldLight.withOpacity(0.65)
                      : Colors.white.withOpacity(0.12),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppColors.goldLight : Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    filter,
                    style: TextStyle(
                      color: selected ? AppColors.goldLight : Colors.white70,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gold.withOpacity(0.38), width: 1.4),
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
            'RESUMO DE HOJE',
            style: TextStyle(
              color: AppColors.gold,
              letterSpacing: 3,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(total),
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                height: 1,
                letterSpacing: -1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.11),
              border: Border.all(color: AppColors.gold.withOpacity(0.24)),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.goldLight,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              platform,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 17,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent.withOpacity(0.10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.greenAccent,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(sale.amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${sale.platform} • $time',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13.5,
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

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

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
          color: Colors.white.withOpacity(0.72),
          fontSize: 12.5,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold.withOpacity(0.68), size: 42),

          const SizedBox(height: 14),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 14,
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
          style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 16),
        ),
      ),
    );
  }
}
