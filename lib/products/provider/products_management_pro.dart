import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class Category {
  String id;
  String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {"id": id, "name": name};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map["id"] ?? "", name: map["name"] ?? "");
  }
}

class Order {
  final String orderId;
  final String salesManId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;
  final DateTime? timestamp;
  final String color; // new field
  final String buyer; // new field

  Order({
    required this.orderId,
    required this.salesManId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
    this.timestamp,
    required this.color,
    required this.buyer,
  });

  // Convert Firestore document -> Order model
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      orderId: map['orderId'] ?? "",
      salesManId: map['salesManId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      total: (map['total'] ?? 0).toDouble(),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      color: map['color'] ?? '', // new field mapping
      buyer: map['buyer'] ?? '', // new field mapping
    );
  }

  // Convert Order model -> Firestore document
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'salesManId': salesManId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'color': color, // new field
      'buyer': buyer, // new field
    };
  }
}

class Product {
  String id;
  String name;
  double price; // original price
  double? offerPrice; // ✅ optional offer price
  String unit;
  int stock;
  String description;
  List<String> images;
  String categoryId;
  double? hyperMarket; // ✅ maybe used as hyper price reference
  String market;
  String itemCode;
  double? hyperMarketPrice; // ✅ actual Hyper Market offer price
  double? kgPrice;
  double? ctrPrice;
  double? pcsPrice;
  bool isHidden;

  Product({
    required this.itemCode,
    required this.market,
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    required this.unit,
    required this.stock,
    required this.description,
    required this.images,
    required this.categoryId,
    this.hyperMarket,
    this.hyperMarketPrice,
    this.kgPrice,
    this.ctrPrice,
    this.pcsPrice,
    this.isHidden = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemCode': itemCode,
      'market': market,
      'hyperPrice': hyperMarket, // keep key consistent
      'id': id,
      'name': name,
      'price': price,
      'offerPrice': offerPrice,
      'unit': unit,
      'stock': stock,
      'description': description,
      'images': images,
      'categoryId': categoryId,
      'hyperMarketPrice': hyperMarketPrice,
      'kgPrice': kgPrice,
      'ctrPrice': ctrPrice,
      'pcsPrice': pcsPrice,
      'isHidden': isHidden,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return Product(
      itemCode: map['itemCode'] ?? "",
      market: map['market'] ?? "",
      hyperMarket: parseDouble(map['hyperPrice']),
      hyperMarketPrice: parseDouble(map['hyperMarketPrice']),
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: parseDouble(map['price']) ?? 0.0,
      offerPrice: parseDouble(map['offerPrice']),
      unit: map['unit'] ?? '',
      stock: parseInt(map['stock']),
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['categoryId'] ?? '',
      kgPrice: parseDouble(map['kgPrice']),
      ctrPrice: parseDouble(map['ctrPrice']),
      pcsPrice: parseDouble(map['pcsPrice']),
      isHidden: (map['isHidden'] != null && map['isHidden'] is bool)
          ? map['isHidden'] as bool
          : false,
    );
  }
  Product copyWith({
    String? id,
    String? name,
    String? itemCode,
    double? price,
    double? offerPrice,
    String? unit,
    int? stock,
    String? description,
    List<String>? images,
    String? categoryId,
    double? hyperMarket,
    double? hyperMarketPrice,
    String? market,
    double? kgPrice,
    double? ctrPrice,
    double? pcsPrice,
    bool? isHidden, // ✅ new field
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      itemCode: itemCode ?? this.itemCode,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      images: images ?? List<String>.from(this.images),
      categoryId: categoryId ?? this.categoryId,
      hyperMarket: hyperMarket ?? this.hyperMarket,
      hyperMarketPrice: hyperMarketPrice ?? this.hyperMarketPrice,
      market: market ?? this.market,
      kgPrice: kgPrice ?? this.kgPrice,
      ctrPrice: ctrPrice ?? this.ctrPrice,
      pcsPrice: pcsPrice ?? this.pcsPrice,
      isHidden: isHidden ?? this.isHidden, // ✅ updated copy
    );
  }
}

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------- STATE -------------------
  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<Category> _categories = [];
  List<dynamic> images = [];

  Product? _editingProduct;

  // Form Controllers
  final nameController = TextEditingController();
  final itemCodeController = TextEditingController();
  final priceController = TextEditingController();
  final offerPriceController = TextEditingController();
  final stockController = TextEditingController();
  final unitController = TextEditingController();
  final kgPriceController = TextEditingController();
  final ctnPriceController = TextEditingController();
  final pcsPriceController = TextEditingController();
  final descriptionController = TextEditingController();
  final hypermarketController = TextEditingController();
  final marketController = TextEditingController();

  String? selectedCategory;
  String? selectedMarket;
  String searchQuery = "";
  String? expandedProductId;
  List<String> selectedFilterCategories = [];

  bool _isFormFilled = false;

  // ------------------- GETTERS -------------------
  List<Product> get products => List.unmodifiable(_products);
  List<Order> get orders => List.unmodifiable(_orders);
  List<Category> get categories => List.unmodifiable(_categories);

  double get totalOrderValue =>
      _orders.fold(0.0, (sum, order) => sum + order.total);

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch =
          searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedFilterCategories.isEmpty ||
          selectedFilterCategories.contains(p.categoryId);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ------------------- FIRESTORE SUBSCRIPTIONS -------------------
  StreamSubscription<QuerySnapshot>? _productSub;
  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _categorySub;

  // ------------------- INITIALIZER -------------------
  ProductProvider() {
    _listenProducts();
    _listenCategories();
    _listenOrders();
  }

  // ------------------- PRODUCTS -------------------
  void _listenProducts() {
    _productSub?.cancel();
    _productSub = _firestore.collection('products').snapshots().listen((
      snapshot,
    ) {
      bool hasChanged = false;

      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final product = Product.fromMap(data);

        switch (change.type) {
          case DocumentChangeType.added:
            _products.add(product);
            hasChanged = true;
            break;
          case DocumentChangeType.modified:
            final index = _products.indexWhere((p) => p.id == product.id);
            if (index != -1) {
              _products[index] = product;
              hasChanged = true;
            }
            break;
          case DocumentChangeType.removed:
            _products.removeWhere((p) => p.id == product.id);
            hasChanged = true;
            break;
        }
      }

      if (hasChanged) notifyListeners(); // ✅ only rebuild if something changed
    }, onError: (error) => log('❌ listenProducts error: $error'));
  }

  Future<void> addProduct(Product product, List<dynamic> images) async {
    try {
      // 1️⃣ Upload images to Cloudinary
      final imageUrls = await uploadMultipleImagesToCloudinary(images);

      // 2️⃣ Create a new product with uploaded image URLs
      final newProduct = product.copyWith(images: imageUrls);

      // 3️⃣ Save to Firestore
      await _firestore
          .collection('products')
          .doc(newProduct.id)
          .set(newProduct.toMap());

      notifyListeners();
      log("✅ Product added successfully with Cloudinary images");
    } catch (e, stack) {
      log("❌ addProduct Error: $e");
      log(stack.toString());
      throw Exception("Failed to add product");
    }
  }

  Future<void> editProduct(Product oldProduct, Product newProduct) async {
    try {
      await _firestore
          .collection('products')
          .doc(oldProduct.id)
          .update(newProduct.toMap());
      // final index = _products.indexWhere((p) => p.id == oldProduct.id);
      // if (index != -1) _products[index] = newProduct;

      final index = _products.indexWhere((p) => p.id == newProduct.id);
      if (index != -1) {
        _products[index] = newProduct;
      } else {
        // Optional: if the product isn't found, add it (safety)
        _products.add(newProduct);
      }

      // ✅ Notify listeners to update the UI immediately

      notifyListeners();
      log("✅ Product updated successfully");
    } catch (e, stack) {
      log("❌ editProduct Error: $e");
      log(stack.toString());
      throw Exception("Failed to edit product");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e, stack) {
      log("❌ deleteProduct Error: $e");
      log(stack.toString());
      throw Exception("Failed to delete product");
    }
  }

  Future<void> toggleProductVisibility(String id, bool hide) async {
    try {
      await _firestore.collection('products').doc(id).set(
        {
          'isHidden': hide,
          'updatedAt': FieldValue.serverTimestamp(), // optional
        },
        SetOptions(merge: true), // ✅ only updates the given fields
      );

      // update locally if you have the product in memory
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isHidden: hide);
      }

      notifyListeners();
    } catch (e, stack) {
      log("❌ toggleProductVisibility Error: $e");
      log(stack.toString());
      throw Exception("Failed to update product visibility");
    }
  }

  void toggleExpanded(String productId) {
    expandedProductId = expandedProductId == productId ? null : productId;
    notifyListeners();
  }

  // ------------------- CATEGORIES -------------------
  void _listenCategories() {
    _categorySub?.cancel();
    _categorySub = _firestore.collection('categories').snapshots().listen((
      snapshot,
    ) {
      _categories
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Category.fromMap(doc.data())));
      notifyListeners();
    }, onError: (error) => log('❌ listenCategories error: $error'));
  }

  void toggleFilterCategory(String categoryId) {
    if (selectedFilterCategories.contains(categoryId)) {
      selectedFilterCategories.remove(categoryId);
    } else {
      selectedFilterCategories.add(categoryId);
    }
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    selectedCategory = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setMarket(String? market) {
    selectedMarket = market;
    notifyListeners();
  }

  // ------------------- ORDERS -------------------
  void _listenOrders() {
    _ordersSub?.cancel();
    _ordersSub = _firestore.collection('orders').snapshots().listen((snapshot) {
      _orders
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Order.fromMap(doc.data())));
      notifyListeners();
    }, onError: (error) => log('❌ listenOrders error: $error'));
  }

  Future<void> deleteAllOrders() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
      _orders.clear();
      notifyListeners();
      log("✅ All orders deleted successfully");
    } catch (e) {
      log("❌ deleteAllOrders error: $e");
    }
  }

  Future<void> setOfferPrice(Product product, double? offerPrice) async {
    await _updateProductField(product, {'offerPrice': offerPrice});
  }

  Future<void> setHyperMarketPrice(
    Product product,
    double? hyperMarketPrice,
  ) async {
    await _updateProductField(product, {'hyperMarketPrice': hyperMarketPrice});
  }

  Future<void> _updateProductField(
    Product product,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _firestore.collection('products').doc(product.id).update(fields);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        final existing = _products[index];
        _products[index] = existing.copyWith(
          offerPrice: fields['offerPrice'] ?? existing.offerPrice,
          hyperMarketPrice:
              fields['hyperMarketPrice'] ?? existing.hyperMarketPrice,
        );
      }
      notifyListeners();
    } catch (e, stack) {
      log("❌ _updateProductField Error: $e");
      log(stack.toString());
      throw Exception("Failed to update product field");
    }
  }

  void updateProduct(Product updatedProduct) {
    // Find the product in the list
    final index = products.indexWhere((p) => p.id == updatedProduct.id);

    if (index != -1) {
      products[index] = updatedProduct; // replace with the updated product
      notifyListeners(); // tell Flutter to rebuild the UI
    }
  }

  // ------------------- IMAGES -------------------
  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> pickMultipleImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      for (var xfile in pickedFiles) {
        final file = File(xfile.path);
        images.add(file);
      }
      notifyListeners();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      images.add(file);

      notifyListeners();
    }
  }

  void addImage(File base64) {
    images.add(base64);
    notifyListeners();
  }

  void removeImageAt(int index, Product product) {
    if (index < 0 || index >= images.length) return;

    images.removeAt(index);
    notifyListeners();
  }

  void removeImage(File image) {
    images.remove(image);
    notifyListeners();
  }

  // ------------------- FORM MANAGEMENT -------------------
  void resetForm() {
    images.clear();
    nameController.clear();
    itemCodeController.clear();
    priceController.clear();
    offerPriceController.clear();
    stockController.clear();
    unitController.clear();
    kgPriceController.clear();
    ctnPriceController.clear();
    pcsPriceController.clear();
    descriptionController.clear();
    hypermarketController.clear();
    marketController.clear();
    selectedMarket = null;
    selectedCategory = null;
    _isFormFilled = false;
    notifyListeners();
  }

  void loadProductForEditingOnce(Product product) {
    if (_editingProduct?.id == product.id) return;

    resetForm();

    _editingProduct = product;
    nameController.text = product.name;
    itemCodeController.text = product.itemCode;
    priceController.text = product.price.toString();
    offerPriceController.text = product.offerPrice?.toString() ?? '';
    stockController.text = product.stock.toString();
    unitController.text = product.unit;
    hypermarketController.text = product.hyperMarket?.toString() ?? '';
    selectedMarket = product.market;
    selectedCategory = product.categoryId;
    descriptionController.text = product.description;
    kgPriceController.text = product.kgPrice?.toString() ?? '';
    ctnPriceController.text = product.ctrPrice?.toString() ?? '';
    pcsPriceController.text = product.pcsPrice?.toString() ?? '';

    // ✅ Only store existing image URLs
    images = List<dynamic>.from(product.images);

    notifyListeners();
  }

  Future<void> saveEditedProductDirect(Product updatedProduct) async {
    // Separate images
    final List<File> newImages = images.whereType<File>().toList();
    final List<String> existingUrls = images.whereType<String>().toList();

    List<String> finalImageUrls = existingUrls;

    if (newImages.isNotEmpty) {
      final uploadedUrls = await uploadMultipleImagesToCloudinary(newImages);
      finalImageUrls = [...existingUrls, ...uploadedUrls];
    }

    final productToSave = updatedProduct.copyWith(images: finalImageUrls);

    await editProduct(updatedProduct, productToSave);

    resetForm();
    _editingProduct = null;
  }

  //   Future<void> saveEditedProduct(Product oldProduct) async {
  //     if (_editingProduct == null) return;

  //     final newProduct = Product(
  //       id: oldProduct.id,
  //       name: nameController.text.trim(),
  //       itemCode: itemCodeController.text.trim(),
  //       price: double.tryParse(priceController.text.trim()) ?? 0,
  //       offerPrice: double.tryParse(offerPriceController.text.trim()),
  //       stock: int.tryParse(stockController.text.trim()) ?? 0,
  //       unit: unitController.text.trim(),
  //       market: selectedMarket ?? "",
  //       hyperMarket: double.tryParse(hypermarketController.text.trim()) ?? 0,
  //       images: List<String>.from(images),
  //       categoryId: selectedCategory ?? "",
  //       description: descriptionController.text.trim(),
  //       kgPrice: double.tryParse(kgPriceController.text.trim()),
  //       ctrPrice: double.tryParse(ctnPriceController.text.trim()),
  //       pcsPrice: double.tryParse(pcsPriceController.text.trim()),
  //     );

  //     await editProduct(oldProduct, newProduct);

  //     // Ensure local list has updated images
  //     final index = _products.indexWhere((p) => p.id == newProduct.id);
  //     if (index != -1) {
  //       _products[index] = newProduct; // ✅ new images now in provider list
  //     }

  //     resetForm();
  //     _editingProduct = null;
  //   }

  // ------------------- CLEANUP -------------------
  @override
  void dispose() {
    _productSub?.cancel();
    _ordersSub?.cancel();
    _categorySub?.cancel();
    nameController.dispose();
    itemCodeController.dispose();
    priceController.dispose();
    offerPriceController.dispose();
    stockController.dispose();
    unitController.dispose();
    kgPriceController.dispose();
    ctnPriceController.dispose();
    pcsPriceController.dispose();
    descriptionController.dispose();
    hypermarketController.dispose();
    marketController.dispose();
    super.dispose();
  }

  Future<List<String>> uploadMultipleImagesToCloudinary(
    List<dynamic> imageFiles,
  ) async {
    log(imageFiles.length.toString());
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      final imageUrl = await uploadImageToCloudinary(imageFile);
      if (imageUrl != null) {
        uploadedUrls.add(imageUrl);
      } else {
        print('⚠️ Failed to upload one image');
      }
    }

    return uploadedUrls;
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dmqmff4g4';
    const uploadPreset = 'red_rose_contracting_w.l.l';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final decoded = json.decode(responseData);
      return decoded['secure_url']; // ✅ return image URL
    } else {
      print('❌ Upload failed: ${response.statusCode}');
      return null;
    }
  }
}
