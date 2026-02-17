import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:products_catelogs/categories/screen/categories_managment.dart';
import 'package:products_catelogs/orders/screen/orders_screen.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/products/screen/products_management.dart';
import 'package:products_catelogs/settings/screens/settings.dart';
import 'package:products_catelogs/staff_management/provider/provider.dart';
import 'package:products_catelogs/staff_management/screen/salesman_screen.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ReferenceScaffold(
      title: "Dashboard",
      subtitle: "Welcome back",
      showBackButton: false,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.setting),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Settings()),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionCard(
              color: theme.colorScheme.primary.withAlpha(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.wallet_3, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Total Sale Value",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<ProductProvider>(
                    builder: (context, value, child) {
                      return Text(
                        "QAR ${value.totalOrderValue.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Consumer2<ProductProvider, StaffProvider>(
              builder: (context, value, staff, child) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 15,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductsManagement(),
                          ),
                        );
                      },
                      child: buildStatCard(
                        context,
                        Iconsax.box,
                        "Products",
                        "${value.products.length}",
                        backgroundColor: Color.alphaBlend(
                          theme.colorScheme.primary.withAlpha(18),
                          theme.cardColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrdersScreen(),
                          ),
                        );
                      },
                      child: buildStatCard(
                        context,
                        Iconsax.shopping_cart,
                        "Total Orders",
                        "${value.orders.length}",
                        backgroundColor: Color.alphaBlend(
                          theme.colorScheme.primary.withAlpha(28),
                          theme.cardColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoriesManagment(),
                          ),
                        );
                      },
                      child: buildStatCard(
                        context,
                        Iconsax.category,
                        "Categories",
                        "${value.categories.length}",
                        backgroundColor: Color.alphaBlend(
                          theme.colorScheme.primary.withAlpha(38),
                          theme.cardColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SalesmanScreen(),
                          ),
                        );
                      },
                      child: buildStatCard(
                        context,
                        Iconsax.people,
                        "Sales Man",
                        "${staff.staffList.length}",
                        backgroundColor: Color.alphaBlend(
                          theme.colorScheme.primary.withAlpha(48),
                          theme.cardColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Consumer<ProductProvider>(
              builder: (context, value, child) {
                if (value.orders.isEmpty) {
                  return const AppEmptyState(
                    assetPath: 'asstes/Image.png',
                    title: "No recent orders",
                    subtitle:
                        "Orders will appear here after customers place them",
                  );
                }

                final visibleOrders = value.orders.length > 8
                    ? value.orders.take(8).toList()
                    : value.orders;

                return AppSectionCard(
                  title: "Recent Orders",
                  subtitle: "Latest ${visibleOrders.length} entries",
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleOrders.length,
                    itemBuilder: (context, index) {
                      final orders = visibleOrders[index];
                      final formattedDate = orders.timestamp != null
                          ? DateFormat('d MMM yyyy').format(orders.timestamp!)
                          : '';
                      return buildTransaction(
                        context,
                        orders.productName,
                        formattedDate,
                        orders.total.toString(),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.iconTheme.color, size: 30),
          const SizedBox(height: 12),
          AutoSizeText(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            minFontSize: 20,
            maxFontSize: 50,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.bodySmall!.copyWith(fontSize: 15)),
        ],
      ),
    );
  }

  Widget buildTransaction(
    BuildContext context,
    String name,
    String date,
    String txnId,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: theme.colorScheme.primary.withAlpha(28),
            child: Icon(Iconsax.box, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Total",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("QAR $txnId", style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
