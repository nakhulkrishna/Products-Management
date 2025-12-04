import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ==================== MODELS ====================
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toMap() => {"id": id, "name": name};

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map["id"] ?? "",
      name: map["name"] ?? "",
    );
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
  final String color;
  final String buyer;

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
      color: map['color'] ?? '',
      buyer: map['buyer'] ?? '',
    );
  }

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
      'color': color,
      'buyer': buyer,
    };
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final double? offerPrice;
  final String unit;
  final int stock;
  final String description;
  final List<String> images;
  final String categoryId;
  final double? hyperMarket;
  final String market;
  final String itemCode;
  final double? hyperMarketPrice;
  final double? kgPrice;
  final double? ctrPrice;
  final double? pcsPrice;
  final bool isHidden;

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
      'hyperPrice': hyperMarket,
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
    return Product(
      itemCode: map['itemCode'] ?? "",
      market: map['market'] ?? "",
      hyperMarket: _parseDouble(map['hyperPrice']),
      hyperMarketPrice: _parseDouble(map['hyperMarketPrice']),
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: _parseDouble(map['price']) ?? 0.0,
      offerPrice: _parseDouble(map['offerPrice']),
      unit: map['unit'] ?? '',
      stock: _parseInt(map['stock']),
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['categoryId'] ?? '',
      kgPrice: _parseDouble(map['kgPrice']),
      ctrPrice: _parseDouble(map['ctrPrice']),
      pcsPrice: _parseDouble(map['pcsPrice']),
      isHidden: map['isHidden'] == true,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
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
    bool? isHidden,
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
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      hyperMarket: hyperMarket ?? this.hyperMarket,
      hyperMarketPrice: hyperMarketPrice ?? this.hyperMarketPrice,
      market: market ?? this.market,
      kgPrice: kgPrice ?? this.kgPrice,
      ctrPrice: ctrPrice ?? this.ctrPrice,
      pcsPrice: pcsPrice ?? this.pcsPrice,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

// ==================== PRODUCT PROVIDER ====================
class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // ==================== PAGINATION CONFIG ====================
  static const int _pageSize = 15; // Reduced from 20 for better performance
  static const int _maxCachedProducts = 100; // Maximum products to keep in memory

  // ==================== STATE ====================
  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<Category> _categories = [];
  List<dynamic> images = [];

  DocumentSnapshot? _lastDocument;
  bool _hasMoreProducts = true;
  bool _isLoadingMore = false;
  bool _initialLoadComplete = false;

  Product? _editingProduct;
  String? selectedCategory;
  String? selectedMarket;
  String _searchQuery = "";
  String? expandedProductId;
  final List<String> _selectedFilterCategories = [];

  // ==================== FORM CONTROLLERS ====================
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

  // ==================== SUBSCRIPTIONS ====================
  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _categorySub;

  // ==================== GETTERS ====================
  List<Product> get products => List.unmodifiable(_products);
  List<Order> get orders => List.unmodifiable(_orders);
  List<Category> get categories => List.unmodifiable(_categories);
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoadingMore => _isLoadingMore;
  bool get initialLoadComplete => _initialLoadComplete;
  List<String> get selectedFilterCategories => _selectedFilterCategories;
  String get searchQuery => _searchQuery;

  double get totalOrderValue =>
      _orders.fold(0.0, (sum, order) => sum + order.total);

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.itemCode.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedFilterCategories.isEmpty ||
          _selectedFilterCategories.contains(p.categoryId);
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ==================== INITIALIZATION ====================
  ProductProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await _loadInitialProducts();
    _listenCategories();
    _listenOrders();
  }

  // ==================== PAGINATION METHODS ====================
  Future<void> _loadInitialProducts() async {
    try {
      log('📥 Loading initial products...');
      
      final query = _firestore
          .collection('products')
          .orderBy('name')
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _products.clear();

        for (var doc in snapshot.docs) {
          try {
            _products.add(Product.fromMap(doc.data()));
          } catch (e) {
            log('⚠️ Error parsing product: $e');
          }
        }

        _hasMoreProducts = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreProducts = false;
      }

      _initialLoadComplete = true;
      notifyListeners();
      log('✅ Loaded ${_products.length} products');
    } catch (e, stack) {
      log('❌ _loadInitialProducts error: $e');
      log(stack.toString());
      _initialLoadComplete = true;
      _hasMoreProducts = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts || _lastDocument == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      log('📥 Loading more products...');

      final query = _firestore
          .collection('products')
          .orderBy('name')
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        for (var doc in snapshot.docs) {
          try {
            final product = Product.fromMap(doc.data());
            if (!_products.any((p) => p.id == product.id)) {
              _products.add(product);
            }
          } catch (e) {
            log('⚠️ Error parsing product: $e');
          }
        }

        _hasMoreProducts = snapshot.docs.length == _pageSize;
        
        // Memory management: Remove oldest products if exceeding limit
        if (_products.length > _maxCachedProducts) {
          _products.removeRange(0, _products.length - _maxCachedProducts);
          log('🧹 Cleaned up old products. Current count: ${_products.length}');
        }
      } else {
        _hasMoreProducts = false;
      }

      log('✅ Total products: ${_products.length}');
    } catch (e, stack) {
      log('❌ loadMoreProducts error: $e');
      log(stack.toString());
      _hasMoreProducts = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    log('🔄 Refreshing products...');
    _products.clear();
    _lastDocument = null;
    _hasMoreProducts = true;
    _initialLoadComplete = false;
    notifyListeners();

    await _loadInitialProducts();
  }

  // ==================== PRODUCT OPERATIONS ====================
  Future<void> addProduct(Product product, List<dynamic> images) async {
    try {
      log('➕ Adding new product...');
      
      final imageUrls = await _uploadMultipleImages(images);
      final newProduct = product.copyWith(images: imageUrls);

      await _firestore
          .collection('products')
          .doc(newProduct.id)
          .set(newProduct.toMap());

      _products.insert(0, newProduct);
      notifyListeners();
      
      log("✅ Product added successfully");
    } catch (e, stack) {
      log("❌ addProduct Error: $e");
      log(stack.toString());
      rethrow;
    }
  }

  Future<void> editProduct(Product oldProduct, Product newProduct) async {
    try {
      log('✏️ Editing product: ${oldProduct.id}');
      
      await _firestore
          .collection('products')
          .doc(oldProduct.id)
          .update(newProduct.toMap());

      final index = _products.indexWhere((p) => p.id == newProduct.id);
      if (index != -1) {
        _products[index] = newProduct;
      } else {
        _products.add(newProduct);
      }

      notifyListeners();
      log("✅ Product updated successfully");
    } catch (e, stack) {
      log("❌ editProduct Error: $e");
      log(stack.toString());
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      log('🗑️ Deleting product: $id');
      
      await _firestore.collection('products').doc(id).delete();
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      
      log("✅ Product deleted successfully");
    } catch (e, stack) {
      log("❌ deleteProduct Error: $e");
      log(stack.toString());
      rethrow;
    }
  }

  Future<void> toggleProductVisibility(String id, bool hide) async {
    try {
      await _firestore.collection('products').doc(id).set(
        {
          'isHidden': hide,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isHidden: hide);
      }

      notifyListeners();
    } catch (e, stack) {
      log("❌ toggleProductVisibility Error: $e");
      log(stack.toString());
      rethrow;
    }
  }

  Future<void> setOfferPrice(Product product, double? offerPrice) async {
    await _updateProductField(product, {'offerPrice': offerPrice});
  }

  Future<void> setHyperMarketPrice(Product product, double? price) async {
    await _updateProductField(product, {'hyperMarketPrice': price});
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
          hyperMarketPrice: fields['hyperMarketPrice'] ?? existing.hyperMarketPrice,
        );
      }
      
      notifyListeners();
    } catch (e, stack) {
      log("❌ _updateProductField Error: $e");
      log(stack.toString());
      rethrow;
    }
  }

  // ==================== CATEGORIES ====================
  void _listenCategories() {
    _categorySub?.cancel();
    _categorySub = _firestore.collection('categories').snapshots().listen(
      (snapshot) {
        _categories
          ..clear()
          ..addAll(snapshot.docs.map((doc) => Category.fromMap(doc.data())));
        notifyListeners();
      },
      onError: (error) => log('❌ listenCategories error: $error'),
    );
  }

  void toggleFilterCategory(String categoryId) {
    if (_selectedFilterCategories.contains(categoryId)) {
      _selectedFilterCategories.remove(categoryId);
    } else {
      _selectedFilterCategories.add(categoryId);
    }
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    selectedCategory = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setMarket(String? market) {
    selectedMarket = market;
    notifyListeners();
  }

  void toggleExpanded(String productId) {
    expandedProductId = expandedProductId == productId ? null : productId;
    notifyListeners();
  }

  // ==================== ORDERS ====================
  void _listenOrders() {
    _ordersSub?.cancel();
    _ordersSub = _firestore.collection('orders').snapshots().listen(
      (snapshot) {
        _orders
          ..clear()
          ..addAll(snapshot.docs.map((doc) => Order.fromMap(doc.data())));
        notifyListeners();
      },
      onError: (error) => log('❌ listenOrders error: $error'),
    );
  }

  Future<void> deleteAllOrders() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      _orders.clear();
      notifyListeners();
      log("✅ All orders deleted successfully");
    } catch (e) {
      log("❌ deleteAllOrders error: $e");
    }
  }

  // ==================== IMAGE HANDLING ====================
  Future<void> pickImageFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      images.add(File(pickedFile.path));
      notifyListeners();
    }
  }

  Future<void> pickMultipleImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      images.addAll(pickedFiles.map((xfile) => File(xfile.path)));
      notifyListeners();
    }
  }

  void addImage(File file) {
    images.add(file);
    notifyListeners();
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      notifyListeners();
    }
  }

  void removeImage(File image) {
    images.remove(image);
    notifyListeners();
  }

  Future<List<String>> _uploadMultipleImages(List<dynamic> imageFiles) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      try {
        final url = await _uploadImageToCloudinary(imageFile);
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        log('⚠️ Failed to upload image: $e');
      }
    }

    return uploadedUrls;
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dmqmff4g4';
    const uploadPreset = 'red_rose_contracting_w.l.l';

    try {
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
        return decoded['secure_url'];
      } else {
        log('❌ Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Cloudinary upload error: $e');
      return null;
    }
  }

  // ==================== FORM MANAGEMENT ====================
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

    images = List<dynamic>.from(product.images);
    notifyListeners();
  }

  Future<void> saveEditedProductDirect(Product updatedProduct) async {
    final newImages = images.whereType<File>().toList();
    final existingUrls = images.whereType<String>().toList();

    List<String> finalImageUrls = existingUrls;

    if (newImages.isNotEmpty) {
      final uploadedUrls = await _uploadMultipleImages(newImages);
      finalImageUrls = [...existingUrls, ...uploadedUrls];
    }

    final productToSave = updatedProduct.copyWith(images: finalImageUrls);
    await editProduct(updatedProduct, productToSave);

    resetForm();
    _editingProduct = null;
  }

  // ==================== CLEANUP ====================
  @override
  void dispose() {
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
}