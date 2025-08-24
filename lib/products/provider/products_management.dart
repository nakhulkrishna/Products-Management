import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class Product {
  String id;
  String name;
  double price;
  String unit;
  int stock;
  String description;
  List<String> images; // 🔹 changed to List<String>
  String categoryId;
  bool selected;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.stock,
    required this.description,
    required this.images,
    required this.categoryId,
    this.selected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'unit': unit,
      'stock': stock,
      'description': description,
      'images': images, // 🔹 store list
      'categoryId': categoryId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      stock: map['stock'] ?? 0,
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []), // 🔹 convert to list
      categoryId: map['categoryId'] ?? '',
    );
  }
}

class ProductProvider extends ChangeNotifier {
  ProductProvider() {
    fetchProducts();
  }
  // veriables
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  bool _isFormFilled = false;
  List<String> images = [];
  final List<Product> _products = [];
  bool _isFetched = false;
  List<Product> get products => List.unmodifiable(_products);

  void fillFormOnce(Product? product) {
    if (!_isFormFilled && product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toString();
      unitController.text = product.unit;
      stockController.text = product.stock.toString();
      descController.text = product.description;
      images = List<String>.from(product.images);
      selectedCategory = product.categoryId;
      _isFormFilled = true;
      notifyListeners();
    }
  }

  void resetForm() {
    images.clear();
    selectedCategory = null;
    nameController.clear();
    priceController.clear();
    unitController.clear();
    descController.clear();
    stockController.clear();
    _isFormFilled = false; // reset flag
    notifyListeners();
  }

Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (_isFetched && !forceRefresh) return;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      _products
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Product.fromMap(doc.data())));
      _isFetched = true;
      notifyListeners();
    } catch (e, stack) {
      log("Firestore fetchProducts Error: $e");
      log(stack.toString());
      throw Exception("Failed to fetch products");
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .set(product.toMap());
      _products.add(product); // Update local list
      notifyListeners();
    } catch (e, stack) {
      log("Firestore addProduct Error: $e");
      log(stack.toString());
      throw Exception("Failed to add product");
    }
  }

  Future<void> editProduct(Product oldProduct, Product newProduct) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(oldProduct.id)
          .update(newProduct.toMap());
      final index = _products.indexWhere((p) => p.id == oldProduct.id);
      if (index != -1) {
        _products[index] = newProduct; // Update local list
      }
      resetForm();
      notifyListeners();
    } catch (e, stack) {
      log("Firestore editProduct Error: $e");
      log(stack.toString());
      throw Exception("Failed to edit product");
    }
  }
void toggleSelection(Product product, bool selected) {
  product.selected = selected;
  notifyListeners();
}
  Future<void> deleteSelected() async {
    try {
      final selectedProducts = _products.where((p) => p.selected).toList();
      final batch = FirebaseFirestore.instance.batch();
      for (var product in selectedProducts) {
        batch.delete(FirebaseFirestore.instance.collection('products').doc(product.id));
      }
      await batch.commit();
      _products.removeWhere((p) => p.selected); // Update local list
      notifyListeners();
    } catch (e, stack) {
      log("Firestore deleteSelected Error: $e");
      log(stack.toString());
      throw Exception("Failed to delete products");
    }
  }
  bool get hasSelection => _products.any((p) => p.selected);
  int get selectedCount => _products.where((p) => p.selected).length;

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

      print("✅ Compressed image size: ${compressedBytes.length} bytes");

      return base64Encode(compressedBytes);
    }
    return '';
  }

  String base64Image = '';
  String? selectedCategory;

  void setCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> pickMultipleImages() async {
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

  void disposeControllers() {
    nameController.dispose();
    priceController.dispose();
    unitController.dispose();
    descController.dispose();
    stockController.dispose();
  }

  // Add a new image
  void addImage(String base64) {
    images.add(base64);
    notifyListeners();
  }

  // Remove image by index
  void removeImageAt(int index) {
    images.removeAt(index);
    notifyListeners();
  }
}
