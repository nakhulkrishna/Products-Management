import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart'
    hide Category;
import 'package:products_catelogs/theme/colors.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class EditProducts extends StatefulWidget {
  final Product product;

  const EditProducts({super.key, required this.product});

  @override
  State<EditProducts> createState() => _EditProductsState();
}

class _EditProductsState extends State<EditProducts> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _showAdvancedPrices = false;

  static const List<String> _markets = ["Hyper Market", "Local Market"];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();

    Future.microtask(() {
      provider.loadProductForEditingOnce(widget.product);
      if (!mounted) return;
      setState(() {
        _showAdvancedPrices =
            provider.hypermarketController.text.trim().isNotEmpty ||
            provider.kgPriceController.text.trim().isNotEmpty ||
            provider.ctnPriceController.text.trim().isNotEmpty ||
            provider.pcsPriceController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return ReferenceScaffold(
      title: "Edit Product",
      subtitle: "Simple and quick update",
      bodyPadding: EdgeInsets.zero,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildImagesSection(context, productProvider),
                const SizedBox(height: 16),
                AppSectionCard(
                  title: "Basic Details",
                  subtitle: "Update required product info",
                  child: Column(
                    children: [
                      _buildTextField(
                        context,
                        controller: productProvider.nameController,
                        label: "Product Name",
                        icon: Iconsax.box,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Product name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        context,
                        controller: productProvider.itemCodeController,
                        label: "Item Code",
                        icon: Iconsax.barcode,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Item code is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _normalizedCategoryValue(
                          productProvider.selectedCategory,
                          categoryProvider.categories,
                        ),
                        decoration: _fieldDecoration(
                          context,
                          label: "Category",
                          icon: Iconsax.category_2,
                        ),
                        items: categoryProvider.categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.name,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Select a category';
                          }
                          return null;
                        },
                        onChanged: (value) =>
                            productProvider.setCategory(value?.trim()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue:
                            _markets.contains(productProvider.selectedMarket)
                            ? productProvider.selectedMarket
                            : null,
                        decoration: _fieldDecoration(
                          context,
                          label: "Market",
                          icon: Iconsax.safe_home,
                        ),
                        items: _markets
                            .map(
                              (market) => DropdownMenuItem(
                                value: market,
                                child: Text(market),
                              ),
                            )
                            .toList(),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Select a market';
                          }
                          return null;
                        },
                        onChanged: (value) =>
                            productProvider.setMarket(value?.trim()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              controller: productProvider.priceController,
                              label: "Base Price",
                              icon: Iconsax.dollar_circle,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value!.trim()) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              context,
                              controller: productProvider.stockController,
                              label: "Stock",
                              icon: Iconsax.archive,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value!.trim()) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        context,
                        controller: productProvider.unitController,
                        label: "Unit (KG / CTN / PCS)",
                        icon: Iconsax.weight,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Unit is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        context,
                        controller: productProvider.descriptionController,
                        label: "Description (Optional)",
                        icon: Iconsax.note,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SwitchListTile.adaptive(
                          value: _showAdvancedPrices,
                          onChanged: (value) {
                            setState(() => _showAdvancedPrices = value);
                          },
                          title: const Text("Use Different Unit Prices"),
                          subtitle: const Text("CTN, KG, PCS and Hyper Market"),
                          activeThumbColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      context,
                                      controller:
                                          productProvider.hypermarketController,
                                      label: "Hyper Market",
                                      icon: Iconsax.shop,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildTextField(
                                      context,
                                      controller:
                                          productProvider.ctnPriceController,
                                      label: "CTN Price",
                                      icon: Iconsax.box,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      context,
                                      controller:
                                          productProvider.kgPriceController,
                                      label: "KG Price",
                                      icon: Iconsax.weight,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildTextField(
                                      context,
                                      controller:
                                          productProvider.pcsPriceController,
                                      label: "PCS Price",
                                      icon: Iconsax.hierarchy_3,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: _showAdvancedPrices
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _submit(
                                  context,
                                  productProvider,
                                  categoryProvider.categories,
                                ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Save Changes"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    final images = productProvider.images;

    return AppSectionCard(
      title: "Product Photos",
      subtitle: "Tap + to add image",
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length + 1,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddImageTile(context, productProvider);
          }
          final image = images[index - 1];
          return _buildImageTile(
            context,
            image,
            onRemove: () => productProvider.removeImageAt(index - 1),
          );
        },
      ),
    );
  }

  Widget _buildAddImageTile(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showImageSourceSheet(context, productProvider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Iconsax.add_square, color: AppColors.brandRed),
            SizedBox(height: 6),
            Text('Add'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    dynamic image, {
    required VoidCallback onRemove,
  }) {
    Widget imageWidget;
    if (image is File) {
      imageWidget = Image.file(image, fit: BoxFit.cover);
    } else if (image is String) {
      imageWidget = Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Iconsax.image),
      );
    } else {
      imageWidget = const Icon(Iconsax.image);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceSheet(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppSectionCard(
              title: "Add Photo",
              subtitle: "Choose image source",
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppInfoTile(
                    icon: Iconsax.camera,
                    title: "Camera",
                    subtitle: "Take a new photo",
                    onTap: () async {
                      await productProvider.pickImageFromCamera();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                  AppInfoTile(
                    icon: Iconsax.gallery,
                    title: "Gallery",
                    subtitle: "Pick one or more images",
                    onTap: () async {
                      await productProvider.pickMultipleImages();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TextFormField _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: _fieldDecoration(context, label: label, icon: icon),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon));
  }

  String? _normalizedCategoryValue(String? value, List<Category> categories) {
    if (value == null || value.trim().isEmpty) return null;
    for (final category in categories) {
      if (category.name == value) return category.name;
      if (category.id == value) return category.name;
    }
    return null;
  }

  double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  int _toInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  Future<void> _submit(
    BuildContext context,
    ProductProvider productProvider,
    List<Category> categories,
  ) async {
    if (_isSaving) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final category =
        _normalizedCategoryValue(
          productProvider.selectedCategory,
          categories,
        ) ??
        '';
    final market = productProvider.selectedMarket ?? '';

    if (category.isEmpty || market.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and market')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedProduct = Product(
      id: widget.product.id,
      name: productProvider.nameController.text.trim(),
      itemCode: productProvider.itemCodeController.text.trim(),
      market: market,
      categoryId: category,
      price: _toDouble(productProvider.priceController.text),
      stock: _toInt(productProvider.stockController.text),
      unit: productProvider.unitController.text.trim(),
      description: productProvider.descriptionController.text.trim(),
      hyperMarket: _toDouble(productProvider.hypermarketController.text),
      kgPrice: _toDouble(productProvider.kgPriceController.text),
      ctrPrice: _toDouble(productProvider.ctnPriceController.text),
      pcsPrice: _toDouble(productProvider.pcsPriceController.text),
      offerPrice: widget.product.offerPrice,
      hyperMarketPrice: widget.product.hyperMarketPrice,
      isHidden: widget.product.isHidden,
      images: widget.product.images,
    );

    try {
      await productProvider.saveEditedProductDirect(updatedProduct);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
