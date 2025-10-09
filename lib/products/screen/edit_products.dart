import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:provider/provider.dart';

class EditProducts extends StatefulWidget {
  final Product product;
  const EditProducts({super.key, required this.product});

  @override
  State<EditProducts> createState() => _EditProductsState();
}

class _EditProductsState extends State<EditProducts> {
  late Product originalProduct;
  bool _hasChanges = false;
  late ProductProvider productProvider;
  final List<String> markets = ["Hyper Market", "Local Market"];

  @override
  void initState() {
    super.initState();
    productProvider = Provider.of<ProductProvider>(context, listen: false);
    Future.microtask(
      () => productProvider.loadProductForEditingOnce(widget.product),
    );
    originalProduct = widget.product;

    // Add listeners to track changes
    productProvider.nameController.addListener(_checkChanges);
    productProvider.itemCodeController.addListener(_checkChanges);
    productProvider.priceController.addListener(_checkChanges);
    productProvider.stockController.addListener(_checkChanges);
    productProvider.unitController.addListener(_checkChanges);
    productProvider.hypermarketController.addListener(_checkChanges);
    productProvider.kgPriceController.addListener(_checkChanges);
    productProvider.ctnPriceController.addListener(_checkChanges);
    productProvider.pcsPriceController.addListener(_checkChanges);
    productProvider.descriptionController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final provider = productProvider;
    final changed =
        provider.nameController.text.trim() != originalProduct.name ||
        provider.itemCodeController.text.trim() != originalProduct.itemCode ||
        double.tryParse(provider.priceController.text.trim()) !=
            originalProduct.price ||
        int.tryParse(provider.stockController.text.trim()) !=
            originalProduct.stock ||
        provider.unitController.text.trim() != originalProduct.unit ||
        provider.selectedMarket != originalProduct.market ||
        provider.selectedCategory != originalProduct.categoryId ||
        double.tryParse(provider.hypermarketController.text.trim()) !=
            originalProduct.hyperMarket ||
        double.tryParse(provider.kgPriceController.text.trim()) !=
            originalProduct.kgPrice ||
        double.tryParse(provider.ctnPriceController.text.trim()) !=
            originalProduct.ctrPrice ||
        double.tryParse(provider.pcsPriceController.text.trim()) !=
            originalProduct.pcsPrice ||
        provider.descriptionController.text.trim() !=
            (originalProduct.description ?? '') ||
        provider.images.length != originalProduct.images.length;

    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  final List<dynamic> imagesToShow =
                      (widget.product.images.isNotEmpty)
                      ? widget.product.images
                      : provider.images;

                  final totalItems = imagesToShow.length + 1;
                  final rows = (totalItems / 2).ceil();
                  final gridHeight = rows * 180.0;

                  return SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(4),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalItems,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        if (index == imagesToShow.length) {
                          return buildStatCard(context, provider, null, index);
                        }
                        final image = imagesToShow[index];
                        return buildStatCard(context, provider, image, index);
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              buildTextField(
                theme,
                "Product Name",
                Iconsax.box,
                productProvider.nameController,
              ),
              const SizedBox(height: 16),
              buildTextField(
                theme,
                "Item Code",
                Iconsax.box,
                productProvider.itemCodeController,
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
                    decoration: buildInputDecoration(
                      theme,
                      "Category",
                      Iconsax.category_2,
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
              buildTextField(
                theme,
                "Stock",
                Iconsax.code_1,
                productProvider.stockController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      theme,
                      "Price",
                      Iconsax.dollar_circle4,
                      productProvider.priceController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildTextField(
                      theme,
                      "Unit (KG / CRN)",
                      Iconsax.level,
                      productProvider.unitController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: markets.contains(productProvider.selectedMarket)
                    ? productProvider.selectedMarket
                    : null,
                decoration: buildInputDecoration(
                  theme,
                  "Market",
                  Iconsax.safe_home,
                ),
                hint: const Text("Select Market"),
                items: markets
                    .map(
                      (market) =>
                          DropdownMenuItem(value: market, child: Text(market)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) productProvider.setMarket(value);
                },
              ),

              const SizedBox(height: 16),
              buildTextField(
                theme,
                "Hyper Market Price",
                Iconsax.box,
                productProvider.hypermarketController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              buildTextField(
                theme,
                "PCS Price",
                Iconsax.box,
                productProvider.pcsPriceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              buildTextField(
                theme,
                "CTN Price",
                Iconsax.box,
                productProvider.ctnPriceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              buildTextField(
                theme,
                "KG Price",
                Iconsax.box,
                productProvider.kgPriceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              if (_hasChanges)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    onPressed: () async {
                      final provider = productProvider;

                      final name = provider.nameController.text.trim();
                      final itemCode = provider.itemCodeController.text.trim();
                      final price = double.tryParse(
                        provider.priceController.text.trim(),
                      );
                      final stock = int.tryParse(
                        provider.stockController.text.trim(),
                      );
                      final unit = provider.unitController.text.trim();
                      final market = provider.selectedMarket;
                      final categoryId = provider.selectedCategory;
                      final description = provider.descriptionController.text
                          .trim();

                      if (name.isEmpty ||
                          itemCode.isEmpty ||
                          price == null ||
                          stock == null ||
                          unit.isEmpty ||
                          market == null ||
                          categoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all required fields!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final editedProduct = Product(
                        id: widget.product.id,
                        name: name,
                        itemCode: itemCode,
                        price: price,
                        stock: stock,
                        unit: unit,
                        market: market,
                        hyperMarket:
                            double.tryParse(
                              provider.hypermarketController.text,
                            ) ??
                            0,
                        images: widget.product.images,
                        categoryId: categoryId,
                        description: description,
                        kgPrice: double.tryParse(
                          provider.kgPriceController.text,
                        ),
                        ctrPrice: double.tryParse(
                          provider.ctnPriceController.text,
                        ),
                        pcsPrice: double.tryParse(
                          provider.pcsPriceController.text,
                        ),
                      );

                      await provider.saveEditedProductDirect(editedProduct);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Product Edited Successfully"),
                          backgroundColor: Colors.green,
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
    ProductProvider provider,
    dynamic image,
    int index,
  ) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Iconsax.camera),
                        title: const Text("Take Photo"),
                        onTap: () => provider.pickImageFromCamera(),
                      ),
                      ListTile(
                        leading: const Icon(Iconsax.gallery),
                        title: const Text("Select From Gallery"),
                        onTap: () => provider.pickMultipleImages(),
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
            child: image == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.image5, size: 35),
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
                    child: SizedBox.expand(
                      child: image is String
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Image.file(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                  ),
          ),
        ),
        if (image != null)
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: () => provider.removeImageAt(index, widget.product),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  TextField buildTextField(
    ThemeData theme,
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: buildInputDecoration(theme, label, icon),
    );
  }

  InputDecoration buildInputDecoration(
    ThemeData theme,
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
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
    );
  }
}
