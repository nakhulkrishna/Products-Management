import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/products/provider/products_management.dart';
import 'package:provider/provider.dart';

import 'add_products.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final products = provider.products;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.hasSelection
            ? "${provider.selectedCount} Selected"
            : "Products"),
        actions: [
          if (provider.hasSelection)
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.red),
              onPressed: () {
                provider.deleteSelected();
              },
            )
          else
            IconButton(
              onPressed: () {
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
            // table headers
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
                            'Name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Price',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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
            // list
            Expanded(
              child: ListView.separated(
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
                            provider.toggleSelection(product, val ?? false);
                          },
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Image.asset(product.image,
                                width: 40, height: 40, fit: BoxFit.cover),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(product.code,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text('\$${product.price}'),
                      ),
                      Row(
                        children: const [
                          Icon(Iconsax.edit, color: Colors.grey),
                          SizedBox(width: 8),
                          Icon(Iconsax.trash, color: Colors.red),
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
}
