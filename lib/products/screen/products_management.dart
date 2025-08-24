import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/products/provider/products_management.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/products/screen/edit_products.dart';
import 'package:provider/provider.dart';
import 'add_products.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String searchQuery = "";
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    // 🔎 Apply search + filter
    final products = productProvider.products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final matchesCategory =
          selectedCategory == null ||
          selectedCategory == "All" ||
          product.categoryId == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          productProvider.hasSelection
              ? "${productProvider.selectedCount} Selected"
              : "Products",
        ),
        actions: [
          if (productProvider.hasSelection)
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.red),
              onPressed: () {
                productProvider.deleteSelected();
              },
            )
          else
            IconButton(
              onPressed: () {
                productProvider.resetForm();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddProductScreen()),
                );
              },
              icon: const Icon(Iconsax.box_add),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
         
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search..",
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Iconsax.search_normal,
                    size: 22,
                    color: Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Iconsax.setting_4,
                      size: 22,
                      color: Colors.black87,
                    ),
                    onPressed: () {
                      /// 👉 Open Filter BottomSheet
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Filter by Category",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...categoryProvider.categories.map(
                                  (c) => ListTile(
                                    title: Text(c.name),
                                    leading: Radio<String>(
                                      value: c.name,
                                      groupValue: selectedCategory,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedCategory = value;
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                                ListTile(
                                  title: const Text("All"),
                                  leading: Radio<String>(
                                    value: "All",
                                    groupValue: selectedCategory ?? "All",
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategory = value;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Table headers
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blueGrey.shade400,
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 40),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Products',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // List
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text("No products found"))
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Checkbox(
                                value: product.selected,
                                onChanged: (val) {
                                  productProvider.toggleSelection(
                                    product,
                                    val ?? false,
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  buildProductImage(product.images),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        product.id,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '₹ ${product.price}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    productProvider.resetForm();
                                   Navigator.push(context, MaterialPageRoute(builder: (context) => EditProducts(product: product,),));
                                  },
                                  icon: const Icon(
                                    Iconsax.edit,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }


Widget buildProductImage(List<String> images) {
  try {
    if (images.isEmpty) {
      return const Icon(Iconsax.camera, size: 40, color: Colors.grey);
    }
    // Show only the first image
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.memory(
        base64Decode(images.first),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  } catch (e) {
    return const Icon(Icons.broken_image, size: 40, color: Colors.red);
  }
}

}
