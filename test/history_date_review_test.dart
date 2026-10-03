import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/core/active_sales_sources.dart';
import 'package:torico/screens/sales_history_screen.dart';
import 'package:torico/services/firestore_sales_service.dart';

void main() {
  test('inactive integrations ignore stale connection flags', () {
    expect(
      ActiveSalesSources.integrationStatus('Mercado Pago', connected: true),
      'Conectado',
    );
    expect(
      ActiveSalesSources.integrationStatus('Rede', connected: true),
      'Pausada',
    );
    for (final name in [
      'Stone',
      'PagBank',
      'Cielo',
      'Getnet',
      'Pagar.me',
      'Asaas',
      'InfinitePay',
    ]) {
      expect(
        ActiveSalesSources.integrationStatus(name, connected: true),
        'Em preparação',
      );
      expect(ActiveSalesSources.isActive(name), false);
    }
  });

  testWidgets('zero today does not hide yesterday Mercado Pago sale', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final requested = <DateTime>[];
    final previousSale = ToricoSaleRecord(
      id: 'existing-sale',
      amount: 1,
      platform: 'Mercado Pago',
      platformId: 'mercado_pago',
      status: 'approved',
      source: 'mercado_pago',
      dateKey: yesterday.toIso8601String().substring(0, 10),
      externalId: null,
      rawPayload: null,
      createdAt: yesterday.add(const Duration(hours: 15)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SalesHistoryScreen(
          initialDate: today,
          summaryLoader: (date) =>
              Stream.value(DailySalesSummary.empty(date.toIso8601String())),
          salesLoader: (date, platform) {
            requested.add(date);
            return Stream.value(
              date == yesterday &&
                      (platform == null || platform == 'Mercado Pago')
                  ? [previousSale]
                  : [],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('0,00'), findsWidgets);
    expect(find.textContaining('1,00'), findsNothing);
    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(requested.last, yesterday);
    expect(find.textContaining('1,00'), findsWidgets);
    await tester.tap(find.text('Mercado Pago').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('1,00'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Próximo dia'));
    await tester.pumpAndSettle();
    expect(requested.last, today);
    expect(find.textContaining('1,00'), findsNothing);
    expect(previousSale.amount, 1);
  });
}
