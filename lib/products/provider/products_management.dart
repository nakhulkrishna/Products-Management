import 'package:flutter/material.dart';

class Product {
  String name;
  String code;
  double price;
  String image;
  bool selected;

  Product({
    required this.name,
    required this.code,
    required this.price,
    required this.image,
    this.selected = false,
  });
}

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  // add initial list (optional)
  void setProducts(List<Product> products, ) {
    _products = products;
    notifyListeners();
  }

  void toggleSelection(Product product, bool selected) {
    product.selected = selected;
    notifyListeners();
  }

  void deleteSelected() {
    _products.removeWhere((p) => p.selected);
    notifyListeners();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  bool get hasSelection => _products.any((p) => p.selected);

  int get selectedCount => _products.where((p) => p.selected).length;
}
