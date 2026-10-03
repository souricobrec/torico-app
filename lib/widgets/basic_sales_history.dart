import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/currency_formatter.dart';
import '../services/firestore_sales_service.dart';

class BasicSalesHistory extends StatefulWidget {
  final Stream<List<ToricoSaleRecord>> Function() salesLoader;
  final VoidCallback onViewPlans;
  const BasicSalesHistory({
    super.key,
    required this.salesLoader,
    required this.onViewPlans,
  });

  static List<ToricoSaleRecord> preview(List<ToricoSaleRecord> records) {
    final sorted = records.where((sale) => sale.status == 'approved').toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
    return sorted.take(10).toList();
  }

  @override
  State<BasicSalesHistory> createState() => _BasicSalesHistoryState();
}

class _BasicSalesHistoryState extends State<BasicSalesHistory> {
  late final stream = widget.salesLoader();
  String shortDate(DateTime? date) {
    if (date == null) return 'Data indisponível';
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(date.day)}/${pad(date.month)}/${date.year} ${pad(date.hour)}:${pad(date.minute)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      title: const Text('Histórico'),
    ),
    body: StreamBuilder<List<ToricoSaleRecord>>(
      stream: stream,
      builder: (context, snapshot) {
        final sales = BasicSalesHistory.preview(snapshot.data ?? []);
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Plano Básico: exibindo apenas as últimas 10 vendas.',
              style: TextStyle(color: AppColors.gold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recurso disponível no TORICO Plus.'),
                ),
              ),
              icon: const Icon(Icons.lock_outline, color: AppColors.gold),
              label: const Text(
                'Filtros por data e período · Plus',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
            if (snapshot.hasError)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Não foi possível carregar as vendas. Tente novamente.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else if (!snapshot.hasData)
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            else if (sales.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nenhuma venda registrada.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              for (final sale in sales)
                Card(
                  color: const Color(0xFF06182C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.gold.withValues(alpha: .25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(sale.amount),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sale.platform == 'Rede' ? 'REDE' : sale.platform,
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${shortDate(sale.createdAt)} · Aprovado',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            const Text(
              'Quer consultar períodos, filtros e relatórios completos? Conheça o TORICO Plus.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.onViewPlans,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Ver planos'),
            ),
          ],
        );
      },
    ),
  );
}
