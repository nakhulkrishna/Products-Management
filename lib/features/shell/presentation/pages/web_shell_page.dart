import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/core/constants/app_colors.dart';
import 'package:products_catelogs/features/auth/application/auth_providers.dart';
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
    _tabs[0] = _buildTab(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final userName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');
    final userSubtitle = user?.email ?? 'Authenticated';
    final activeTab = ref.watch(sidebarTabProvider);
    final activeIndex = SidebarTab.values.indexOf(activeTab);
    if (!_loaded[activeIndex]) {
      _loaded[activeIndex] = true;
      _tabs[activeIndex] = _buildTab(activeIndex);
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: WebShellScaffold(
        activeTab: activeTab,
        onTabSelected: (tab) {
          ref.read(sidebarTabProvider.notifier).state = tab;
        },
        onLogout: _logout,
        onOpenSettings: _openSettings,
        onSearchSubmitted: _handleGlobalSearch,
        userName: userName,
        userSubtitle: userSubtitle,
        body: IndexedStack(index: activeIndex, children: _tabs),
      ),
    );
  }

  Widget _buildTab(int index) {
    switch (SidebarTab.values[index]) {
      case SidebarTab.dashboard:
        return const DashboardTabPage();
      case SidebarTab.products:
        return const ProductsTabPage();
      case SidebarTab.orders:
        return const OrdersTabPage();
      case SidebarTab.staffs:
        return const StaffsTabPage();
      case SidebarTab.settings:
        return SettingsTabPage(onLogout: _logout);
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _openSettings() {
    ref.read(sidebarTabProvider.notifier).state = SidebarTab.settings;
  }

  void _handleGlobalSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return;

    SidebarTab? target;
    if (normalized.contains('order')) {
      target = SidebarTab.orders;
    } else if (normalized.contains('product') ||
        normalized.contains('category')) {
      target = SidebarTab.products;
    } else if (normalized.contains('staff') ||
        normalized.contains('salesman')) {
      target = SidebarTab.staffs;
    } else if (normalized.contains('setting') ||
        normalized.contains('profile')) {
      target = SidebarTab.settings;
    } else if (normalized.contains('dashboard') ||
        normalized.contains('sale')) {
      target = SidebarTab.dashboard;
    }

    if (target != null) {
      ref.read(sidebarTabProvider.notifier).state = target;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened ${target.label} for "$query".')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No module mapped for "$query".')),
      );
    }
  }
}
