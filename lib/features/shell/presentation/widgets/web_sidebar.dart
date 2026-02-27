import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/core/constants/app_images.dart';
import 'package:products_catelogs/features/products/application/bulk_upload_background_service.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

class WebShellScaffold extends StatelessWidget {
  final SidebarTab activeTab;
  final ValueChanged<SidebarTab> onTabSelected;
  final VoidCallback onLogout;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onSearchSubmitted;
  final String userName;
  final String userSubtitle;
  final Widget body;

  const WebShellScaffold({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onLogout,
    required this.onOpenSettings,
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
                          onSearchSubmitted: onSearchSubmitted,
                          onLogout: onLogout,
                          userName: userName,
                          userSubtitle: userSubtitle,
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

class _IconRail extends StatelessWidget {
  final SidebarTab activeTab;
  final ValueChanged<SidebarTab> onTabSelected;
  final VoidCallback onLogout;
  final bool compact;

  const _IconRail({
    required this.activeTab,
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
                    Icons.blur_on_rounded,
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
                  for (final tab in SidebarTab.values)
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
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onLogout;
  final String userName;
  final String userSubtitle;

  const _TopAppBar({
    required this.title,
    required this.compact,
    required this.narrow,
    required this.onOpenSettings,
    required this.onSearchSubmitted,
    required this.onLogout,
    required this.userName,
    required this.userSubtitle,
  });

  @override
  State<_TopAppBar> createState() => _TopAppBarState();
}

class _TopAppBarState extends State<_TopAppBar> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _notifications = <String>[
    'New order placed: ORD-5301',
    'Bulk upload completed successfully',
    'Low stock warning for 4 products',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
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
              icon: Icons.notifications_none_rounded,
              onTap: _openNotificationsSheet,
            ),
            const SizedBox(width: 8),
            _TopIconButton(
              icon: Icons.settings_outlined,
              onTap: widget.onOpenSettings,
            ),
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
                  child: Icon(Icons.person_rounded, color: Color(0xFF4C596D)),
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
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF7D8592),
                  ),
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
                            icon: const Icon(Icons.close_rounded),
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
                                return ListTile(
                                  leading: const Icon(
                                    Icons.notifications_active_outlined,
                                  ),
                                  title: Text(_notifications[index]),
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
                    : Icon(Icons.check_circle_rounded, size: 12, color: fg),
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

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
    );
  }
}
