import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/core/constants/app_colors.dart';
import 'package:products_catelogs/core/access/access_control.dart';
import 'package:products_catelogs/core/access/user_role.dart';
import 'package:products_catelogs/features/auth/application/auth_providers.dart';
import 'package:products_catelogs/features/core_team/presentation/pages/core_team_tab_page.dart';
import 'package:products_catelogs/features/customers/presentation/pages/customers_tab_page.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final profileState = ref.watch(userProfileProvider);
    final role = profileState.maybeWhen(
      data: (profile) => appUserRoleFromRaw(profile?['role']),
      orElse: () => AppUserRole.staff,
    );
    final profileData = profileState.value;
    final allowedTabs = ref.watch(allowedTabsProvider);
    if (allowedTabs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No accessible modules for this account.')),
      );
    }

    final fullName = profileData?['fullName']?.toString().trim() ?? '';
    final userName = fullName.isNotEmpty
        ? fullName
        : (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');
    final userSubtitle = '${role.label}  |  ${user?.email ?? 'Authenticated'}';
    final requestedTab = ref.watch(sidebarTabProvider);
    final activeTab = allowedTabs.contains(requestedTab)
        ? requestedTab
        : allowedTabs.first;
    if (activeTab != requestedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(sidebarTabProvider.notifier).state = activeTab;
      });
    }

    final activeIndex = SidebarTab.values.indexOf(activeTab);
    if (!_loaded[activeIndex]) {
      _loaded[activeIndex] = true;
      _tabs[activeIndex] = _buildTab(activeIndex);
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: WebShellScaffold(
        activeTab: activeTab,
        visibleTabs: allowedTabs,
        onTabSelected: (tab) {
          if (!allowedTabs.contains(tab)) {
            _showAccessDenied(tab.label);
            return;
          }
          ref.read(sidebarTabProvider.notifier).state = tab;
        },
        onLogout: _logout,
        onOpenSettings: _openSettings,
        onSearchSubmitted: _handleGlobalSearch,
        onOpenOrdersFromNotifications: _openOrdersFromNotifications,
        onOpenCoreTeamFromNotifications: _openCoreTeamFromNotifications,
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
      case SidebarTab.customers:
        return const CustomersTabPage();
      case SidebarTab.staffs:
        return const StaffsTabPage();
      case SidebarTab.coreTeam:
        return const CoreTeamTabPage();
      case SidebarTab.settings:
        return SettingsTabPage(onLogout: _logout);
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  void _openSettings() {
    ref.read(sidebarTabProvider.notifier).state = SidebarTab.settings;
  }

  void _openOrdersFromNotifications() {
    final role = ref.read(currentUserRoleProvider);
    final profile = ref.read(userProfileProvider).value;
    final allowedTabs = AccessControl.allowedTabs(
      role: role,
      permissionsRaw: profile?[AccessControl.permissionsField],
    );
    if (!allowedTabs.contains(SidebarTab.orders)) {
      _showAccessDenied(SidebarTab.orders.label);
      return;
    }
    ref.read(sidebarTabProvider.notifier).state = SidebarTab.orders;
  }

  void _openCoreTeamFromNotifications() {
    final role = ref.read(currentUserRoleProvider);
    final profile = ref.read(userProfileProvider).value;
    final allowedTabs = AccessControl.allowedTabs(
      role: role,
      permissionsRaw: profile?[AccessControl.permissionsField],
    );
    if (!allowedTabs.contains(SidebarTab.coreTeam)) {
      _showAccessDenied(SidebarTab.coreTeam.label);
      return;
    }
    ref.read(sidebarTabProvider.notifier).state = SidebarTab.coreTeam;
  }

  void _handleGlobalSearch(String query) {
    final role = ref.read(currentUserRoleProvider);
    final profile = ref.read(userProfileProvider).value;
    final allowedTabs = AccessControl.allowedTabs(
      role: role,
      permissionsRaw: profile?[AccessControl.permissionsField],
    );
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return;

    SidebarTab? target;
    if (normalized.contains('order')) {
      target = SidebarTab.orders;
    } else if (normalized.contains('customer') ||
        normalized.contains('client')) {
      target = SidebarTab.customers;
    } else if (normalized.contains('product') ||
        normalized.contains('category')) {
      target = SidebarTab.products;
    } else if (normalized.contains('staff') ||
        normalized.contains('salesman')) {
      target = SidebarTab.staffs;
    } else if (normalized.contains('core') ||
        normalized.contains('team') ||
        normalized.contains('admin user')) {
      target = SidebarTab.coreTeam;
    } else if (normalized.contains('setting') ||
        normalized.contains('profile')) {
      target = SidebarTab.settings;
    } else if (normalized.contains('dashboard') ||
        normalized.contains('sale')) {
      target = SidebarTab.dashboard;
    }

    if (target != null) {
      if (!allowedTabs.contains(target)) {
        _showAccessDenied(target.label);
        return;
      }
      ref.read(sidebarTabProvider.notifier).state = target;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened ${target.label} for "$query".')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No module mapped for "$query".')));
    }
  }

  void _showAccessDenied(String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You do not have access to $moduleName.')),
    );
  }
}
