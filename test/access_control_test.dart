import 'package:flutter_test/flutter_test.dart';
import 'package:products_catelogs/core/access/access_control.dart';
import 'package:products_catelogs/core/access/user_role.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

void main() {
  group('User role parsing', () {
    test('maps admin-like raw values to admin', () {
      expect(appUserRoleFromRaw('admin'), AppUserRole.admin);
      expect(appUserRoleFromRaw('manager'), AppUserRole.admin);
    });

    test('maps unknown values to staff', () {
      expect(appUserRoleFromRaw(null), AppUserRole.staff);
      expect(appUserRoleFromRaw('anything-else'), AppUserRole.staff);
    });
  });

  group('Access control', () {
    test('staff defaults include orders, customers, settings', () {
      final tabs = AccessControl.allowedTabs(role: AppUserRole.staff);
      expect(tabs.contains(SidebarTab.orders), isTrue);
      expect(tabs.contains(SidebarTab.customers), isTrue);
      expect(tabs.contains(SidebarTab.settings), isTrue);
      expect(tabs.contains(SidebarTab.products), isFalse);
    });

    test('settings remains accessible even if explicitly disabled', () {
      final tabs = AccessControl.allowedTabs(
        role: AppUserRole.staff,
        permissionsRaw: {'settings': false, 'orders': true, 'customers': true},
      );
      expect(tabs.contains(SidebarTab.settings), isTrue);
    });

    test('permission aliases normalize correctly', () {
      final parsed = AccessControl.parsePermissions({
        'staff': true,
        'coreteam': true,
      });
      expect(parsed['staffs'], isTrue);
      expect(parsed['coreTeam'], isTrue);
    });
  });
}
