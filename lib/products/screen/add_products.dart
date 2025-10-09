import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/dashboard/provider/staff_provider.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/staff_management/provider/provider.dart';
import 'package:provider/provider.dart';

class AddProducts extends StatelessWidget {
  const AddProducts({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final theme = Theme.of(context);
    const List<String> markets = ["Hyper Market", "Local Market"];
    bool isLoading = false;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Products"),
        // backgroundColor: ,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Consumer<ProductProvider>(
                builder: (context, value, child) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: value.images.isEmpty ? 1 : value.images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (context, index) {
                      if (value.images.isEmpty) {
                        // show default empty card
                        return buildStatCard(context, productProvider, null);
                      } else {
                        // show image card
                        return buildStatCard(
                          context,
                          productProvider,
                          value.images[index],
                        );
                      }
                    },
                  );
                },
              ),

              SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.name,
                controller: productProvider.nameController,
                decoration: InputDecoration(
                  labelText: "Products Name",
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
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'Products Name required'
                      : null,
                ),
              ),

              SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.text,
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
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'Products Name required'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  final theme = Theme.of(context);

                  return DropdownButtonFormField<String>(
                    value: productProvider.selectedCategory == null
                        ? null
                        : productProvider.selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Categorie",
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
                      errorText:
                          provider.submitted &&
                              productProvider.selectedCategory == Null
                          ? 'Categorie required'
                          : null,
                    ),

                    items: categoryProvider.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.name, // store id in provider
                        child: Text(cat.name),
                      );
                    }).toList(),

                    onChanged: (value) async {
                      productProvider.setCategory(value ?? "");
                    },
                  );
                },
              ),

              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                controller: productProvider.stockController,
                decoration: InputDecoration(
                  labelText: "Stcok",
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
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'Stcok required'
                      : null,
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
                        labelText: "price",
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
                        errorText:
                            provider.submitted && provider.username.isEmpty
                            ? 'Price  required'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.text,
                      controller: productProvider.unitController,
                      // obscureText: provider.obscurePassword,
                      decoration: InputDecoration(
                        hint: Text("KG / CRN"),
                        labelText: "Unit",
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
                        errorText:
                            provider.submitted && provider.username.isEmpty
                            ? 'Unit required'
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  final theme = Theme.of(context);
                  return DropdownButtonFormField<String>(
                    value: productProvider.selectedMarket ?? null,
                    decoration: InputDecoration(
                      labelText: "Market",
                      prefixIcon: const Icon(Iconsax.safe_home),
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
                      errorText:
                          provider.submitted &&
                              productProvider.selectedMarket == null
                          ? 'Market required'
                          : null,
                    ),
                    items: markets.map((market) {
                      return DropdownMenuItem(
                        value: market,
                        child: Text(market),
                      );
                    }).toList(),
                    onChanged: (value) {
                      productProvider.setMarket(value ?? "");
                      log(value!);
                    },
                  );
                },
              ),
              SizedBox(height: 16),
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
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'Hyper Market Price required'
                      : null,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.text,
                controller: productProvider.kgPriceController,
                decoration: InputDecoration(
                  labelText: "Kg price",
                  prefixIcon: const Icon(Iconsax.weight),
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
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'KG price required'
                      : null,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                controller: productProvider.ctnPriceController,
                decoration: InputDecoration(
                  labelText: "Ctn price",
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
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'Ctn required'
                      : null,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                controller: productProvider.pcsPriceController,
                decoration: InputDecoration(
                  labelText: "Pcs",
                  prefixIcon: const Icon(Iconsax.paperclip),
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
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'Pcs required'
                      : null,
                ),
              ),

              SizedBox(height: 16),

              // Add this inside your build method, above Scaffold
              SizedBox(
                width: double.infinity,
                height: 50,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() => isLoading = true);

                              final hyperPrice =
                                  double.tryParse(
                                    productProvider.hypermarketController.text
                                        .trim(),
                                  ) ??
                                  0;
                              final name = productProvider.nameController.text
                                  .trim();
                              final itemcode = productProvider
                                  .itemCodeController
                                  .text
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
                              final unit = productProvider.unitController.text
                                  .trim();
                              final market =
                                  productProvider.selectedMarket ?? "";
                              final description = productProvider
                                  .descriptionController
                                  .text
                                  .trim();
                              final categoryId =
                                  productProvider.selectedCategory ?? '';
                              final images =
                                  productProvider.images; // base64 / File list

                              final kgPrice =
                                  double.tryParse(
                                    productProvider.kgPriceController.text,
                                  ) ??
                                  0;
                              final ctnPrice =
                                  double.tryParse(
                                    productProvider.ctnPriceController.text,
                                  ) ??
                                  0;
                              final pcsPrice =
                                  double.tryParse(
                                    productProvider.pcsPriceController.text,
                                  ) ??
                                  0;

                              if (name.isEmpty ||
                                  unit.isEmpty ||
                                  categoryId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill all required fields',
                                    ),
                                  ),
                                );
                                setState(() => isLoading = false);
                                return;
                              }

                              final product = Product(
                                images: [],
                                itemCode: itemcode,
                                market: market,
                                id: DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                                name: name,
                                price: price,
                                unit: unit,
                                stock: stock,
                                description: description,
                                categoryId: categoryId,
                                hyperMarket: hyperPrice,
                                pcsPrice: pcsPrice,
                                kgPrice: kgPrice,
                                ctrPrice: ctnPrice,
                              );

                              try {
                                await productProvider.addProduct(
                                  product,
                                  images,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product Added Successfully'),
                                  ),
                                );

                                productProvider.resetForm();
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to add product: $e'),
                                  ),
                                );
                              } finally {
                                setState(() => isLoading = false);
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Add Product",
                              style: TextStyle(fontSize: 18),
                            ),
                    );
                  },
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatCard(
    BuildContext context,
    ProductProvider productProvider,
    File? image,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          showDragHandle: true,
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Makes it fit content
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      productProvider.pickImageFromCamera();
                    },
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Iconsax.camera),
                            SizedBox(width: 10),
                            Text("Take Photo"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      productProvider.pickMultipleImages();
                    },
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Iconsax.gallery),
                            SizedBox(width: 10),
                            Text("Take Photo From Library"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
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
        child: image == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.image5),
                    SizedBox(height: 10),
                    Text(
                      "Tap to add Photos",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(image),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          productProvider.removeImage(image);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
