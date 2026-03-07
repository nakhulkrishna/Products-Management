import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:products_catelogs/core/access/access_control.dart';
import 'package:products_catelogs/core/access/user_role.dart';
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
    final requestedRole = appUserRoleFromRaw(role);
    const assignedRole = AppUserRole.staff;
    const requiresApproval = true;
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
        role: assignedRole.firestoreValue,
        requestedRole: requestedRole.firestoreValue,
        phone: phone.trim(),
        region: region.trim(),
        department: department.trim(),
        requiresApproval: requiresApproval,
      );
    }
    return credential;
  }

  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) return null;
          return {...data, '_docId': snapshot.id};
        });
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
    required String requestedRole,
    required String phone,
    required String region,
    required String department,
    required bool requiresApproval,
  }) {
    final now = FieldValue.serverTimestamp();
    final approvalStatus = requiresApproval ? 'pending' : 'approved';
    final normalizedRole = appUserRoleFromRaw(role);
    return _firestore.collection(FirestoreCollections.users).doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': normalizedRole.firestoreValue,
      'requestedRole': appUserRoleFromRaw(requestedRole).firestoreValue,
      'phone': phone.isEmpty ? '+974 5500 1122' : phone,
      'region': region.isEmpty ? 'Doha' : region,
      'department': department.isEmpty ? 'Commercial' : department,
      'approvalStatus': approvalStatus,
      'isActive': !requiresApproval,
      AccessControl.permissionsField: AccessControl.defaultPermissionsForRole(
        normalizedRole,
      ),
      if (!requiresApproval) 'approvedAt': now,
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));
  }
}
