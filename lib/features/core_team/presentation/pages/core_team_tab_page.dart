import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/core/access/access_control.dart';
import 'package:products_catelogs/core/access/user_role.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';
import 'package:products_catelogs/features/auth/application/auth_providers.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

class CoreTeamTabPage extends ConsumerStatefulWidget {
  const CoreTeamTabPage({super.key});

  @override
  ConsumerState<CoreTeamTabPage> createState() => _CoreTeamTabPageState();
}

class _CoreTeamTabPageState extends ConsumerState<CoreTeamTabPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  final List<_CorePanelUser> _users = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;
  bool _loading = true;
  String? _error;
  String? _errorLog;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _subscribeUsers();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeUsers() {
    _usersSub?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _errorLog = null;
    });
    _usersSub = _firestore
        .collection(FirestoreCollections.users)
        .snapshots()
        .listen(
          (snapshot) {
            final users =
                snapshot.docs
                    .map(_CorePanelUser.fromDoc)
                    .whereType<_CorePanelUser>()
                    .toList()
                  ..sort(
                    (a, b) => a.fullName.toLowerCase().compareTo(
                      b.fullName.toLowerCase(),
                    ),
                  );
            if (!mounted) return;
            setState(() {
              _users
                ..clear()
                ..addAll(users);
              _loading = false;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            final errorLog = _buildErrorLog(
              action: 'catalog_users stream subscribe',
              error: error,
              stackTrace: stackTrace,
            );
            _logErrorToConsole(errorLog, error, stackTrace);
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = '$error';
              _errorLog = errorLog;
            });
          },
        );
  }

  List<_CorePanelUser> get _filteredUsers {
    if (_query.isEmpty) return _users;
    return _users.where((user) {
      return user.fullName.toLowerCase().contains(_query) ||
          user.email.toLowerCase().contains(_query) ||
          _roleLabelForCoreTeam(user.role).toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(currentUserRoleProvider) == AppUserRole.admin;
    final users = _filteredUsers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Core Team',
          style: TextStyle(
            fontSize: 30,
            height: 1.1,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'List and manage Super Admin and assisting admin-panel users.',
          style: TextStyle(
            color: Color(0xFF8A94A6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search users',
            prefixIcon: const Icon(Iconsax.search_normal),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!canManage) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Text(
              'Only admins can manage users in Core Team. You have view-only access.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFB42318)),
                            ),
                            if ((_errorLog ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SelectableText(
                                _errorLog!,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                : users.isEmpty
                ? const Center(
                    child: Text('No Super Admin or assisting users found.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE8EBF0)),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _userRow(user, canManage: canManage);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _userRow(_CorePanelUser user, {required bool canManage}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFDCE6EA),
            child: Icon(Iconsax.user, color: Color(0xFF4C596D)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _chip(
            _roleLabelForCoreTeam(user.role),
            const Color(0xFFEAF4FF),
            const Color(0xFF2277B8),
          ),
          const SizedBox(width: 8),
          if (user.approvalStatus != 'approved') ...[
            _chip(
              user.approvalStatus == 'pending'
                  ? 'Pending Approval'
                  : 'Unapproved',
              const Color(0xFFFFF4E5),
              const Color(0xFFB54708),
            ),
            const SizedBox(width: 8),
          ],
          _chip(
            user.isActive ? 'Active' : 'Inactive',
            user.isActive ? const Color(0xFFEFFAF3) : const Color(0xFFFFEEF0),
            user.isActive ? const Color(0xFF0F9D58) : const Color(0xFFC62828),
          ),
          if (canManage) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              onSelected: (value) async {
                if (value == 'edit') {
                  await _editUserAccess(user);
                  return;
                }
                if (value == 'approve') {
                  await _approveUser(user);
                  return;
                }
                if (value == 'delete') {
                  await _confirmDeleteUser(user);
                  return;
                }
                await _toggleUserActive(user);
              },
              itemBuilder: (_) {
                final items = <PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Role & Permissions'),
                  ),
                ];
                if (user.approvalStatus != 'approved') {
                  items.add(
                    const PopupMenuItem(
                      value: 'approve',
                      child: Text('Approve User'),
                    ),
                  );
                }
                items.add(
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      user.isActive ? 'Deactivate User' : 'Activate User',
                    ),
                  ),
                );
                items.add(
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete User'),
                  ),
                );
                return items;
              },
              child: const Icon(Iconsax.setting, color: Color(0xFF4B5563)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Future<void> _toggleUserActive(_CorePanelUser user) async {
    if (!_ensureAdminAccess()) return;
    try {
      final nextActive = !user.isActive;
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({
            'isActive': nextActive,
            if (nextActive) 'approvalStatus': 'approved',
            if (nextActive) 'approvedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !user.isActive ? 'User activated.' : 'User deactivated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user status: $error')),
      );
    }
  }

  Future<void> _approveUser(_CorePanelUser user) async {
    if (!_ensureAdminAccess()) return;
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({
            'approvalStatus': 'approved',
            'isActive': true,
            'approvedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${user.fullName} approved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to approve user: $error')));
    }
  }

  Future<void> _confirmDeleteUser(_CorePanelUser user) async {
    if (!_ensureAdminAccess()) return;
    final shouldDelete = await _showSideSheet<bool>(
      title: 'Delete User',
      body: Text(
        'Delete ${user.fullName} from Core Team?\n\nThis removes the admin panel user profile record.',
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
          ),
          child: const Text('Delete'),
        ),
      ],
    );

    if (shouldDelete != true) return;
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${user.fullName} deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete user: $error')));
    }
  }

  Future<void> _editUserAccess(_CorePanelUser user) async {
    if (!_ensureAdminAccess()) return;
    final role = ValueNotifier<AppUserRole>(user.role);
    final permissionMap = ValueNotifier<Map<String, bool>>(
      Map<String, bool>.from(user.permissions),
    );

    final saved = await _showSideSheet<bool>(
      title: 'Manage Access: ${user.fullName}',
      body: ValueListenableBuilder<AppUserRole>(
        valueListenable: role,
        builder: (context, selectedRole, _) {
          return ValueListenableBuilder<Map<String, bool>>(
            valueListenable: permissionMap,
            builder: (context, localPermissions, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<AppUserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                          AppUserRole.developer,
                          AppUserRole.admin,
                          AppUserRole.staff,
                        ]
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry,
                            child: Text(_roleLabelForCoreTeam(entry)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      role.value = value;
                      permissionMap.value = {
                        ...AccessControl.defaultPermissionsForRole(value),
                        ...permissionMap.value,
                      };
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Module Permissions',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final tab in SidebarTab.values)
                    SwitchListTile(
                      dense: true,
                      title: Text(tab.label),
                      value:
                          localPermissions[AccessControl.permissionKey(tab)] ??
                          false,
                      onChanged: (value) {
                        permissionMap.value = {
                          ...localPermissions,
                          AccessControl.permissionKey(tab): value,
                        };
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Save'),
        ),
      ],
    );
    final updatedRole = role.value;
    final updatedPermissions = permissionMap.value;
    role.dispose();
    permissionMap.dispose();

    if (saved != true) return;
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({
            'role': updatedRole.firestoreValue,
            AccessControl.permissionsField: updatedPermissions,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User permissions updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save permissions: $error')),
      );
    }
  }

  bool _ensureAdminAccess() {
    if (ref.read(currentUserRoleProvider) == AppUserRole.admin) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Only admins can manage Core Team users.'),
      ),
    );
    return false;
  }

  String _roleLabelForCoreTeam(AppUserRole role) {
    if (role == AppUserRole.developer) return 'Super Admin';
    return role.label;
  }

  Future<T?> _showSideSheet<T>({
    required String title,
    required Widget body,
    List<Widget> actions = const [],
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1080 ? 520.0 : (width > 720 ? 460.0 : width);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Iconsax.close_circle, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: body,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: actions,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  String _buildErrorLog({
    required String action,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final now = DateTime.now().toIso8601String();
    final firebaseError = error is FirebaseException ? error : null;
    final authUser = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    final rawRole = (profile?['role'] ?? '').toString();

    return '''
[CoreTeam Error]
time: $now
action: $action
firebase_code: ${firebaseError?.code ?? 'n/a'}
firebase_plugin: ${firebaseError?.plugin ?? 'n/a'}
message: ${firebaseError?.message ?? error}
auth_uid: ${authUser?.uid ?? 'n/a'}
auth_email: ${authUser?.email ?? 'n/a'}
profile_doc_id: ${(profile?['_docId'] ?? 'n/a').toString()}
profile_role: $rawRole
stacktrace:
$stackTrace
''';
  }

  void _logErrorToConsole(String errorLog, Object error, StackTrace stackTrace) {
    developer.log(
      errorLog,
      name: 'CoreTeamTabPage',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    print('========== CORE TEAM ERROR START ==========');
    print(errorLog);
    print('=========== CORE TEAM ERROR END ===========');
  }
}

class _CorePanelUser {
  final String uid;
  final String fullName;
  final String email;
  final AppUserRole role;
  final bool isActive;
  final String approvalStatus;
  final Map<String, bool> permissions;

  const _CorePanelUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.approvalStatus,
    required this.permissions,
  });

  static _CorePanelUser? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final rawRole = (data['role'] as String? ?? '').trim().toLowerCase();
    final rawRequestedRole =
        (data['requestedRole'] as String? ?? '').trim().toLowerCase();
    final isSalesman =
        rawRole.contains('sales') ||
        rawRequestedRole.contains('sales');
    if (isSalesman) {
      return null;
    }

    final isCoreTeamRole =
        rawRole.contains('admin') ||
        rawRole.contains('manager') ||
        rawRole.contains('developer') ||
        rawRole == 'dev' ||
        rawRole.contains('staff') ||
        rawRequestedRole.contains('admin') ||
        rawRequestedRole.contains('manager') ||
        rawRequestedRole.contains('developer') ||
        rawRequestedRole == 'dev' ||
        rawRequestedRole.contains('staff');
    if (!isCoreTeamRole) {
      return null;
    }

    final role = appUserRoleFromRaw(data['role']);
    final defaultPermissions = AccessControl.defaultPermissionsForRole(role);
    final parsedPermissions = AccessControl.parsePermissions(
      data[AccessControl.permissionsField],
    );

    final isActive = data['isActive'] is bool ? data['isActive'] as bool : true;
    final approvalStatus =
        (data['approvalStatus'] as String?)?.trim().toLowerCase() ??
        (isActive ? 'approved' : 'pending');

    return _CorePanelUser(
      uid: doc.id,
      fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? (data['fullName'] as String).trim()
          : 'Unnamed User',
      email: (data['email'] as String?)?.trim().isNotEmpty == true
          ? (data['email'] as String).trim()
          : 'No email',
      role: role,
      isActive: isActive,
      approvalStatus: approvalStatus,
      permissions: {...defaultPermissions, ...parsedPermissions},
    );
  }
}
