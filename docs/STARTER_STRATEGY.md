# Starter Strategy: Feature-Based + Riverpod (Web Sidebar Shell)

## Goal
- Keep one stable web layout shell (sidebar + body).
- Change only the body content by sidebar tab.
- Avoid full-page navigation for core workspace tabs.

## Current Base
- Sidebar state: `lib/features/shell/application/sidebar_tab_provider.dart`
- Sidebar enum: `lib/features/shell/domain/sidebar_tab.dart`
- Stable shell: `lib/features/shell/presentation/pages/web_shell_page.dart`
- Sidebar widget: `lib/features/shell/presentation/widgets/web_sidebar.dart`
- Tab pages:
  - Dashboard: `lib/features/dashboard/presentation/pages/dashboard_tab_page.dart`
  - Products: `lib/features/products/presentation/pages/products_tab_page.dart`
  - Orders: `lib/features/orders/presentation/pages/orders_tab_page.dart`
  - Settings: `lib/features/settings/presentation/pages/settings_tab_page.dart`

## Folder Pattern (per feature)
- `application/`: Riverpod providers, controllers, use-cases
- `domain/`: entities, value objects, business rules
- `data/`: repositories, DTOs, remote/local sources
- `presentation/`: pages, widgets, view models

## Rules
1. Sidebar shell must remain mounted.
2. Body uses `IndexedStack` so tabs preserve state.
3. Use Riverpod providers for tab-level state and data loading.
4. Keep shared constants/components in `lib/core` and `lib/features/shared`.
5. Add navigation routes only for flows outside the main shell (e.g. login, detail modals, wizards).

## Next Implementation Steps
1. Add `data/` + repository contracts for each feature.
2. Replace placeholder tab pages with real screens.
3. Add async providers (`FutureProvider`/`NotifierProvider`) per feature.
4. Add shared error/loading widgets.
5. Add tests for providers and shell-tab behavior.
