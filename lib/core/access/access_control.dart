import 'package:products_catelogs/core/access/user_role.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

class AccessControl {
  static const String permissionsField = 'permissions';

  static const Map<SidebarTab, String> permissionKeyByTab = {
    SidebarTab.dashboard: 'dashboard',
    SidebarTab.products: 'products',
    SidebarTab.orders: 'orders',
    SidebarTab.customers: 'customers',
    SidebarTab.staffs: 'staffs',
    SidebarTab.coreTeam: 'coreTeam',
    SidebarTab.settings: 'settings',
  };

  static const Map<String, SidebarTab> tabByPermissionKey = {
    'dashboard': SidebarTab.dashboard,
    'products': SidebarTab.products,
    'orders': SidebarTab.orders,
    'customers': SidebarTab.customers,
    'staff': SidebarTab.staffs,
    'staffs': SidebarTab.staffs,
    'coreteam': SidebarTab.coreTeam,
    'settings': SidebarTab.settings,
  };

  static List<SidebarTab> allowedTabsForRole(AppUserRole role) {
    switch (role) {
      case AppUserRole.admin:
        return SidebarTab.values;
      case AppUserRole.developer:
        return const [
          SidebarTab.dashboard,
          SidebarTab.products,
          SidebarTab.orders,
          SidebarTab.customers,
          SidebarTab.coreTeam,
          SidebarTab.settings,
        ];
      case AppUserRole.staff:
        return const [
          SidebarTab.orders,
          SidebarTab.customers,
          SidebarTab.settings,
        ];
    }
  }

  static Map<String, bool> defaultPermissionsForRole(AppUserRole role) {
    final allowed = allowedTabsForRole(role).toSet();
    return {
      for (final entry in permissionKeyByTab.entries)
        entry.value: allowed.contains(entry.key),
    };
  }

  static Map<String, bool> parsePermissions(dynamic raw) {
    final parsed = <String, bool>{};
    if (raw is! Map) {
      return parsed;
    }
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) continue;
      final normalized = key.toLowerCase();
      final mappedTab = tabByPermissionKey[normalized];
      final canonicalKey = mappedTab == null ? normalized : permissionKey(mappedTab);
      final value = entry.value;
      final isEnabled = switch (value) {
        bool v => v,
        num v => v != 0,
        String v => v.trim().toLowerCase() == 'true',
        _ => false,
      };
      parsed[canonicalKey] = isEnabled;
    }
    return parsed;
  }

  static List<SidebarTab> allowedTabs({
    required AppUserRole role,
    dynamic permissionsRaw,
  }) {
    final roleAllowedTabs = allowedTabsForRole(role).toSet();
    final defaults = defaultPermissionsForRole(role);
    final overrides = parsePermissions(permissionsRaw);
    final merged = <String, bool>{...defaults, ...overrides};

    final allowed = <SidebarTab>[];
    for (final tab in SidebarTab.values) {
      if (!roleAllowedTabs.contains(tab)) continue;
      final key = permissionKeyByTab[tab];
      if (key == null) continue;
      if (merged[key] == true) {
        allowed.add(tab);
      }
    }

    if (!allowed.contains(SidebarTab.settings)) {
      allowed.add(SidebarTab.settings);
    }
    return allowed;
  }

  static bool canAccessTab({
    required AppUserRole role,
    required SidebarTab tab,
    dynamic permissionsRaw,
  }) {
    return allowedTabs(role: role, permissionsRaw: permissionsRaw).contains(tab);
  }

  static String permissionKey(SidebarTab tab) {
    return permissionKeyByTab[tab] ?? tab.name;
  }

  static SidebarTab defaultTabForRole(AppUserRole role) {
    return allowedTabsForRole(role).first;
  }
}
