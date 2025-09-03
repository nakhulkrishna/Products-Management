import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:provider/provider.dart';

class EditProducts extends StatelessWidget {
  final Product product;
  const EditProducts({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final theme = Theme.of(context);
    const List<String> markets = ["Hyper Market", "Local Market"];

    productProvider.nameController.text = product.name;
    productProvider.itemCodeController.text = product.itemCode;
    productProvider.priceController.text = product.price.toString();
    productProvider.stockController.text = product.stock.toString();
    productProvider.unitController.text = product.unit;
    productProvider.hypermarketController.text = product.hyperMarket.toString();
    productProvider.selectedMarket = product.market;
    productProvider.selectedCategory = product.categoryId;
    productProvider.images = List<String>.from(product.images);
    productProvider.descriptionController.text = product.description;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Consumer<ProductProvider>(
                builder: (context, value, child) {
               return  GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: productProvider.images.isEmpty ? 1 : productProvider.images.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.2,
  ),
  itemBuilder: (context, index) {
    final image = productProvider.images.isEmpty ? "" : productProvider.images[index];
    return buildStatCard(context, productProvider, image, );
  },
);

                },
              ),

              const SizedBox(height: 16),
              TextField(
                controller: productProvider.nameController,
                decoration: InputDecoration(
                  labelText: "Product Name",
                  prefixIcon: const Icon(Iconsax.box),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: productProvider.itemCodeController,
                decoration: InputDecoration(
                  labelText: "Item Code",
                  prefixIcon: const Icon(Iconsax.box),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  final categories = categoryProvider.categories;
                  final selected =
                      categories.any(
                        (c) =>
                            c.id.toString() == productProvider.selectedCategory,
                      )
                      ? productProvider.selectedCategory
                      : null;

                  return DropdownButtonFormField<String>(
                    value: selected,
                    hint: const Text('Select Category'),
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon: const Icon(Iconsax.category_2),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: theme.cardColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: theme.cardColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id.toString(),
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) productProvider.setCategory(value);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                controller: productProvider.stockController,
                decoration: InputDecoration(
                  labelText: "Stock",
                  prefixIcon: const Icon(Iconsax.code_1),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: productProvider.priceController,
                      decoration: InputDecoration(
                        labelText: "Price",
                        prefixIcon: const Icon(Iconsax.dollar_circle4),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: theme.cardColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: theme.cardColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: productProvider.unitController,
                      decoration: InputDecoration(
                        labelText: "Unit (KG / CRN)",
                        prefixIcon: const Icon(Iconsax.level),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: theme.cardColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: theme.cardColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: markets.contains(productProvider.selectedMarket)
                    ? productProvider.selectedMarket
                    : null, // Set null if current value is not in the list
                decoration: InputDecoration(
                  labelText: "Market",
                  prefixIcon: const Icon(Iconsax.safe_home),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                hint: const Text(
                  "Select Market",
                ), // Placeholder when value is null
                items: markets.map((market) {
                  return DropdownMenuItem(value: market, child: Text(market));
                }).toList(),
                onChanged: (value) {
                  if (value != null) productProvider.setMarket(value);
                },
              ),

              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                controller: productProvider.hypermarketController,
                decoration: InputDecoration(
                  labelText: "Hyper Market Price",
                  prefixIcon: const Icon(Iconsax.box),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.cardColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: () {
                    final hyperPrice =
                        double.tryParse(
                          productProvider.hypermarketController.text.trim(),
                        ) ??
                        0;
                    final name = productProvider.nameController.text.trim();
                    final itemCode = productProvider.itemCodeController.text
                        .trim();
                    final price =
                        double.tryParse(
                          productProvider.priceController.text.trim(),
                        ) ??
                        0;
                    final stock =
                        int.tryParse(
                          productProvider.stockController.text.trim(),
                        ) ??
                        0;
                    final unit = productProvider.unitController.text.trim();
                    final market = productProvider.selectedMarket ?? "";
                    final categoryId = productProvider.selectedCategory ?? "";
                    final images = productProvider.images;

                    final editedProduct = Product(
                      id: product.id,
                      name: name,
                      itemCode: itemCode,
                      price: price,
                      stock: stock,
                      unit: unit,
                      market: market,
                      hyperMarket: hyperPrice,
                      images: images,
                      categoryId: categoryId,
                      description: productProvider.descriptionController.text
                          .trim(),
                    );

                    productProvider.editProduct(product, editedProduct);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product Edited Successfully'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatCard(
    BuildContext context,
    ProductProvider productProvider,
    String image,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          showDragHandle: true,
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => productProvider.pickImageFromCamera(),
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      child: Row(
                        children: const [
                          Icon(Iconsax.camera),
                          SizedBox(width: 10),
                          Text("Take Photo"),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => productProvider.pickMultipleImages(context),
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      child: Row(
                        children: const [
                          Icon(Iconsax.gallery),
                          SizedBox(width: 10),
                          Text("Select From Gallery"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: image.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.image5),
                    const SizedBox(height: 10),
                    Text(
                      "Tap to add Photos",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(image), fit: BoxFit.cover),
              ),
      ),
    );
  }


}
