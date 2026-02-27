import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/core/constants/app_strings.dart';

enum SidebarTab { dashboard, products, orders, customers, staffs, settings }

extension SidebarTabX on SidebarTab {
  String get label {
    switch (this) {
      case SidebarTab.dashboard:
        return AppStrings.dashboardTitle;
      case SidebarTab.products:
        return AppStrings.productsTitle;
      case SidebarTab.orders:
        return AppStrings.ordersTitle;
      case SidebarTab.customers:
        return AppStrings.customersTitle;
      case SidebarTab.staffs:
        return AppStrings.staffsTitle;
      case SidebarTab.settings:
        return AppStrings.settingsTitle;
    }
  }

  IconData get icon {
    switch (this) {
      case SidebarTab.dashboard:
        return Iconsax.category;
      case SidebarTab.products:
        return Iconsax.box;
      case SidebarTab.orders:
        return Iconsax.bill;
      case SidebarTab.customers:
        return Iconsax.profile_2user;
      case SidebarTab.staffs:
        return Iconsax.user;
      case SidebarTab.settings:
        return Iconsax.setting;
    }
  }
}
