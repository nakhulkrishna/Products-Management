import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

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

//   Future<void> deleteSelected() async {
//     try {
//       final batch = FirebaseFirestore.instance.batch();
//       for (var id in _selectedIds) {
//         batch.delete(FirebaseFirestore.instance.collection('products').doc(id));
//       }
//       await batch.commit();
//       _products.removeWhere((p) => _selectedIds.contains(p.id));
//       _selectedIds.clear();
//       notifyListeners();
//     } catch (e, stack) {
//       log("Firestore deleteSelected Error: $e");
//       log(stack.toString());
//       throw Exception("Failed to delete products");
//     }
//   }

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
    );
  }
}

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProductProvider() {
    listenProducts();
    listenCategories();
    listenOrders();
  }

  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<Category> _categories = [];
  List<String> images = [];
  bool _isFormFilled = false;

  List<Product> get products => List.unmodifiable(_products);
  List<Order> get orders => List.unmodifiable(_orders);
  List<Category> get categories => List.unmodifiable(_categories);

  double get totalOrderValue {
    return _orders.fold(0.0, (sum, order) => sum + order.total);
  }

  String searchQuery = "";
  String? selectedCategory;
  String? expandedProductId;

  final TextEditingController nameController = TextEditingController();

  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController offerPriceController = TextEditingController();
  final TextEditingController hypermarketController = TextEditingController();

  final marketController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedMarket; // Add this for the dropdown market selection

  // Existing methods...

  // Setter for market
  void setMarket(String? market) {
    selectedMarket = market;
    notifyListeners();
  }



  void resetForm() {
    images.clear();
    hypermarketController.clear();
    nameController.clear();
    priceController.clear();
    unitController.clear();
    descController.clear();
    stockController.clear();
    selectedMarket = null; // reset market
    _isFormFilled = false;
    notifyListeners();
  }

  StreamSubscription? _productSub;
  StreamSubscription? _ordersSub;
  StreamSubscription? _categorySub;

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    selectedCategory = categoryId;
    notifyListeners();
  }

  void toggleExpanded(String productId) {
    if (expandedProductId == productId) {
      expandedProductId = null;
    } else {
      expandedProductId = productId;
    }
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners(); // triggers UI rebuild for filteredProducts
  }

  List<String> selectedFilterCategories = [];

  void toggleFilterCategory(String categoryId) {
    if (selectedFilterCategories.contains(categoryId)) {
      selectedFilterCategories.remove(categoryId);
    } else {
      selectedFilterCategories.add(categoryId);
    }
    notifyListeners();
  }

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

  void listenProducts() {

    _productSub = _firestore.collection('products').snapshots().listen((
      snapshot,
    ) {
      _products
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Product.fromMap(doc.data())));
      notifyListeners();
    });
  }

  void cancelProductListener() {
    _productSub?.cancel();
    _productSub = null;
  }

  void listenOrders() {
    _ordersSub?.cancel(); // prevent duplicate listeners
    _ordersSub = _firestore.collection('orders').snapshots().listen((snapshot) {
      _orders
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Order.fromMap(doc.data())));
      notifyListeners();
    });
  }

  Future<void> addProduct(Product product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .set(product.toMap());
      // _products.add(product);
      notifyListeners();
    } catch (e, stack) {
      log("Firestore addProduct Error: $e");
      log(stack.toString());
      throw Exception("Failed to add product");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      // Delete the document from Firestore
      await FirebaseFirestore.instance.collection('products').doc(id).delete();

      // Remove the product from your local list
      _products.removeWhere((p) => p.id == id);

      // Notify listeners to update the UI
      notifyListeners();
    } catch (e, stack) {
      log("Firestore deleteProduct Error: $e");
      log(stack.toString());
      throw Exception("Failed to delete product");
    }
  }

  /// -------------------------------
  /// LIVE LISTEN TO CATEGORIES
  /// -------------------------------
  void listenCategories() {
    _categorySub?.cancel();
    _categorySub = _firestore.collection('categories').snapshots().listen((
      snapshot,
    ) {
      _categories
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Category.fromMap(doc.data())));
      notifyListeners();
    });
  }

  Future<String> pickImageAsBase64({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 400,
    int maxHeight = 400,
    int quality = 50,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return '';
      final resized = img.copyResize(image, width: maxWidth, height: maxHeight);
      final compressedBytes = img.encodeJpg(resized, quality: quality);
      return base64Encode(compressedBytes);
    }
    return '';
  }

  Future<void> setOfferPrice(Product product, double? offerPrice) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update({'offerPrice': offerPrice});

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = Product(
          itemCode: product.itemCode,
          market: product.market,
          id: product.id,
          name: product.name,
          price: product.price,
          offerPrice: offerPrice, // ✅ updated field
          unit: product.unit,
          stock: product.stock,
          description: product.description,
          images: product.images,
          categoryId: product.categoryId,
        );
      }

      notifyListeners();
    } catch (e, stack) {
      log("Firestore setOfferPrice Error: $e");
      log(stack.toString());
      throw Exception("Failed to set offer price");
    }
  }

  Future<void> setHyperMarketPrice(Product product, double? hyperMarketPrice) async {
  try {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .update({'hyperMarketPrice': hyperMarketPrice});

    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = Product(
        itemCode: product.itemCode,
        market: product.market,
        id: product.id,
        name: product.name,
        price: product.price,
        offerPrice: product.offerPrice,
        unit: product.unit,
        stock: product.stock,
        description: product.description,
        images: product.images,
        categoryId: product.categoryId,
        hyperMarket: product.hyperMarket,
        hyperMarketPrice: hyperMarketPrice, // ✅ update field
      );
    }

    notifyListeners();
    log("✅ HyperMarket price updated successfully");
  } catch (e, stack) {
    log("❌ Firestore setHyperMarketPrice Error: $e");
    log(stack.toString());
    throw Exception("Failed to set hypermarket price");
  }
}


  Future<void> pickMultipleImages(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 50);

    if (pickedFiles != null) {
      for (var file in pickedFiles) {
        final bytes = await File(file.path).readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 400, height: 400);
          final compressedBytes = img.encodeJpg(resized, quality: 50);
          images.add(base64Encode(compressedBytes));
        }
      }
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        final resized = img.copyResize(image, width: 400, height: 400);
        final compressedBytes = img.encodeJpg(resized, quality: 50);
        images.add(base64Encode(compressedBytes));
        notifyListeners();
      }
    }
  }

  void addImage(String base64) {
    images.add(base64);
    notifyListeners();
  }

  void removeImageAt(int index) {
    images.removeAt(index);
    notifyListeners();
  }

  @override
  void dispose() {
    _productSub?.cancel();
    _categorySub?.cancel();
    super.dispose();
  }

  /// Delete all orders (or you can filter if needed)
  Future<void> deleteAllOrders() async {
    final collection = FirebaseFirestore.instance.collection('orders');

    try {
      // Get all orders
      final snapshot = await collection.get();

      // Batch delete
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print("✅ All orders deleted successfully");
      notifyListeners();
    } catch (e) {
      print("❌ Error deleting orders: $e");
    }
  }
  Future<void> editProduct(Product oldProduct, Product newProduct) async {
  try {
    // Update Firestore
    await FirebaseFirestore.instance
        .collection('products')
        .doc(oldProduct.id)
        .update(newProduct.toMap());

    // Update local list
    final index = _products.indexWhere((p) => p.id == oldProduct.id);
    if (index != -1) {
      _products[index] = newProduct;
    }

    notifyListeners();
    log("✅ Product updated successfully");
  } catch (e, stack) {
    log("❌ Firestore editProduct Error: $e");
    log(stack.toString());
    throw Exception("Failed to edit product");
  }
}


}
