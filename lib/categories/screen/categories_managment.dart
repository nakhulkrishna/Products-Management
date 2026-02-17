import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/categories/screen/add_categories.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class CategoriesManagment extends StatelessWidget {
  const CategoriesManagment({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferenceScaffold(
      title: "Categories",
      subtitle: "Manage catalog groups",
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCategories()),
            );
          },
          icon: const Icon(Iconsax.add),
        ),
      ],
      bodyPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      body: Consumer<ProductProvider>(
        builder: (context, value, child) {
          final data = value.categories;
          if (data.isEmpty) {
            return const AppEmptyState(
              assetPath: 'asstes/Image.png',
              title: "No categories yet",
              subtitle: "Add your first category to organize products",
            );
          }

          return AppSectionCard(
            title: "All Categories",
            subtitle: "${data.length} total",
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final cate = data[index];
                return buildSalesmanTile(context, cate.name, cate.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildSalesmanTile(BuildContext context, String name, String id) {
    return AppInfoTile(
      icon: Iconsax.category,
      title: name,
      subtitle: "ID: $id",
      trailing: IconButton(
        onPressed: () {
          context.read<CategoryProvider>().deleteCategory(id);
        },
        icon: const Icon(Iconsax.trash, color: Colors.red),
      ),
    );
  }
}
