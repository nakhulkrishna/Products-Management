// import 'dart:convert';
// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:products_catelogs/categories/provider/category_provider.dart';
// import 'package:products_catelogs/products/provider/products_management.dart';
// import 'package:provider/provider.dart';

// class EditProducts extends StatelessWidget {
//   final Product? product;

//   const EditProducts({super.key, this.product});

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<ProductProvider>(context);

//     // Prefill form after first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       provider.fillFormOnce(product);
//     });
//     Future<void> updateProduct() async {
//       if (provider.nameController.text.isEmpty ||
//           provider.priceController.text.isEmpty ||
//           provider.unitController.text.isEmpty ||
//           provider.selectedCategory == null ||
//           provider.images.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please fill all required fields")),
//         );
//         return;
//       }

//       final newProduct = Product(
//         id: product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
//         name: provider.nameController.text.trim(),
//         price: double.tryParse(provider.priceController.text.trim()) ?? 0,
//         unit: provider.unitController.text.trim(),
//         stock: int.tryParse(provider.stockController.text.trim()) ?? 0,
//         description: provider.descController.text.trim(),
//         images: List<String>.from(provider.images),
//         categoryId: provider.selectedCategory ?? '',
//       );

//       await provider.editProduct(product!, newProduct);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Product updated successfully")),
//       );

//       log("calling reset form");
//       provider.resetForm();
//       log("called  reset form");
//       Navigator.pop(context);
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text("Edit Product")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// 🔹 Image Picker
//               Center(
//                 child: GestureDetector(
//                   onTap: () => _showImageSourceDialog(context, provider),
//                   child: SizedBox(
//                     height: 120,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount:
//                           provider.images.length + 1, // +1 for add button
//                       itemBuilder: (context, index) {
//                         if (index == provider.images.length) {
//                           // Add image button
//                           return Container(
//                             width: 120,
//                             margin: const EdgeInsets.only(right: 8),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade200,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.grey.shade400),
//                             ),
//                             child: Icon(
//                               Iconsax.add,
//                               size: 40,
//                               color: Colors.grey,
//                             ),
//                           );
//                         } else {
//                           // Show existing images
//                           return Stack(
//                             children: [
//                               Container(
//                                 width: 120,
//                                 margin: const EdgeInsets.only(right: 8),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: Colors.grey.shade400,
//                                   ),
//                                 ),
//                                 child: Image.memory(
//                                   base64Decode(provider.images[index]),
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                               Positioned(
//                                 top: 4,
//                                 right: 4,
//                                 child: GestureDetector(
//                                   onTap: () => provider.removeImageAt(index),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       color: Colors.black54,
//                                     ),
//                                     child: const Icon(
//                                       Icons.close,
//                                       size: 20,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               /// 🔹 Product Name
//               _buildLabel("Product Name"),
//               _buildTextField(
//                 provider.nameController,
//                 "Enter product name",
//                 prefix: Iconsax.box,
//               ),
//               const SizedBox(height: 16),

//               /// 🔹 Price
//               _buildLabel("Price"),
//               _buildTextField(
//                 provider.priceController,
//                 "Enter price",
//                 prefix: Iconsax.money,
//                 isNumber: true,
//               ),
//               const SizedBox(height: 16),

//               /// 🔹 Unit
//               _buildLabel("Unit"),
//               _buildTextField(
//                 provider.unitController,
//                 "e.g. kg, litre, piece",
//                 prefix: Iconsax.weight,
//               ),
//               const SizedBox(height: 16),

//               /// 🔹 Stock Quantity
//               _buildLabel("Stock Quantity"),
//               _buildTextField(
//                 provider.stockController,
//                 "Enter stock quantity",
//                 prefix: Iconsax.box,
//                 isNumber: true,
//               ),
//               const SizedBox(height: 16),

//               /// 🔹 Description
//               _buildLabel("Description"),
//               TextField(
//                 controller: provider.descController,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: "Enter product description",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               /// 🔹 Category Dropdown
//               _buildLabel("Category"),
//               const SizedBox(height: 8),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade400),
//                 ),
//                 child: Consumer<CategoryProvider>(
//                   builder: (context, categoryProvider, _) {
//                     final categories = categoryProvider.categories;
//                     if (categories.isEmpty) {
//                       return const Padding(
//                         padding: EdgeInsets.all(12.0),
//                         child: Text("No categories found. Please add one."),
//                       );
//                     }
//                     return DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         hint: const Text("Select category"),
//                         value: provider.selectedCategory,
//                         items: categories.map((cat) {
//                           return DropdownMenuItem(
//                             value: cat.name,
//                             child: Text(cat.name),
//                           );
//                         }).toList(),
//                         onChanged: provider.setCategory,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 32),

//               /// 🔹 Save Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton.icon(
//                   onPressed: updateProduct,
//                   icon: Icon(Iconsax.document_upload, color: Colors.black),
//                   label: Text(
//                     "Update Product",
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey.shade100,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLabel(String text) => Padding(
//     padding: const EdgeInsets.only(bottom: 8),
//     child: Text(
//       text,
//       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//     ),
//   );

//   Widget _buildTextField(
//     TextEditingController controller,
//     String hint, {
//     IconData? prefix,
//     bool isNumber = false,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         hintText: hint,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         prefixIcon: prefix != null ? Icon(prefix) : null,
//       ),
//     );
//   }
// }

// void _showImageSourceDialog(BuildContext context, ProductProvider provider) {
//   showModalBottomSheet(
//     context: context,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//     ),
//     builder: (_) => Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             leading: const Icon(Iconsax.gallery),
//             title: const Text("Pick from Gallery"),
//             onTap: () {
//               Navigator.pop(context);
//               provider.pickMultipleImages();
//             },
//           ),
//           ListTile(
//             leading: const Icon(Iconsax.camera),
//             title: const Text("Take a Photo"),
//             onTap: () {
//               Navigator.pop(context);
//               provider.pickImageFromCamera();
//             },
//           ),
//         ],
//       ),
//     ),
//   );
// }
