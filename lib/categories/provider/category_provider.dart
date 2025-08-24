import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class Category {
  String id;
  String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {"id": id, "name": name};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map["id"], name: map["name"]);
  }
}


class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Category> _categories = [];
  StreamSubscription? _subscription;

  List<Category> get categories => List.unmodifiable(_categories);

  CategoryProvider() {
    _listenToCategories();
  }

  void _listenToCategories() {
    _subscription = _firestore.collection("categories").snapshots().listen((snapshot) {
      _categories
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Category.fromMap(doc.data())));
      notifyListeners();
    });
  }

  Future<void> addCategory(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newCategory = Category(id: id, name: name);

    await _firestore.collection("categories").doc(id).set(newCategory.toMap());
  }

  Future<void> editCategory(String id, String newName) async {
    await _firestore.collection("categories").doc(id).update({"name": newName});
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection("categories").doc(id).delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
