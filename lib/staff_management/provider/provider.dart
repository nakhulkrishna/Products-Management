import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class StaffProvider extends ChangeNotifier {
  StaffProvider() {
    fetchStaff();
  }
  // Fields
  String _username = '';
  String _email = '';
  String _password = '';
  bool _submitted = false;
  bool _obscurePassword = true;
  List<Map<String, dynamic>> _staffList = [];
  // Getters
  String get username => _username;
  String get email => _email;
  String get password => _password;
  bool get submitted => _submitted;
  bool get obscurePassword => _obscurePassword;
  List<Map<String, dynamic>> get staffList => _staffList;

  // Setters
  void setUsername(String val) {
    _username = val;
    notifyListeners();
  }

  void setEmail(String val) {
    _email = val;
    notifyListeners();
  }

  void setPassword(String val) {
    _password = val;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // Mark form as submitted to show inline errors
  void markSubmitted() {
    _submitted = true;
    notifyListeners();
  }

  // Validate fields
  bool validateFields() {
    return _username.isNotEmpty && _email.isNotEmpty && _password.length >= 7;
  }

  // Submit staff to Firestore
  Future<void> submitStaff() async {
    if (!validateFields()) return;

    // Hash the password
    final bytes = utf8.encode(_password);
    final hashedPassword = sha256.convert(bytes).toString();

    // Custom ID based on timestamp
    final customId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add to Firestore using the custom ID as document ID
    await FirebaseFirestore.instance
        .collection('staff')
        .doc(customId) // <-- document ID
        .set({
          "id": customId, // <-- store the ID as a field too
          "username": _username,
          "email": _email,
          "password": hashedPassword,
          "createdAt": FieldValue.serverTimestamp(),
        });
fetchStaff();
    // Reset fields
    _username = '';
    _email = '';
    _password = '';
    _submitted = false;
    notifyListeners();

    print('Staff added with ID: $customId');
  }

  // Fetch staff list and update _staffList
  Future<void> fetchStaff() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('staff')
          .get();
      _staffList = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners(); // notify UI to rebuild
    } catch (e) {
      print('Error fetching staff: $e');
    }
  }

  Future<void> deleteStaff(String docId) async {
    await FirebaseFirestore.instance.collection('staff').doc(docId).delete();
    _staffList.removeWhere((staff) => staff['id'] == docId);
    notifyListeners();
  }
}
