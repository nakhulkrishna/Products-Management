import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/features/shell/domain/sidebar_tab.dart';

final sidebarTabProvider = StateProvider<SidebarTab>(
  (ref) => SidebarTab.dashboard,
);
