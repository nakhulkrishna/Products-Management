import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/core/constants/app_colors.dart';
import 'package:products_catelogs/features/dashboard/presentation/pages/dashboard_tab_page.dart';
import 'package:products_catelogs/features/orders/presentation/pages/orders_tab_page.dart';
import 'package:products_catelogs/features/products/presentation/pages/products_tab_page.dart';
import 'package:products_catelogs/features/settings/presentation/pages/settings_tab_page.dart';
import 'package:products_catelogs/features/staff/presentation/pages/staffs_tab_page.dart';
import 'package:products_catelogs/features/shell/application/sidebar_tab_provider.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';
import 'package:products_catelogs/features/shell/presentation/widgets/web_sidebar.dart';

class WebShellPage extends ConsumerStatefulWidget {
  const WebShellPage({super.key});

  @override
  ConsumerState<WebShellPage> createState() => _WebShellPageState();
}

class _WebShellPageState extends ConsumerState<WebShellPage> {
  static final _tabBuilders = <Widget Function()>[
    () => const DashboardTabPage(),
    () => const ProductsTabPage(),
    () => const OrdersTabPage(),
    () => const StaffsTabPage(),
    () => const SettingsTabPage(),
  ];

  late final List<bool> _loaded;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _loaded = List<bool>.filled(SidebarTab.values.length, false);
    _tabs = List<Widget>.filled(
      SidebarTab.values.length,
      const SizedBox.shrink(),
    );
    _loaded[0] = true;
    _tabs[0] = _tabBuilders[0]();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(sidebarTabProvider);
    final activeIndex = SidebarTab.values.indexOf(activeTab);
    if (!_loaded[activeIndex]) {
      _loaded[activeIndex] = true;
      _tabs[activeIndex] = _tabBuilders[activeIndex]();
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: WebShellScaffold(
        activeTab: activeTab,
        onTabSelected: (tab) {
          ref.read(sidebarTabProvider.notifier).state = tab;
        },
        body: IndexedStack(index: activeIndex, children: _tabs),
      ),
    );
  }
}
