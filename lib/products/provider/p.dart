// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
// import 'package:image_picker/image_picker.dart';

// class Product {
//   String id;
//   String name;
//   double price; // original price
//   double? offerPrice; // ✅ new field (nullable)
//   String unit;
//   int stock;
//   String description;
//   List<String> images;
//   String categoryId;

//   Product({
//     required this.id,
//     required this.name,
//     required this.price,
//     this.offerPrice,
//     required this.unit,
//     required this.stock,
//     required this.description,
//     required this.images,
//     required this.categoryId,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'price': price,
//       'offerPrice': offerPrice, // ✅ save offer price too
//       'unit': unit,
//       'stock': stock,
//       'description': description,
//       'images': images,
//       'categoryId': categoryId,
//     };
//   }

//   factory Product.fromMap(Map<String, dynamic> map) {
//     return Product(
//       id: map['id'] ?? '',
//       name: map['name'] ?? '',
//       price: (map['price'] ?? 0).toDouble(),
//       offerPrice: map['offerPrice'] != null
//           ? (map['offerPrice'] as num).toDouble()
//           : null, // ✅ load offer price if exists
//       unit: map['unit'] ?? '',
//       stock: map['stock'] ?? 0,
//       description: map['description'] ?? '',
//       images: List<String>.from(map['images'] ?? []),
//       categoryId: map['categoryId'] ?? '',
//     );
//   }
// }

// class ProductProvider extends ChangeNotifier {
//   ProductProvider() {
//     fetchProducts();
//   }

//   // --- Form controllers ---
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController unitController = TextEditingController();
//   final TextEditingController descController = TextEditingController();
//   final TextEditingController stockController = TextEditingController();

//   // --- Local state ---
//   final List<Product> _products = [];
//   final Set<String> _selectedIds = {}; // ✅ selection state only
//   List<String> images = [];
//   bool _isFetched = false;
//   bool _isFormFilled = false;
//   String? selectedCategory  ;
//    String? selectedCategoryfor = "All";
//   String base64Image = '';

//   String _searchQuery = "";

//   bool _isGridView = true;

//   String get searchQuery => _searchQuery;

//   bool get isGridView => _isGridView;

//   void setSearchQuery(String value) {
//     _searchQuery = value;
//     notifyListeners();
//   }

//   void setSelectedCategory(String category) {
//     selectedCategoryfor = category;
//     notifyListeners();
//   }

//   void toggleGridView() {
//     _isGridView = !_isGridView;
//     notifyListeners();
//   }

//   // --- Filtered products ---
//   List<Product> get filteredProducts {
//     return _products.where((product) {
//       final matchesSearch = product.name.toLowerCase().contains(
//         _searchQuery.toLowerCase(),
//       );
//       final matchesCategory =
//           selectedCategoryfor == "All" || product.categoryId == selectedCategoryfor;
//       return matchesSearch && matchesCategory;
//     }).toList();
//   }

//   List<Product> get products => List.unmodifiable(_products);

//   // --- Form handling ---
//   void fillFormOnce(Product? product) {
//     if (!_isFormFilled && product != null) {
//       nameController.text = product.name;
//       priceController.text = product.price.toString();
//       unitController.text = product.unit;
//       stockController.text = product.stock.toString();
//       descController.text = product.description;
//       images = List<String>.from(product.images);
//       selectedCategory = product.categoryId;
//       _isFormFilled = true;
//       notifyListeners();
//     }
//   }

//   void resetForm() {
//     images.clear();

//     nameController.clear();
//     priceController.clear();
//     unitController.clear();
//     descController.clear();
//     stockController.clear();
//     _isFormFilled = false;
//     notifyListeners();
//   }

//   // --- Firestore operations ---
//   Future<void> fetchProducts({bool forceRefresh = false}) async {
//     if (_isFetched && !forceRefresh) return;
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('products')
//           .get();
//       _products
//         ..clear()
//         ..addAll(snapshot.docs.map((doc) => Product.fromMap(doc.data())));
//       _isFetched = true;
//       notifyListeners();
//     } catch (e, stack) {
//       log("Firestore fetchProducts Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to fetch products");
//     }
//   }

//   Future<void> addProduct(Product product) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('products')
//           .doc(product.id)
//           .set(product.toMap());
//       _products.add(product);
//       notifyListeners();
//     } catch (e, stack) {
//       log("Firestore addProduct Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to add product");
//     }
//   }

//   Future<void> editProduct(Product oldProduct, Product newProduct) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('products')
//           .doc(oldProduct.id)
//           .update(newProduct.toMap());
//       final index = _products.indexWhere((p) => p.id == oldProduct.id);
//       if (index != -1) {
//         _products[index] = newProduct;
//       }
//       resetForm();
//       notifyListeners();
//     } catch (e, stack) {
//       log("Firestore editProduct Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to edit product");
//     }
//   }

// Future<void> deleteProduct(String id) async {
//   try {
//     // Delete the document from Firestore
//     await FirebaseFirestore.instance.collection('products').doc(id).delete();

//     // Remove the product from your local list
//     _products.removeWhere((p) => p.id == id);

//     // Optional: remove from selected IDs if you use it elsewhere
//     _selectedIds.remove(id);

//     // Notify listeners to update the UI
//     notifyListeners();
//   } catch (e, stack) {
//     log("Firestore deleteProduct Error: $e");
//     log(stack.toString());
//     throw Exception("Failed to delete product");
//   }
// }


//   // --- Selection logic ---
//   bool isSelected(Product product) => _selectedIds.contains(product.id);

//   void toggleSelection(Product product, bool selected) {
//     if (selected) {
//       _selectedIds.add(product.id);
//     } else {
//       _selectedIds.remove(product.id);
//     }
//     notifyListeners();
//   }

//   void clearSelection() {
//     _selectedIds.clear();
//     notifyListeners();
//   }

//   List<Product> get selectedProducts =>
//       _products.where((p) => _selectedIds.contains(p.id)).toList();

//   bool get hasSelection => _selectedIds.isNotEmpty;
//   int get selectedCount => _selectedIds.length;

//   // --- Image helpers ---
//   Future<String> pickImageAsBase64({
//     ImageSource source = ImageSource.gallery,
//     int maxWidth = 400,
//     int maxHeight = 400,
//     int quality = 50,
//   }) async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: source);

//     if (pickedFile != null) {
//       final bytes = await File(pickedFile.path).readAsBytes();
//       final image = img.decodeImage(bytes);
//       if (image == null) return '';
//       final resized = img.copyResize(image, width: maxWidth, height: maxHeight);
//       final compressedBytes = img.encodeJpg(resized, quality: quality);
//       return base64Encode(compressedBytes);
//     }
//     return '';
//   }

//   Future<void> pickMultipleImages() async {
//     final picker = ImagePicker();
//     final pickedFiles = await picker.pickMultiImage(imageQuality: 50);

//     if (pickedFiles != null) {
//       for (var file in pickedFiles) {
//         final bytes = await File(file.path).readAsBytes();
//         final image = img.decodeImage(bytes);
//         if (image != null) {
//           final resized = img.copyResize(image, width: 400, height: 400);
//           final compressedBytes = img.encodeJpg(resized, quality: 50);
//           images.add(base64Encode(compressedBytes));
//         }
//       }
//       notifyListeners();
//     }
//   }

//   Future<void> pickImageFromCamera() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(
//       source: ImageSource.camera,
//       imageQuality: 50,
//     );
//     if (pickedFile != null) {
//       final bytes = await File(pickedFile.path).readAsBytes();
//       final image = img.decodeImage(bytes);
//       if (image != null) {
//         final resized = img.copyResize(image, width: 400, height: 400);
//         final compressedBytes = img.encodeJpg(resized, quality: 50);
//         images.add(base64Encode(compressedBytes));
//         notifyListeners();
//       }
//     }
//   }

//   Future<void> setOfferPrice(Product product, double? offerPrice) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('products')
//           .doc(product.id)
//           .update({'offerPrice': offerPrice});

//       final index = _products.indexWhere((p) => p.id == product.id);
//       if (index != -1) {
//         _products[index] = Product(
//           id: product.id,
//           name: product.name,
//           price: product.price,
//           offerPrice: offerPrice, // ✅ updated field
//           unit: product.unit,
//           stock: product.stock,
//           description: product.description,
//           images: product.images,
//           categoryId: product.categoryId,
//         );
//       }

//       notifyListeners();
//     } catch (e, stack) {
//       log("Firestore setOfferPrice Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to set offer price");
//     }
//   }

//   void addImage(String base64) {
//     images.add(base64);
//     notifyListeners();
//   }

//   void removeImageAt(int index) {
//     images.removeAt(index);
//     notifyListeners();
//   }



//   void disposeControllers() {
//     nameController.dispose();
//     priceController.dispose();
//     unitController.dispose();
//     descController.dispose();
//     stockController.dispose();
//   }
//   Future<void> deleteSingle(String id) async {
//   try {
//     await FirebaseFirestore.instance.collection('products').doc(id).delete();
//     _products.removeWhere((p) => p.id == id);
//     notifyListeners();
//   } catch (e) {
//     log("Firestore deleteSingle Error: $e");
//     throw Exception("Failed to delete product");
//   }
// }

// }
