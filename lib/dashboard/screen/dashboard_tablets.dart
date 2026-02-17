import 'package:flutter/material.dart';
import 'package:products_catelogs/categories/screen/categories_managment.dart';
import 'package:products_catelogs/dashboard/provider/side_bar_provider.dart';
import 'package:products_catelogs/orders/screen/orders_screen.dart';
import 'package:products_catelogs/products/screen/products_management.dart';
import 'package:products_catelogs/settings/screens/settings.dart';
import 'package:products_catelogs/staff_management/screen/salesman_screen.dart';
import 'package:products_catelogs/theme/colors.dart';
import 'package:provider/provider.dart';

class DashboardTablets extends StatelessWidget {
  const DashboardTablets({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarProvider = context.watch<SidebarProvider>();

    final screens = [
      const ProductsManagement(),
      const CategoriesManagment(),
      const SalesmanScreen(),
      const OrdersScreen(),
      const Settings(),
    ];

    final titles = [
      "Products",
      "Categories",
      "Sales Team",
      "Orders",
      "Settings",
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.brandRedDark, AppColors.brandRed],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Red Rose Admin",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: titles.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final isSelected =
                            sidebarProvider.selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => sidebarProvider.setIndex(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: isSelected
                                      ? Colors.white.withAlpha(34)
                                      : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(color: Colors.white24)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIcon(index),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      titles[index],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: screens[sidebarProvider.selectedIndex]),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.inventory_2_rounded;
      case 1:
        return Icons.category_rounded;
      case 2:
        return Icons.people_rounded;
      case 3:
        return Icons.shopping_cart_rounded;
      case 4:
        return Icons.settings_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }
}
