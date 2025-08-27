import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/categories/screen/add_categories.dart';
import 'package:products_catelogs/dashboard/provider/staff_provider.dart';
import 'package:products_catelogs/products/provider/products_management.dart';
import 'package:products_catelogs/staff_management/screen/staff_management.dart';
import 'package:provider/provider.dart';

class CategoriesManagment extends StatelessWidget {
  const CategoriesManagment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCategories()),
              );
            },
            icon: Icon(Iconsax.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<ProductProvider>(
          builder: (context, value, child) {
            final data =
                value.categories; // Assuming this is a list of salesmen
            if (data.isEmpty) {
              return const Center(child: Text("No Categories found"));
            }
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final cate = data[index];
                return buildSalesmanTile(context, cate.name, cate.id);
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildSalesmanTile(BuildContext context, String name, String id) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.primaryColor,
            child: const Icon(Iconsax.user, color: Colors.white),
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
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(id);
              // provider.deleteStaff(id);
            },
            icon: Icon(Iconsax.trash, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
