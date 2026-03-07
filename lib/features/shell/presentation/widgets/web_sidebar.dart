import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/core/constants/app_images.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';
import 'package:products_catelogs/features/products/application/bulk_upload_background_service.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

class WebShellScaffold extends StatelessWidget {
  final SidebarTab activeTab;
  final List<SidebarTab> visibleTabs;
  final ValueChanged<SidebarTab> onTabSelected;
  final VoidCallback onLogout;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenOrdersFromNotifications;
  final VoidCallback onOpenCoreTeamFromNotifications;
  final ValueChanged<String> onSearchSubmitted;
  final String userName;
  final String userSubtitle;
  final Widget body;

  const WebShellScaffold({
    super.key,
    required this.activeTab,
    required this.visibleTabs,
    required this.onTabSelected,
    required this.onLogout,
    required this.onOpenSettings,
    required this.onOpenOrdersFromNotifications,
    required this.onOpenCoreTeamFromNotifications,
    required this.onSearchSubmitted,
    required this.userName,
    required this.userSubtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1120;
        final isNarrow = constraints.maxWidth < 900;
        final isMobile = constraints.maxWidth < 760;

        if (isMobile) {
          return _MobileShellScaffold(
            activeTab: activeTab,
            visibleTabs: visibleTabs,
            onTabSelected: onTabSelected,
            onLogout: onLogout,
            onOpenSettings: onOpenSettings,
            onOpenOrdersFromNotifications: onOpenOrdersFromNotifications,
            onOpenCoreTeamFromNotifications: onOpenCoreTeamFromNotifications,
            onSearchSubmitted: onSearchSubmitted,
            body: body,
          );
        }

        return Center(
          child: Container(
            // margin: EdgeInsets.all(isNarrow ? 8 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              // borderRadius: BorderRadius.circular(isNarrow ? 18 : 24),
              border: Border.all(color: const Color(0xFFE5E8ED)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x170D1B2A),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isNarrow ? 18 : 24),
              child: Row(
                children: [
                  _IconRail(
                    activeTab: activeTab,
                    visibleTabs: visibleTabs,
                    onTabSelected: onTabSelected,
                    onLogout: onLogout,
                    compact: isCompact,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopAppBar(
                          title: activeTab.label,
                          compact: isCompact,
                          narrow: isNarrow,
                          onOpenSettings: onOpenSettings,
                          onOpenOrdersFromNotifications:
                              onOpenOrdersFromNotifications,
                          onOpenCoreTeamFromNotifications:
                              onOpenCoreTeamFromNotifications,
                          onSearchSubmitted: onSearchSubmitted,
                          onLogout: onLogout,
                          userName: userName,
                          userSubtitle: userSubtitle,
                          canSeeCoreTeamNotifications: visibleTabs.contains(
                            SidebarTab.coreTeam,
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE8EBF0)),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(isNarrow ? 10 : 18),
                            child: body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileShellScaffold extends StatelessWidget {
  final SidebarTab activeTab;
  final List<SidebarTab> visibleTabs;
  final ValueChanged<SidebarTab> onTabSelected;
  final VoidCallback onLogout;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenOrdersFromNotifications;
  final VoidCallback onOpenCoreTeamFromNotifications;
  final ValueChanged<String> onSearchSubmitted;
  final Widget body;

  const _MobileShellScaffold({
    required this.activeTab,
    required this.visibleTabs,
    required this.onTabSelected,
    required this.onLogout,
    required this.onOpenSettings,
    required this.onOpenOrdersFromNotifications,
    required this.onOpenCoreTeamFromNotifications,
    required this.onSearchSubmitted,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE8EBF0))),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Search',
                    onPressed: () => _openSearchDialog(context),
                    icon: const Icon(Iconsax.search_normal),
                  ),
                  Expanded(
                    child: Text(
                      activeTab.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F29),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    onSelected: (value) {
                      if (value == 'settings') {
                        onOpenSettings();
                      } else if (value == 'logout') {
                        onLogout();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'settings', child: Text('Settings')),
                      PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(8), child: body),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE8EBF0))),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      for (final tab in visibleTabs)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _MobileTabChip(
                            label: tab.label,
                            icon: tab.icon,
                            selected: tab == activeTab,
                            onTap: () => onTabSelected(tab),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSearchDialog(BuildContext context) async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Search'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
            decoration: const InputDecoration(
              hintText: 'Search and jump...',
              prefixIcon: Icon(Iconsax.search_normal),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );

    final normalized = query?.trim() ?? '';
    if (normalized.isNotEmpty) {
      onSearchSubmitted(normalized);
    }
  }
}

class _MobileTabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MobileTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE6F4F3) : const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? const Color(0xFF369C99)
                    : const Color(0xFF818A98),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF369C99)
                      : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconRail extends StatelessWidget {
  final SidebarTab activeTab;
  final List<SidebarTab> visibleTabs;
  final ValueChanged<SidebarTab> onTabSelected;
  final VoidCallback onLogout;
  final bool compact;

  const _IconRail({
    required this.activeTab,
    required this.visibleTabs,
    required this.onTabSelected,
    required this.onLogout,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final railWidth = compact ? 66.0 : 78.0;

    return Container(
      width: railWidth,
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFD),
        border: Border(right: BorderSide(color: Color(0xFFE8EBF0))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: compact ? 24 : 28,
                child: Image.asset(
                  AppImages.brandingLogo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Iconsax.blur,
                    size: 18,
                    color: Color(0xFF4EA6A3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE8EBF0)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final tab in visibleTabs)
                    _IconRailItem(
                      label: tab.label,
                      icon: tab.icon,
                      selected: tab == activeTab,
                      compact: compact,
                      onTap: () => onTabSelected(tab),
                    ),
                ],
              ),
            ),
            _IconRailItem(
              label: 'Logout',
              icon: Iconsax.logout,
              selected: false,
              compact: compact,
              onTap: onLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _IconRailItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _IconRailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 18.0 : 20.0;
    final itemHeight = compact ? 36.0 : 40.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: itemHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected ? const Color(0xFFE6F4F3) : null,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: selected
                  ? const Color(0xFF369C99)
                  : const Color(0xFF818A98),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAppBar extends StatefulWidget {
  final String title;
  final bool compact;
  final bool narrow;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenOrdersFromNotifications;
  final VoidCallback onOpenCoreTeamFromNotifications;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onLogout;
  final String userName;
  final String userSubtitle;
  final bool canSeeCoreTeamNotifications;

  const _TopAppBar({
    required this.title,
    required this.compact,
    required this.narrow,
    required this.onOpenSettings,
    required this.onOpenOrdersFromNotifications,
    required this.onOpenCoreTeamFromNotifications,
    required this.onSearchSubmitted,
    required this.onLogout,
    required this.userName,
    required this.userSubtitle,
    required this.canSeeCoreTeamNotifications,
  });

  @override
  State<_TopAppBar> createState() => _TopAppBarState();
}

class _TopAppBarState extends State<_TopAppBar> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<_ShellNotificationItem> _notifications =
      <_ShellNotificationItem>[];
  final Set<String> _inventorySyncInFlight = <String>{};
  final Map<String, String> _knownOrderStatusByDocId = <String, String>{};
  final Map<String, String> _knownPaymentStatusByDocId = <String, String>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;
  bool _orderSnapshotSeeded = false;
  bool _userSnapshotSeeded = false;
  final Set<String> _pendingUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _listenForOrderNotifications();
    if (widget.canSeeCoreTeamNotifications) {
      _listenForPendingUserNotifications();
    }
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((item) => !item.read).length;

  @override
  Widget build(BuildContext context) {
    final titleSize = widget.narrow ? 21.0 : 28.0;

    return SizedBox(
      height: widget.narrow ? 64 : 72,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.narrow ? 12 : 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1F29),
                ),
              ),
            ),
            if (!widget.narrow) ...[
              const _BackgroundUploadBadge(),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.compact ? 180 : 260,
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    widget.onSearchSubmitted(value.trim());
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search and jump...',
                    prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                    suffixIcon: _searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Iconsax.close_circle, size: 16),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE1E6EE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE1E6EE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF44A5A2)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
            ],
            _TopIconButton(
              icon: Iconsax.notification,
              onTap: _openNotificationsSheet,
              badgeCount: _unreadCount,
            ),
            const SizedBox(width: 8),
            _TopIconButton(icon: Iconsax.setting, onTap: widget.onOpenSettings),
            SizedBox(width: widget.narrow ? 8 : 14),
            Container(width: 1, height: 26, color: const Color(0xFFE8EBF0)),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0x1A0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              offset: const Offset(0, 42),
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    widget.onOpenSettings();
                    break;
                  case 'logout':
                    widget.onLogout();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFDCE6EA),
                    child: Icon(Iconsax.user, color: Color(0xFF4C596D)),
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            color: Color(0xFF1A1F29),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.userSubtitle,
                          style: const TextStyle(
                            color: Color(0xFF7D8592),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    const Icon(Iconsax.arrow_down_1, color: Color(0xFF7D8592)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotificationsSheet() {
    if (_notifications.any((item) => !item.read)) {
      setState(() {
        for (final item in _notifications) {
          item.read = true;
        }
      });
    }
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: const Color(0x88000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: SizedBox(
              width: 420,
              height: double.infinity,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _notifications.clear());
                            },
                            child: const Text('Clear'),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Iconsax.close_circle),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8EBF0)),
                    Expanded(
                      child: _notifications.isEmpty
                          ? const Center(
                              child: Text(
                                'No new notifications.',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _notifications.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFE8EBF0),
                              ),
                              itemBuilder: (context, index) {
                                final item = _notifications[index];
                                return ListTile(
                                  leading: Icon(
                                    item.icon,
                                    color: const Color(0xFF0F766E),
                                  ),
                                  title: Text(item.title),
                                  subtitle: Text(item.message),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _openNotificationTarget(item.target);
                                  },
                                  trailing: Text(
                                    _formatNotificationTime(item.createdAt),
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
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

  void _listenForOrderNotifications() {
    _ordersSub = _firestore
        .collection(FirestoreCollections.orders)
        .snapshots()
        .listen(
          (snapshot) {
            if (!_orderSnapshotSeeded) {
              for (final doc in snapshot.docs) {
                final data = doc.data();
                _knownOrderStatusByDocId[doc.id] = _statusLabel(
                  _stringOr(data['orderStatus'], fallback: 'processing'),
                );
                _knownPaymentStatusByDocId[doc.id] = _paymentLabel(
                  _stringOr(data['paymentStatus'], fallback: 'pending'),
                );
                if (!_isInventorySynced(data)) {
                  unawaited(_syncInventoryForOrder(doc));
                }
              }
              _orderSnapshotSeeded = true;
              return;
            }

            for (final change in snapshot.docChanges) {
              final data = change.doc.data();
              if (data == null) continue;

              final orderId = _stringOr(
                data['id'],
                fallback: change.doc.id,
              ).trim();
              final nextStatus = _statusLabel(
                _stringOr(data['orderStatus'], fallback: 'processing'),
              );
              final nextPayment = _paymentLabel(
                _stringOr(data['paymentStatus'], fallback: 'pending'),
              );

              if (change.type == DocumentChangeType.added &&
                  !_knownOrderStatusByDocId.containsKey(change.doc.id)) {
                _pushNotification(
                  title: 'New order received',
                  message: '$orderId was placed.',
                  icon: Iconsax.box,
                );
              }

              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                if (!_isInventorySynced(data)) {
                  unawaited(_syncInventoryForOrder(change.doc));
                }
              }

              if (change.type == DocumentChangeType.modified) {
                final previousStatus = _knownOrderStatusByDocId[change.doc.id];
                if (previousStatus != null && previousStatus != nextStatus) {
                  _pushNotification(
                    title: 'Order status changed',
                    message: '$orderId: $previousStatus to $nextStatus',
                    icon: Iconsax.refresh,
                  );
                }

                final previousPayment =
                    _knownPaymentStatusByDocId[change.doc.id];
                if (previousPayment != null && previousPayment != nextPayment) {
                  _pushNotification(
                    title: 'Payment status updated',
                    message: '$orderId: $previousPayment to $nextPayment',
                    icon: Iconsax.notification,
                  );
                }
              }

              if (change.type == DocumentChangeType.removed) {
                _knownOrderStatusByDocId.remove(change.doc.id);
                _knownPaymentStatusByDocId.remove(change.doc.id);
              } else {
                _knownOrderStatusByDocId[change.doc.id] = nextStatus;
                _knownPaymentStatusByDocId[change.doc.id] = nextPayment;
              }
            }
          },
          onError: (_) {
            _pushNotification(
              title: 'Notification issue',
              message: 'Realtime order updates are temporarily unavailable.',
              icon: Iconsax.warning_2,
            );
          },
        );
  }

  bool _isInventorySynced(Map<String, dynamic> order) {
    final sync = order['inventorySync'];
    if (sync is! Map) return false;
    final map = Map<String, dynamic>.from(sync);
    return map['stockDeducted'] == true;
  }

  Future<void> _syncInventoryForOrder(
    DocumentSnapshot<Map<String, dynamic>> orderDoc,
  ) async {
    if (_inventorySyncInFlight.contains(orderDoc.id)) return;
    _inventorySyncInFlight.add(orderDoc.id);
    try {
      await _firestore.runTransaction((tx) async {
        final freshOrder = await tx.get(orderDoc.reference);
        final order = freshOrder.data();
        if (!freshOrder.exists || order == null) return;
        if (_isInventorySynced(order)) return;

        final rawItems = order['items'];
        if (rawItems is! List || rawItems.isEmpty) {
          tx.set(orderDoc.reference, {
            'inventorySync': {
              'stockDeducted': true,
              'deductedBy': 'admin_client_sync',
              'deductedAt': FieldValue.serverTimestamp(),
              'warningCount': 1,
              'warnings': ['No valid items found in order.'],
            },
          }, SetOptions(merge: true));
          return;
        }

        final consumeByProduct = <String, double>{};
        for (final item in rawItems) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final productDocId = _normalizeProductDocId(map['productCode']);
          if (productDocId.isEmpty) continue;
          final qtyBase = _doubleOr(map['qtyBase']);
          final qty = _doubleOr(map['qty']);
          final conversion = _doubleOr(map['conversionToBaseUnit']);
          final resolvedQtyBase = qtyBase > 0 ? qtyBase : (qty * conversion);
          if (resolvedQtyBase <= 0) continue;
          consumeByProduct.update(
            productDocId,
            (value) => value + resolvedQtyBase,
            ifAbsent: () => resolvedQtyBase,
          );
        }

        final warnings = <String>[];
        for (final entry in consumeByProduct.entries) {
          final productRef = _firestore
              .collection(FirestoreCollections.products)
              .doc(entry.key);
          final productSnap = await tx.get(productRef);
          if (!productSnap.exists) {
            warnings.add('Missing product: ${entry.key}');
            continue;
          }
          final product = productSnap.data() ?? <String, dynamic>{};
          final inventory = _asMap(product['inventory']);
          final currentAvailable =
              _doubleOr(inventory['availableQtyBaseUnit']) > 0
              ? _doubleOr(inventory['availableQtyBaseUnit'])
              : _doubleOr(inventory['baseUnitQty']);
          final requested = entry.value;
          if (currentAvailable < requested) {
            warnings.add(
              'Stock low for ${entry.key}: requested ${requested.toStringAsFixed(2)}, available ${currentAvailable.toStringAsFixed(2)}',
            );
          }
          final nextAvailable = (currentAvailable - requested).clamp(
            0.0,
            double.infinity,
          );
          tx.set(productRef, {
            'inventory': {'availableQtyBaseUnit': nextAvailable},
            'audit': {'updatedAt': FieldValue.serverTimestamp()},
          }, SetOptions(merge: true));
        }

        tx.set(orderDoc.reference, {
          'inventorySync': {
            'stockDeducted': true,
            'deductedBy': 'admin_client_sync',
            'deductedAt': FieldValue.serverTimestamp(),
            'warningCount': warnings.length,
            'warnings': warnings.take(20).toList(),
          },
        }, SetOptions(merge: true));
      });
    } catch (_) {
      // Keep silent in UI; this path retries on next order stream update.
    } finally {
      _inventorySyncInFlight.remove(orderDoc.id);
    }
  }

  String _normalizeProductDocId(dynamic code) {
    if (code is! String) return '';
    return code.replaceAll('#', '').trim().toLowerCase();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry('$k', v));
    }
    return <String, dynamic>{};
  }

  double _doubleOr(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  void _pushNotification({
    required String title,
    required String message,
    required IconData icon,
    _ShellNotificationTarget target = _ShellNotificationTarget.orders,
  }) {
    if (!mounted) return;
    setState(() {
      _notifications.insert(
        0,
        _ShellNotificationItem(
          title: title,
          message: message,
          icon: icon,
          createdAt: DateTime.now(),
          target: target,
        ),
      );
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }
    });
  }

  void _openNotificationTarget(_ShellNotificationTarget target) {
    switch (target) {
      case _ShellNotificationTarget.orders:
        widget.onOpenOrdersFromNotifications();
        break;
      case _ShellNotificationTarget.coreTeam:
        widget.onOpenCoreTeamFromNotifications();
        break;
    }
  }

  void _listenForPendingUserNotifications() {
    _usersSub = _firestore
        .collection(FirestoreCollections.users)
        .snapshots()
        .listen(
          (snapshot) {
            final currentPendingIds = <String>{};
            for (final doc in snapshot.docs) {
              final data = doc.data();
              if (_isPendingUser(data)) {
                currentPendingIds.add(doc.id);
              }
            }

            if (!_userSnapshotSeeded) {
              _pendingUserIds
                ..clear()
                ..addAll(currentPendingIds);
              if (currentPendingIds.isNotEmpty) {
                _pushNotification(
                  title: 'Pending registrations',
                  message:
                      '${currentPendingIds.length} user(s) are waiting for approval (including salesmen).',
                  icon: Iconsax.user_tag,
                  target: _ShellNotificationTarget.coreTeam,
                );
              }
              _userSnapshotSeeded = true;
              return;
            }

            for (final change in snapshot.docChanges) {
              final data = change.doc.data();
              if (data == null) continue;
              final isPending = _isPendingUser(data);
              final id = change.doc.id;
              final wasPending = _pendingUserIds.contains(id);

              if (isPending && !wasPending) {
                final name = _stringOr(
                  data['fullName'],
                  fallback: _stringOr(data['email'], fallback: 'Unknown user'),
                );
                final requestedRole = _stringOr(
                  data['requestedRole'],
                  fallback: _stringOr(data['role'], fallback: 'Staff'),
                );
                _pushNotification(
                  title: 'New pending registration',
                  message: '$name requested $requestedRole access.',
                  icon: Iconsax.profile_2user,
                  target: _ShellNotificationTarget.coreTeam,
                );
                _pendingUserIds.add(id);
              } else if (!isPending && wasPending) {
                _pendingUserIds.remove(id);
              }
            }
          },
          onError: (_) {
            _pushNotification(
              title: 'Notification issue',
              message:
                  'Pending registration updates are temporarily unavailable.',
              icon: Iconsax.warning_2,
              target: _ShellNotificationTarget.coreTeam,
            );
          },
        );
  }

  bool _isPendingUser(Map<String, dynamic> user) {
    final approval = _stringOr(
      user['approvalStatus'],
      fallback: 'approved',
    ).toLowerCase();
    if (approval != 'pending') return false;
    final requestedRole = _stringOr(
      user['requestedRole'],
      fallback: _stringOr(user['role'], fallback: ''),
    ).toLowerCase();
    return requestedRole.contains('staff') ||
        requestedRole.contains('salesman') ||
        requestedRole.contains('sales');
  }

  String _statusLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'delivered':
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }

  String _paymentLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'partial':
      case 'partially_paid':
        return 'Partial';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  String _stringOr(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  String _formatNotificationTime(DateTime createdAt) {
    final hourRaw = createdAt.hour % 12;
    final hour = hourRaw == 0 ? 12 : hourRaw;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final suffix = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '${createdAt.month}/${createdAt.day} $hour:$minute $suffix';
  }
}

class _BackgroundUploadBadge extends StatelessWidget {
  const _BackgroundUploadBadge();

  @override
  Widget build(BuildContext context) {
    final service = BulkUploadBackgroundService.instance;
    return ValueListenableBuilder<BulkUploadStatus>(
      valueListenable: service.status,
      builder: (context, status, _) {
        if (!status.isRunning && status.total == 0) {
          return const SizedBox.shrink();
        }
        final text = status.isRunning
            ? 'Bulk ${status.completed}/${status.total}'
            : 'Bulk done ${status.success}/${status.total}';
        final bg = status.isRunning
            ? const Color(0xFFEAF4FF)
            : const Color(0xFFEFFAF3);
        final fg = status.isRunning
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF16803C);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDCE3EF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: status.isRunning
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        value: status.total == 0
                            ? null
                            : status.completed / status.total,
                        color: fg,
                      )
                    : Icon(Iconsax.tick_circle, size: 12, color: fg),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Ink(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE3E7EE)),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF4B5565)),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShellNotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final DateTime createdAt;
  final _ShellNotificationTarget target;
  bool read = false;

  _ShellNotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.createdAt,
    required this.target,
  });
}

enum _ShellNotificationTarget { orders, coreTeam }
