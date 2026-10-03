import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/user_plan_service.dart';
import 'painel_screen.dart';
import 'plan_screen.dart';
import 'sales_history_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String plataforma;
  final Stream<UserPlan>? planStream;
  final Widget Function(BuildContext, String)? pageBuilder;
  const MainNavigationScreen({
    super.key,
    required this.plataforma,
    this.planStream,
    this.pageBuilder,
  });
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String selectedTab = 'Painel';
  final Map<String, Widget> loadedPages = {};
  late final Stream<UserPlan> plans =
      widget.planStream ?? UserPlanService().watchPlanReadOnly();
  Widget page(String tab) {
    if (widget.pageBuilder != null) return widget.pageBuilder!(context, tab);
    return switch (tab) {
      'Histórico' => SalesHistoryScreen(planStream: plans),
      'Plano' => const PlanScreen(),
      'Conta' => SettingsScreen(plataforma: widget.plataforma),
      _ => PainelScreen(plataforma: widget.plataforma),
    };
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<UserPlan>(
    stream: plans,
    builder: (context, snapshot) {
      final plus = !snapshot.hasError && snapshot.data?.isPlus == true;
      final tabs = ['Painel', if (plus) 'Histórico', 'Plano', 'Conta'];
      if (!tabs.contains(selectedTab)) selectedTab = 'Painel';
      if (!plus) loadedPages.remove('Histórico');
      loadedPages.putIfAbsent(selectedTab, () => page(selectedTab));
      const icons = {
        'Painel': Icons.dashboard_rounded,
        'Histórico': Icons.receipt_long_rounded,
        'Plano': Icons.workspace_premium_rounded,
        'Conta': Icons.settings_rounded,
      };
      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: tabs.indexOf(selectedTab),
          children: [
            for (final tab in tabs)
              KeyedSubtree(
                key: ValueKey(tab),
                child: loadedPages[tab] ?? const SizedBox.shrink(),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF06182C),
            border: Border(
              top: BorderSide(color: AppColors.gold.withValues(alpha: .18)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .30),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: tabs.indexOf(selectedTab),
              onTap: (index) => setState(() => selectedTab = tabs[index]),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.goldLight,
              unselectedItemColor: Colors.white54,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11.6,
              ),
              items: tabs
                  .map(
                    (tab) => BottomNavigationBarItem(
                      icon: Icon(icons[tab]),
                      label: tab,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    },
  );
}
