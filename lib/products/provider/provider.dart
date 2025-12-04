// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';

// import 'package:archive/archive.dart';
// import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
// import 'package:excel/excel.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:products_catelogs/products/model/categories_model.dart';
// import 'package:products_catelogs/products/model/order_model.dart';
// import 'package:products_catelogs/products/model/product_model.dart';
// import 'package:products_catelogs/products/screen/bulk.dart';

// class ProductProvider extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String? selectedCategory;
//   String? selectedMarket;
//   String searchQuery = "";
//   String? expandedProductId;
//   List<String> selectedFilterCategories = [];
//   List<dynamic> images = [];

//   Product? _editingProduct;
//   final List<Product> _products = [];
//   final List<Order> _orders = [];
//   final List<Category> _categories = [];
//   final nameController = TextEditingController();
//   final itemCodeController = TextEditingController();
//   final priceController = TextEditingController();
//   final offerPriceController = TextEditingController();
//   final stockController = TextEditingController();
//   final unitController = TextEditingController();
//   final kgPriceController = TextEditingController();
//   final ctnPriceController = TextEditingController();
//   final pcsPriceController = TextEditingController();
//   final descriptionController = TextEditingController();
//   final hypermarketController = TextEditingController();
//   final marketController = TextEditingController();

//   List<Product> get products => List.unmodifiable(_products);
//   List<Order> get orders => List.unmodifiable(_orders);
//   List<Category> get categories => List.unmodifiable(_categories);

//   bool _isFormFilled = false;

//   double get totalOrderValue =>
//       _orders.fold(0.0, (sum, order) => sum + order.total);

//   List<Product> get filteredProducts {
//     return _products.where((p) {
//       final matchesSearch =
//           searchQuery.isEmpty ||
//           p.name.toLowerCase().contains(searchQuery.toLowerCase());
//       final matchesCategory =
//           selectedFilterCategories.isEmpty ||
//           selectedFilterCategories.contains(p.categoryId);
//       return matchesSearch && matchesCategory;
//     }).toList();
//   }

//   StreamSubscription<QuerySnapshot>? _productSub;
//   StreamSubscription<QuerySnapshot>? _ordersSub;
//   StreamSubscription<QuerySnapshot>? _categorySub;

//   DocumentSnapshot? _lastProductDoc;
//   bool _hasMoreProducts = true;
//   bool _isFetchingProducts = false;
//   bool get hasMore => _hasMoreProducts;

//   //. fecth products function in paginated
//   Future<void> fetchProductsPaginated() async {
//     if (_isFetchingProducts || !_hasMoreProducts) return;

//     try {
//       _isFetchingProducts = true;
//       _isFetchingProducts = true;
//       notifyListeners(); // To show loader in UI if required

//       Query query = _firestore
//           .collection('products')
//           .orderBy('name') // Change field if needed
//           .limit(10);

//       if (_lastProductDoc != null) {
//         query = query.startAfterDocument(_lastProductDoc!);
//       }

//       final snapshot = await query.get();

//       if (snapshot.docs.isNotEmpty) {
//         final newProducts = snapshot.docs
//             .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
//             .toList();

//         _products.addAll(newProducts);
//         _lastProductDoc = snapshot.docs.last;
//       }

//       if (snapshot.docs.length < 10) {
//         _hasMoreProducts = false;
//       }
//     } catch (error) {
//       log('❌ Pagination Fetch Error: $error');
//     } finally {
//       _isFetchingProducts = false;
//       notifyListeners();
//     }
//   }

//   //. reset products pagination
//   void resetProductsPagination() {
//     _products.clear();
//     _lastProductDoc = null;
//     _hasMoreProducts = true;
//   }

//   //. add products and save image link
//   Future<void> addProduct(Product product, List<dynamic> images) async {
//     try {
//       // 1️⃣ Upload images to Cloudinary
//       final imageUrls = await uploadMultipleImagesToCloudinary(images);

//       // 2️⃣ Create a new product with uploaded image URLs
//       final newProduct = product.copyWith(images: imageUrls);

//       // 3️⃣ Save to Firestore
//       await _firestore
//           .collection('products')
//           .doc(newProduct.id)
//           .set(newProduct.toMap());

//       notifyListeners();
//       log("✅ Product added successfully with Cloudinary images");
//     } catch (e, stack) {
//       log("❌ addProduct Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to add product");
//     }
//   }

//   //. upload multiple images to cloud
//   Future<List<String>> uploadMultipleImagesToCloudinary(
//     List<dynamic> imageFiles,
//   ) async {
//     log(imageFiles.length.toString());
//     final List<String> uploadedUrls = [];

//     for (final imageFile in imageFiles) {
//       final imageUrl = await uploadImageToCloudinary(imageFile);
//       if (imageUrl != null) {
//         uploadedUrls.add(imageUrl);
//       } else {
//         print('⚠️ Failed to upload one image');
//       }
//     }

//     return uploadedUrls;
//   }

//   //. upload image to cloud
//   Future<String?> uploadImageToCloudinary(File imageFile) async {
//     const cloudName = 'dmqmff4g4';
//     const uploadPreset = 'red_rose_contracting_w.l.l';

//     final url = Uri.parse(
//       'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
//     );

//     final request = http.MultipartRequest('POST', url)
//       ..fields['upload_preset'] = uploadPreset
//       ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

//     final response = await request.send();

//     if (response.statusCode == 200) {
//       final responseData = await response.stream.bytesToString();
//       final decoded = json.decode(responseData);
//       return decoded['secure_url']; // ✅ return image URL
//     } else {
//       print('❌ Upload failed: ${response.statusCode}');
//       return null;
//     }
//   }

//   //. edit products
//   Future<void> editProduct(Product oldProduct, Product newProduct) async {
//     try {
//       await _firestore
//           .collection('products')
//           .doc(oldProduct.id)
//           .update(newProduct.toMap());
//       // final index = _products.indexWhere((p) => p.id == oldProduct.id);
//       // if (index != -1) _products[index] = newProduct;

//       final index = _products.indexWhere((p) => p.id == newProduct.id);
//       if (index != -1) {
//         _products[index] = newProduct;
//       } else {
//         // Optional: if the product isn't found, add it (safety)
//         _products.add(newProduct);
//       }

//       // ✅ Notify listeners to update the UI immediately

//       notifyListeners();
//       log("✅ Product updated successfully");
//     } catch (e, stack) {
//       log("❌ editProduct Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to edit product");
//     }
//   }

//   //. delete products
//   Future<void> deleteProduct(String id) async {
//     try {
//       await _firestore.collection('products').doc(id).delete();
//       _products.removeWhere((p) => p.id == id);
//       notifyListeners();
//     } catch (e, stack) {
//       log("❌ deleteProduct Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to delete product");
//     }
//   }

//   //. set product availability
//   Future<void> toggleProductVisibility(String id, bool hide) async {
//     try {
//       await _firestore.collection('products').doc(id).set(
//         {
//           'isHidden': hide,
//           'updatedAt': FieldValue.serverTimestamp(), // optional
//         },
//         SetOptions(merge: true), // ✅ only updates the given fields
//       );

//       // update locally if you have the product in memory
//       final index = _products.indexWhere((p) => p.id == id);
//       if (index != -1) {
//         _products[index] = _products[index].copyWith(isHidden: hide);
//       }

//       notifyListeners();
//     } catch (e, stack) {
//       log("❌ toggleProductVisibility Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to update product visibility");
//     }
//   }

//   //. fecth categories
//   Future<void> fetchCategories() async {
//     try {
//       notifyListeners(); // optional if you want to show loader

//       final snapshot = await _firestore
//           .collection('categories')
//           .orderBy('name') // optional: ensures sorted results
//           .get();

//       _categories
//         ..clear()
//         ..addAll(
//           snapshot.docs.map(
//             (doc) => Category.fromMap(doc.data() as Map<String, dynamic>),
//           ),
//         );

//       notifyListeners(); // rebuild UI after data loads
//     } catch (error) {
//       log('❌ fetchCategories error: $error');
//     }
//   }

//   //.  set filter fr categories
//   void toggleFilterCategory(String categoryId) {
//     if (selectedFilterCategories.contains(categoryId)) {
//       selectedFilterCategories.remove(categoryId);
//     } else {
//       selectedFilterCategories.add(categoryId);
//     }
//     notifyListeners();
//   }

//   //.  set categories
//   void setCategory(String? categoryId) {
//     selectedCategory = categoryId;
//     notifyListeners();
//   }

//   //. set search query
//   void setSearchQuery(String query) {
//     searchQuery = query;
//     notifyListeners();
//   }

//   //. set market for add products
//   void setMarket(String? market) {
//     selectedMarket = market;
//     notifyListeners();
//   }

//   //. delete all orders
//   Future<void> deleteAllOrders() async {
//     try {
//       final snapshot = await _firestore.collection('orders').get();
//       final batch = _firestore.batch();
//       for (var doc in snapshot.docs) batch.delete(doc.reference);
//       await batch.commit();
//       _orders.clear();
//       notifyListeners();
//       log("✅ All orders deleted successfully");
//     } catch (e) {
//       log("❌ deleteAllOrders error: $e");
//     }
//   }

//   //. set offer price
//   Future<void> setOfferPrice(Product product, double? offerPrice) async {
//     await _updateProductField(product, {'offerPrice': offerPrice});
//   }

//   //. set hypermarket price
//   Future<void> setHyperMarketPrice(
//     Product product,
//     double? hyperMarketPrice,
//   ) async {
//     await _updateProductField(product, {'hyperMarketPrice': hyperMarketPrice});
//   }

//   //.  update products fields
//   Future<void> _updateProductField(
//     Product product,
//     Map<String, dynamic> fields,
//   ) async {
//     try {
//       await _firestore.collection('products').doc(product.id).update(fields);
//       final index = _products.indexWhere((p) => p.id == product.id);
//       if (index != -1) {
//         final existing = _products[index];
//         _products[index] = existing.copyWith(
//           offerPrice: fields['offerPrice'] ?? existing.offerPrice,
//           hyperMarketPrice:
//               fields['hyperMarketPrice'] ?? existing.hyperMarketPrice,
//         );
//       }
//       notifyListeners();
//     } catch (e, stack) {
//       log("❌ _updateProductField Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to update product field");
//     }
//   }

//   //. udpate products
//   void updateProduct(Product updatedProduct) {
//     // Find the product in the list
//     final index = products.indexWhere((p) => p.id == updatedProduct.id);

//     if (index != -1) {
//       products[index] = updatedProduct; // replace with the updated product
//       notifyListeners(); // tell Flutter to rebuild the UI
//     }
//   }

//   // Images functions
//   Future<void> pickImageFromCamera() async {
//     await _pickImage(ImageSource.camera);
//   }

//   Future<void> pickMultipleImages() async {
//     final picker = ImagePicker();
//     final pickedFiles = await picker.pickMultiImage();

//     if (pickedFiles != null) {
//       for (var xfile in pickedFiles) {
//         final file = File(xfile.path);
//         images.add(file);
//       }
//       notifyListeners();
//     }
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       final file = File(pickedFile.path);
//       images.add(file);

//       notifyListeners();
//     }
//   }

//   void addImage(File base64) {
//     images.add(base64);
//     notifyListeners();
//   }

//   void removeImageAt(int index, Product product) {
//     if (index < 0 || index >= images.length) return;

//     images.removeAt(index);
//     notifyListeners();
//   }

//   void removeImage(File image) {
//     images.remove(image);
//     notifyListeners();
//   }

//   void resetForm() {
//     images.clear();
//     nameController.clear();
//     itemCodeController.clear();
//     priceController.clear();
//     offerPriceController.clear();
//     stockController.clear();
//     unitController.clear();
//     kgPriceController.clear();
//     ctnPriceController.clear();
//     pcsPriceController.clear();
//     descriptionController.clear();
//     hypermarketController.clear();
//     marketController.clear();
//     selectedMarket = null;
//     selectedCategory = null;
//     _isFormFilled = false;
//     notifyListeners();
//   }

//   void loadProductForEditingOnce(Product product) {
//     if (_editingProduct?.id == product.id) return;

//     resetForm();

//     _editingProduct = product;
//     nameController.text = product.name;
//     itemCodeController.text = product.itemCode;
//     priceController.text = product.price.toString();
//     offerPriceController.text = product.offerPrice?.toString() ?? '';
//     stockController.text = product.stock.toString();
//     unitController.text = product.unit;
//     hypermarketController.text = product.hyperMarket?.toString() ?? '';
//     selectedMarket = product.market;
//     selectedCategory = product.categoryId;
//     descriptionController.text = product.description;
//     kgPriceController.text = product.kgPrice?.toString() ?? '';
//     ctnPriceController.text = product.ctrPrice?.toString() ?? '';
//     pcsPriceController.text = product.pcsPrice?.toString() ?? '';

//     // ✅ Only store existing image URLs
//     images = List<dynamic>.from(product.images);

//     notifyListeners();
//   }

//   Future<void> saveEditedProductDirect(Product updatedProduct) async {
//     // Separate images
//     final List<File> newImages = images.whereType<File>().toList();
//     final List<String> existingUrls = images.whereType<String>().toList();

//     List<String> finalImageUrls = existingUrls;

//     if (newImages.isNotEmpty) {
//       final uploadedUrls = await uploadMultipleImagesToCloudinary(newImages);
//       finalImageUrls = [...existingUrls, ...uploadedUrls];
//     }

//     final productToSave = updatedProduct.copyWith(images: finalImageUrls);

//     await editProduct(updatedProduct, productToSave);

//     resetForm();
//     _editingProduct = null;
//   }

// Future<void> bulkUploadFromZip() async {
//   if (_isFetchingProducts) return;

//   try {
//     _isFetchingProducts = true;
//     notifyListeners();

//     // 1️⃣ Pick ZIP file
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['zip'],
//     );

//     if (result == null || result.files.isEmpty) return;
//     final zipFile = File(result.files.single.path!);

//     final bytes = await zipFile.readAsBytes();
//     final archive = ZipDecoder().decodeBytes(bytes);

//     File? excelFile;
//     final Map<String, File> imageFiles = {};

//     // 2️⃣ Extract Excel & Images folder
//     for (final file in archive) {
//       if (file.isFile) {
//         final fileName = file.name.split('/').last;

//         if (fileName.endsWith('.xlsx')) {
//           excelFile = File('${zipFile.parent.path}/$fileName')
//             ..writeAsBytesSync(file.content as List<int>);
//         }

//         if (file.name.toLowerCase().startsWith('images/')) {
//           final imgFile = File('${zipFile.parent.path}/$fileName')
//             ..writeAsBytesSync(file.content as List<int>);
//           imageFiles[fileName.toLowerCase()] = imgFile;
//         }
//       }
//     }

//     if (excelFile == null) throw Exception("❌ products.xlsx not found in ZIP");

//     // 3️⃣ Read Excel
//     final excelBytes = excelFile.readAsBytesSync();
//     final excel = Excel.decodeBytes(excelBytes);
//     final sheet = excel.tables.values.first;

//     List<Product> newProducts = [];

//     // 4️⃣ Read each row & match images
//     for (int i = 1; i < sheet.rows.length; i++) {
//       final row = sheet.rows[i];

//       String parse(dynamic v) => v?.value?.toString() ?? '';
//       double? toDouble(dynamic v) =>
//           v?.value is num ? (v!.value as num).toDouble() : double.tryParse(parse(v));
//       int toInt(dynamic v) =>
//           v?.value is num ? (v!.value as num).toInt() : int.tryParse(parse(v)) ?? 0;

//       final itemCode = parse(row[1]);

//       // Match all images that contain itemCode in filename
//       final matchedImages = imageFiles.entries
//           .where((entry) => entry.key.contains(itemCode.toLowerCase()))
//           .map((entry) => entry.value)
//           .toList();

//       // Upload images & store URLs
//       List<String> uploadedImageUrls = [];
//       for (final img in matchedImages) {
//         final url = await uploadImageToCloudinary(img);
//         if (url != null) uploadedImageUrls.add(url);
//       }

//       // Create Product object
//       final product = Product(
//         id: itemCode,
//         name: parse(row[0]),
//         itemCode: itemCode,
//         price: toDouble(row[2]) ?? 0.0,
//         offerPrice: toDouble(row[3]),
//         unit: parse(row[4]),
//         stock: toInt(row[5]),
//         description: parse(row[6]),
//         categoryId: parse(row[7]),
//         market: parse(row[8]),
//         hyperMarket: toDouble(row[9]),
//         hyperMarketPrice: toDouble(row[10]),
//         pcsPrice: toDouble(row[11]),
//         kgPrice: toDouble(row[12]),
//         ctrPrice: toDouble(row[13]),
//         images: uploadedImageUrls,
//       );

//       newProducts.add(product);
//     }

//     // 5️⃣ Save to Firestore using batch
//     final WriteBatch batch = _firestore.batch();

//     for (final p in newProducts) {
//       final docRef = _firestore.collection("products").doc(p.id);
//       batch.set(docRef, p.toMap());
//     }

//     await batch.commit();
//     log("✅ Bulk upload completed!");
//   } catch (e, s) {
//     log("❌ bulkUpload Error: $e");
//     log(s.toString());
//     throw Exception("Bulk upload failed");
//   } finally {
//     _isFetchingProducts = false;
//     notifyListeners();
//   }
// }

// }
