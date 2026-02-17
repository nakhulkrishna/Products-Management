import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart' show Iconsax;
import 'package:intl/intl.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferenceScaffold(
      title: "Orders",
      subtitle: "Recent sales records",
      bodyPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      body: Consumer<ProductProvider>(
        builder: (context, value, child) {
          if (value.orders.isEmpty) {
            return const AppEmptyState(
              assetPath: 'asstes/Image.png',
              title: "No orders yet",
              subtitle: "Placed orders will appear here",
            );
          }

          final orders = value.orders.length > 8
              ? value.orders.take(8).toList()
              : value.orders;

          return AppSectionCard(
            title: "Latest Orders",
            subtitle: "Showing ${orders.length} recent entries",
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final formattedDate = order.timestamp != null
                    ? DateFormat('d MMM yyyy').format(order.timestamp!)
                    : '';
                return buildTransaction(
                  context,
                  order.productName,
                  formattedDate,
                  order.total.toString(),
                );
              },
            ),
          );
        },
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
            backgroundColor: theme.colorScheme.primary.withAlpha(30),
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
