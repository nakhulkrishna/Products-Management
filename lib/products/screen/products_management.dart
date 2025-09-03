import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/products/provider/p.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/products/screen/add_products.dart';
import 'package:products_catelogs/products/screen/edit_products.dart';
import 'package:provider/provider.dart';

class ProductsManagement extends StatelessWidget {
  const ProductsManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProvider = context.read<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Products"),
        leading: IconButton(onPressed: (){
          productProvider.cancelProductListener();
          Navigator.pop(context);
        }, icon: Icon(Iconsax.arrow_left)),
        actions: [
          IconButton(
            onPressed: () {
              productProvider.resetForm();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProducts()),
              );
            },
            icon: Icon(Iconsax.add),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 50,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: theme.cardColor,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ), // padding inside the search bar
                      child: Row(
                        children: [
                          Icon(Icons.search, color: theme.iconTheme.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search products...",
                                border: InputBorder
                                    .none, // removes the default underline
                              ),
                              onChanged: (value) {
                                context
                                    .read<ProductProvider>()
                                    .updateSearchQuery(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 50,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: theme.cardColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),

                      child: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) {
                              return Consumer<ProductProvider>(
                                builder: (context, provider, child) {
                                  return Container(
                                    padding: EdgeInsets.all(16),
                                    height: 350,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Filter Products",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineMedium,
                                        ),
                                        SizedBox(height: 20),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount:
                                                provider.categories.length,
                                            itemBuilder: (context, index) {
                                              final category =
                                                  provider.categories[index];
                                              final isSelected = provider
                                                  .selectedFilterCategories
                                                  .contains(category.name);

                                              return ListTile(
                                                title: Text(category.name),
                                                trailing: Checkbox(
                                                  value: isSelected,
                                                  onChanged: (val) {
                                                    provider
                                                        .toggleFilterCategory(
                                                          category.name,
                                                        );
                                                  },
                                                ),
                                                onTap: () => provider
                                                    .toggleFilterCategory(
                                                      category.name,
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            ); // close the sheet
                                          },
                                          child: Text("Apply Filter"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        icon: Icon(Iconsax.filter),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Consumer<ProductProvider>(
                builder: (context, value, child) {
                  final products = value.filteredProducts;
                  if (products.isEmpty) {
                    return SizedBox(
                      height:
                          MediaQuery.of(context).size.height -
                          kToolbarHeight, // screen height minus AppBar
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'asstes/Image-3.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No products found",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final products = value.products[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onLongPress: () =>
                              _showProductOptions(context, products),
                          child: Column(
                            children: [
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (products.images != null &&
                                              products.images.isNotEmpty &&
                                              products
                                                  .images
                                                  .first
                                                  .isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ImagePreviewPage(
                                                      images: products.images,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        child:
                                            (products.images == null ||
                                                products.images.isEmpty ||
                                                products.images.first.isEmpty)
                                            ? const Icon(Iconsax.image)
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.memory(
                                                  base64Decode(
                                                    products.images.first,
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                      ),
                                      SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              maxLines: 2,
                                              products.name,
                                              style: theme.textTheme.bodyLarge!
                                                  .copyWith(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),

                                          Text(
                                            products.categoryId,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          Text(
                                            products.market,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                    ),
                                                    builder: (context) {
                                                      final TextEditingController
                                                      offerPriceController =
                                                          TextEditingController(
                                                            text:
                                                                products
                                                                    .offerPrice
                                                                    ?.toString() ??
                                                                "",
                                                          );
                                                      final TextEditingController
                                                      hypermarketPriceController =
                                                          TextEditingController(
                                                            text:
                                                                products
                                                                    .hyperMarketPrice
                                                                    ?.toString() ??
                                                                "",
                                                          );

                                                      return Padding(
                                                        padding: EdgeInsets.only(
                                                          left: 16,
                                                          right: 16,
                                                          top: 20,
                                                          bottom:
                                                              MediaQuery.of(
                                                                    context,
                                                                  )
                                                                  .viewInsets
                                                                  .bottom +
                                                              20,
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "Set Offer Prices",
                                                              style:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .headlineSmall,
                                                            ),
                                                            SizedBox(
                                                              height: 15,
                                                            ),
                                                            TextField(
                                                              controller:
                                                                  offerPriceController,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              decoration: InputDecoration(
                                                                labelText:
                                                                    "Offer Price",
                                                                border: OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: 15,
                                                            ),
                                                            TextField(
                                                              controller:
                                                                  hypermarketPriceController,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              decoration: InputDecoration(
                                                                labelText:
                                                                    "Hypermarket Offer Price",
                                                                border: OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: 20,
                                                            ),
                                                            SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              child: ElevatedButton(
                                                                onPressed: () {
                                                                  final offerPrice =
                                                                      double.tryParse(
                                                                        offerPriceController
                                                                            .text,
                                                                      );
                                                                  final hyperPrice =
                                                                      double.tryParse(
                                                                        hypermarketPriceController
                                                                            .text,
                                                                      );

                                                                  if (offerPrice !=
                                                                          null ||
                                                                      hyperPrice !=
                                                                          null) {
                                                                    final provider =
                                                                        context
                                                                            .read<
                                                                              ProductProvider
                                                                            >();
                                                                    if (offerPrice !=
                                                                        null) {
                                                                      provider.setOfferPrice(
                                                                        products,
                                                                        offerPrice,
                                                                      );
                                                                    }
                                                                    if (hyperPrice !=
                                                                        null) {
                                                                      provider.setHyperMarketPrice(
                                                                        products,
                                                                        hyperPrice,
                                                                      );
                                                                    }
                                                                    Navigator.pop(
                                                                      context,
                                                                    );
                                                                  }
                                                                },
                                                                child: Text(
                                                                  "Save",
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      products.offerPrice ==
                                                              null
                                                          ?"Qr ${products.price
                                                                .toString()}"
                                                          : "Qr ${products.offerPrice
                                                                .toString()}",
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Colors.green,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      products.hyperMarketPrice ==
                                                              null
                                                          ? "Qr ${products.hyperMarket
                                                                .toString()}"
                                                          : "Qr ${products.hyperMarketPrice.toString()}",
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Colors.red,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // SizedBox(width: 10),
                                              // Text(
                                              //   products.offerPrice == null
                                              //       ? ""
                                              //       : "₹${products.offerPrice.toString()}",
                                              //   style: theme.textTheme.bodySmall
                                              //       ?.copyWith(
                                              //         color: Colors
                                              //             .red, // override color
                                              //       ),
                                              // ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductOptions(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text("Edit"),
                onTap: () {
                  Navigator.pop(context); // close bottom sheet
                  // Reset form and open AddProducts screen in edit mode
                  final productProvider = context.read<ProductProvider>();
                  // productProvider.setProductForEdit(product);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProducts(product: product),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("Delete"),
                onTap: () {
                  Navigator.pop(context); // close bottom sheet
                  // Delete product
                  context.read<ProductProvider>().deleteProduct(product.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ImagePreviewPage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.memory(
                base64Decode(images[index]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
