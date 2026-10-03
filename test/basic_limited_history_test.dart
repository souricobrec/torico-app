import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/widgets/basic_sales_history.dart';
import 'package:torico/services/firestore_sales_service.dart';

ToricoSaleRecord sale(int day, {String status = 'approved'}) =>
    ToricoSaleRecord(
      id: '$day',
      amount: day.toDouble(),
      platform: 'Mercado Pago',
      platformId: 'mercado_pago',
      status: status,
      source: 'webhook',
      dateKey: '2026-09-$day',
      externalId: '$day',
      rawPayload: null,
      createdAt: DateTime(2026, 9, day, 12, 30),
    );
void main() {
  test('preview caps at ten, orders descending and excludes non approved', () {
    final preview = BasicSalesHistory.preview([
      for (var day = 1; day <= 15; day++) sale(day),
      sale(16, status: 'rejected'),
    ]);
    expect(preview.length, 10);
    expect(preview.map((sale) => sale.id), [
      '15',
      '14',
      '13',
      '12',
      '11',
      '10',
      '9',
      '8',
      '7',
      '6',
    ]);
  });
  testWidgets(
    'basic preview shows limit, approved details, Plus block and CTA at 320px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var plans = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BasicSalesHistory(
            salesLoader: () => Stream.value([sale(15)]),
            onViewPlans: () {
              plans++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Plano Básico: exibindo apenas as últimas 10 vendas.'),
        findsOneWidget,
      );
      expect(find.text('Mercado Pago'), findsOneWidget);
      expect(find.text('15/09/2026 12:30 · Aprovado'), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      await tester.tap(find.text('Filtros por data e período · Plus'));
      await tester.pumpAndSettle();
      expect(find.text('Recurso disponível no TORICO Plus.'), findsOneWidget);
      await tester.ensureVisible(find.text('Ver planos'));
      await tester.tap(find.text('Ver planos'));
      await tester.pump();
      expect(plans, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
