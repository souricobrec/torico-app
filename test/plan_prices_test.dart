import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torico/screens/plan_screen.dart';
import 'package:torico/services/user_plan_service.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('Preços oficiais e Plus sem contratação em $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PlanScreen(planStream: Stream.value(UserPlan.basic())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('R\$ 24,90', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('R\$ 39,90'), findsOneWidget);
      expect(
        find.textContaining('não comprova assinatura paga'),
        findsOneWidget,
      );
      expect(find.text('Em breve'), findsOneWidget);
      await tester.ensureVisible(find.text('Conhecer TORICO Plus'));
      await tester.tap(find.text('Conhecer TORICO Plus'));
      await tester.pump();
      expect(find.textContaining('estará disponível em breve'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
