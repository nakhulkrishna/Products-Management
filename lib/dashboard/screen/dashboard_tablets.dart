import 'package:flutter/material.dart';
import 'package:products_catelogs/dashboard/provider/side_bar_provider.dart';
import 'package:provider/provider.dart';
import 'package:products_catelogs/theme/colors.dart';
import 'package:products_catelogs/products/screen/products_management.dart';
import 'package:products_catelogs/categories/screen/categories_managment.dart';
import 'package:products_catelogs/staff_management/screen/salesman_screen.dart';
import 'package:products_catelogs/orders/screen/orders_screen.dart';
import 'package:products_catelogs/settings/screens/settings.dart';


class DashboardTablets extends StatelessWidget {
  const DashboardTablets({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarProvider = Provider.of<SidebarProvider>(context);

    final screens = [
      const ProductsManagement(),
      const CategoriesManagment(),
      const SalesmanScreen(),
      const OrdersScreen(),
      const Settings(),
    ];

    final titles = ["Products", "Categories", "Sales Mans", "Orders", "Settings"];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: TabletColors.secondaryRed,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Dashboard",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...List.generate(titles.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      sidebarProvider.setIndex(index);
                    },
                    child: Container(
                      color: sidebarProvider.selectedIndex == index
                          ? TabletColors.primaryRed
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      child: Row(
                        children: [
                          Icon(_getIcon(index), color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            titles[index],
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Main Content
          Expanded(
            flex: 4,
            child: screens[sidebarProvider.selectedIndex],
          )
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.inventory_2;
      case 1:
        return Icons.category;
      case 2:
        return Icons.people;
      case 3:
        return Icons.shopping_cart;
      case 4:
        return Icons.settings;
      default:
        return Icons.dashboard;
    }
  }
}
