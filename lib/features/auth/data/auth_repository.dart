import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String region,
    required String department,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null && fullName.trim().isNotEmpty) {
      await user.updateDisplayName(fullName.trim());
      await user.reload();
    }
    if (user != null) {
      await _upsertUserProfile(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        role: role.trim(),
        phone: phone.trim(),
        region: region.trim(),
        department: department.trim(),
      );
    }
    return credential;
  }

  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> _upsertUserProfile({
    required String uid,
    required String fullName,
    required String email,
    required String role,
    required String phone,
    required String region,
    required String department,
  }) {
    final now = FieldValue.serverTimestamp();
    return _firestore.collection(FirestoreCollections.users).doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role.isEmpty ? 'Sales Manager' : role,
      'phone': phone.isEmpty ? '+974 5500 1122' : phone,
      'region': region.isEmpty ? 'Doha' : region,
      'department': department.isEmpty ? 'Commercial' : department,
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));
  }
}
