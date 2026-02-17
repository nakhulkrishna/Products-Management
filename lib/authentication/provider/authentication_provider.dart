import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStartDestination { login, registration, dashboard }

class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['username'] ?? '',
      email: data['email'] ?? '',
    );
  }
}

class UserProvider extends ChangeNotifier {
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'username';

  UserModel? _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAuthenticating = false;
  String? _authMessage;
  bool? _registrationEnabledCache;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticating => _isAuthenticating;
  String? get authMessage => _authMessage;

  CollectionReference<Map<String, dynamic>> get _adminCollection =>
      _firestore.collection('Admin');

  Future<AuthStartDestination> resolveStartupDestination() async {
    final isLoggedIn = await checkLogin();
    if (isLoggedIn) {
      return AuthStartDestination.dashboard;
    }

    final canRegister = await isRegistrationEnabled();
    return canRegister
        ? AuthStartDestination.registration
        : AuthStartDestination.login;
  }

  Future<bool> isRegistrationEnabled({bool forceRefresh = false}) async {
    if (!forceRefresh && _registrationEnabledCache != null) {
      return _registrationEnabledCache!;
    }

    try {
      final doc = await _firestore
          .collection('AppConfig')
          .doc('registration')
          .get();

      final status = (doc.data()?['status'] as String?)?.toUpperCase() ?? 'OFF';
      final enabled = doc.exists && status == 'ON';
      _registrationEnabledCache = enabled;
      return enabled;
    } catch (e) {
      debugPrint('Error fetching registration toggle: $e');
      _registrationEnabledCache = false;
      return false;
    }
  }

  Future<bool> checkLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_userIdKey);
      if (id == null || id.trim().isEmpty) {
        return false;
      }

      final doc = await _adminCollection.doc(id).get();
      final data = doc.data();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(data ?? <String, dynamic>{}, doc.id);
        notifyListeners();
        return true;
      }

      await _clearSession(prefs);
      return false;
    } catch (e) {
      debugPrint('Session restore error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    clearAuthMessage();
    final rawEmail = email.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (normalizedEmail.isEmpty || trimmedPassword.isEmpty) {
      _setAuthMessage('Email and password are required.');
      return false;
    }

    if (!isValidEmail(normalizedEmail)) {
      _setAuthMessage('Please enter a valid email.');
      return false;
    }

    _setAuthenticating(true);
    try {
      final hashedPassword = _hashPassword(trimmedPassword);

      QuerySnapshot<Map<String, dynamic>> snapshot = await _adminCollection
          .where('emailNormalized', isEqualTo: normalizedEmail)
          .where('password', isEqualTo: hashedPassword)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await _adminCollection
            .where('email', isEqualTo: normalizedEmail)
            .where('password', isEqualTo: hashedPassword)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isEmpty && rawEmail != normalizedEmail) {
        snapshot = await _adminCollection
            .where('email', isEqualTo: rawEmail)
            .where('password', isEqualTo: hashedPassword)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        _currentUser = UserModel.fromMap(data, doc.id);
        await _persistSession(_currentUser!);
        notifyListeners();
        return true;
      }

      _setAuthMessage('Invalid email or password.');
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      _setAuthMessage('Unable to login right now. Please try again.');
      return false;
    } finally {
      _setAuthenticating(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    clearAuthMessage();
    final trimmedName = name.trim();
    final rawEmail = email.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (trimmedName.length < 2) {
      _setAuthMessage('Please enter your full name.');
      return false;
    }

    if (!isValidEmail(normalizedEmail)) {
      _setAuthMessage('Please enter a valid email.');
      return false;
    }

    if (trimmedPassword.length < 7) {
      _setAuthMessage('Password must be at least 7 characters.');
      return false;
    }

    final canRegister = await isRegistrationEnabled(forceRefresh: true);
    if (!canRegister) {
      _setAuthMessage('Registration is currently disabled.');
      return false;
    }

    _setAuthenticating(true);
    try {
      final existing = await _adminCollection
          .where('emailNormalized', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty ||
          await _emailExistsFallback(rawEmail, normalizedEmail)) {
        _setAuthMessage('Email already exists.');
        return false;
      }

      final doc = _adminCollection.doc();
      await doc.set({
        'username': trimmedName,
        'email': normalizedEmail,
        'emailNormalized': normalizedEmail,
        'password': _hashPassword(trimmedPassword),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _currentUser = UserModel(
        id: doc.id,
        name: trimmedName,
        email: normalizedEmail,
      );
      await _persistSession(_currentUser!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Registration Error: $e');
      _setAuthMessage('Unable to register right now. Please try again.');
      return false;
    } finally {
      _setAuthenticating(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    _currentUser = null;
    _authMessage = null;
    notifyListeners();
  }

  void clearAuthMessage() {
    if (_authMessage == null) return;
    _authMessage = null;
    notifyListeners();
  }

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
  }

  void _setAuthenticating(bool value) {
    if (_isAuthenticating == value) return;
    _isAuthenticating = value;
    notifyListeners();
  }

  void _setAuthMessage(String message) {
    _authMessage = message;
    notifyListeners();
  }

  String _hashPassword(String value) {
    final bytes = utf8.encode(value);
    return sha256.convert(bytes).toString();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  Future<bool> _emailExistsFallback(
    String rawEmail,
    String normalizedEmail,
  ) async {
    final normalizedCheck = await _adminCollection
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (normalizedCheck.docs.isNotEmpty) {
      return true;
    }

    if (rawEmail == normalizedEmail) {
      return false;
    }

    final rawCheck = await _adminCollection
        .where('email', isEqualTo: rawEmail)
        .limit(1)
        .get();
    return rawCheck.docs.isNotEmpty;
  }
}
