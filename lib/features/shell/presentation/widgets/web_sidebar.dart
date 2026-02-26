import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/core/constants/app_images.dart';
import 'package:products_catelogs/core/constants/app_strings.dart';
import 'package:products_catelogs/features/products/application/bulk_upload_background_service.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

class WebShellScaffold extends StatelessWidget {
  final SidebarTab activeTab;
  final ValueChanged<SidebarTab> onTabSelected;
  final Widget body;

  const WebShellScaffold({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
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
                    compact: isCompact,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopAppBar(
                          title: activeTab.label,
                          compact: isCompact,
                          narrow: isNarrow,
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
  final bool compact;

  const _IconRail({
    required this.activeTab,
    required this.onTabSelected,
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
              onTap: () {},
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

class _TopAppBar extends StatelessWidget {
  final String title;
  final bool compact;
  final bool narrow;

  const _TopAppBar({
    required this.title,
    required this.compact,
    required this.narrow,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = narrow ? 21.0 : 28.0;

    return SizedBox(
      height: narrow ? 64 : 72,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1F29),
                ),
              ),
            ),
            if (!narrow) ...[
              const _BackgroundUploadBadge(),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 180 : 260),
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
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
                ),
              ),
              const SizedBox(width: 10),
            ],
            const _TopIconButton(icon: Icons.notifications_none_rounded),
            const SizedBox(width: 8),
            const _TopIconButton(icon: Icons.settings_outlined),
            SizedBox(width: narrow ? 8 : 14),
            Container(width: 1, height: 26, color: const Color(0xFFE8EBF0)),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFDCE6EA),
                  child: Icon(Icons.person_rounded, color: Color(0xFF4C596D)),
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ArtTemplate',
                        style: TextStyle(
                          color: Color(0xFF1A1F29),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        AppStrings.appTagline,
                        style: TextStyle(
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
          ],
        ),
      ),
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

  const _TopIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {},
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
