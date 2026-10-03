import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/core/active_sales_sources.dart';
import 'package:torico/screens/settings_screen.dart';
import 'package:torico/screens/sales_history_screen.dart';

void main() {
  testWidgets(
    'history keeps Mercado Pago selectable and paused REDE disabled',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryPlatformFilters(
              selectedFilter: 'Todas',
              onSelected: (value) => selected = value,
              onOpenPlatforms: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('REDE · Pausada'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.tap(find.text('Mercado Pago'));
      expect(selected, 'Mercado Pago');
    },
  );
  test(
    'paused and future sources never count as monitored, including stale local connections',
    () {
      const cached = ['Mercado Pago', 'Rede', 'Stone'];
      expect(ActiveSalesSources.connected(cached), ['Mercado Pago']);
      expect(
        ActiveSalesSources.panelLabel(cached),
        'Plataforma ativa: Mercado Pago',
      );
      expect(
        ActiveSalesSources.status(cached),
        'Monitorando 1 fonte de venda: Mercado Pago',
      );
      expect(ActiveSalesSources.connected(['Rede']), isEmpty);
      expect(
        ActiveSalesSources.panelLabel(['Rede']),
        'Nenhuma plataforma ativa',
      );
      expect(ActiveSalesSources.connected([]), isEmpty);
    },
  );

  testWidgets('account lists Mercado Pago as connected and REDE as paused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          plataforma: 'Mercado Pago',
          platformLoader: () async => ['Mercado Pago', 'Rede'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Monitorando 1 fonte de venda: Mercado Pago'),
      findsOneWidget,
    );
    expect(find.text('Monitorando 2 fontes de venda'), findsNothing);
    final connections = find.byKey(const ValueKey('connected-sources'));
    expect(
      find.descendant(of: connections, matching: find.text('Mercado Pago')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: connections, matching: find.text('Rede')),
      findsNothing,
    );
    expect(find.text('Pausada'), findsOneWidget);
    expect(
      find.text('Integração pausada. Não está sendo monitorada.'),
      findsOneWidget,
    );
    expect(find.text('Em andamento'), findsNothing);
    expect(find.text('Em análise'), findsNothing);
    expect(find.text('Em preparação'), findsNWidgets(7));
    expect(find.text('Sair da conta'), findsOneWidget);
  });
}
