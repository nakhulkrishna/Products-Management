import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppNumberProvider extends ChangeNotifier {
  String _number = "";

  String get number => _number;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load saved number from SharedPreferences
  Future<void> loadNumber() async {
    final prefs = await SharedPreferences.getInstance();
    _number = prefs.getString('whatsapp_number') ?? "";
    notifyListeners();
  }

  /// Save number to SharedPreferences and Firestore
  Future<void> saveNumber(String number) async {
    _number = number;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('whatsapp_number', _number);

    try {
      await _firestore.collection('order_whatsapp').doc('main_number').set({
        'number': _number,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving number to Firestore: $e");
    }

    notifyListeners();
  }

  /// Validate number (plain digits only, 6-15 digits)
  bool validateNumber(String number) {
    final regExp = RegExp(r'^\d{6,15}$');
    return regExp.hasMatch(number);
  }
}
