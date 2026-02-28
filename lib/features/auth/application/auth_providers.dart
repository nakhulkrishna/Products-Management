import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/core/access/access_control.dart';
import 'package:products_catelogs/core/access/user_role.dart';
import 'package:products_catelogs/core/settings/user_preferences.dart';
import 'package:products_catelogs/features/auth/data/auth_repository.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream<Map<String, dynamic>?>.value(null);
  }
  return ref.watch(authRepositoryProvider).userProfileStream(user.uid);
});

final currentUserRoleProvider = Provider<AppUserRole>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return appUserRoleFromRaw(profile?['role']);
});

final allowedTabsProvider = Provider<List<SidebarTab>>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  final profile = ref.watch(userProfileProvider).value;
  return AccessControl.allowedTabs(
    role: role,
    permissionsRaw: profile?[AccessControl.permissionsField],
  );
});

final userPreferencesProvider = Provider<UserPreferences>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return userPreferencesFromProfile(profile);
});
