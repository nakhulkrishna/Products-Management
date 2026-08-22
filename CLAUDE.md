# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter **web** admin panel (package `products_catelogs`) for the Red Rose product catalog — Firebase project `products-managment-a23a7`, deployed to Firebase Hosting at https://products-managment-a23a7.web.app. Admins manage products, orders, customers, and salesmen (no approval flow — sign-ups are active immediately). It is the management counterpart to the salesman mobile app at `/Users/nakhulkrishna/red-rose-staff-app` (that repo has its own CLAUDE.md); both share the same Firestore database, so schema changes here ripple into that app.

Working branch: `Redesining` (note the typo — it is the real branch name). `main` exists but active work happens here.

## Commands

```bash
flutter pub get
flutter run -d chrome                 # develop (this is a web app)
flutter analyze
flutter test                          # includes test/access_control_test.dart
flutter build web --release --no-tree-shake-icons
npx firebase-tools deploy --only hosting --project products-managment-a23a7
```

- `--no-tree-shake-icons` is required: the plain release build fails with `IconTreeShakerException` on this machine.
- Hosting serves `build/web`, so **deploy only after building** — deploying without a fresh build ships the previous bundle.
- Cloud Functions live in `functions/` (Node): `deductInventoryOnOrderCreate` decrements product stock when a `catalog_orders` doc is created. Deploy with `firebase deploy --only functions`.
- Firestore rules are NOT deployed from this repo. The synced copy + rules notes live in the staff-app repo (`red-rose-staff-app/firestore.rules`).

## Architecture

Entry: `lib/main.dart` → `lib/app/app.dart` → `features/auth/presentation/pages/auth_gate.dart`. The gate streams `catalog_users/{uid}` and blocks only profile-less/invalid users; everyone else lands in `features/shell/presentation/pages/web_shell_page.dart` (sidebar shell).

- **State:** Riverpod is present but most screens are large self-contained `StatefulWidget` "tab pages" (1,500–3,300 lines each) that talk to Firestore directly — `orders_tab_page.dart` (3.3k), `staffs_tab_page.dart` (2.6k). Expect to edit inside these monoliths rather than a layered data/domain stack (only `products` has a real repository: `features/products/data/repositories/products_repository.dart`).
- **Access control:** `lib/core/access/` — roles `Admin`, `Developer`, `Staff` (`appUserRoleFromRaw` fuzzy-matches strings: anything containing `admin|manager` → Admin, `developer|dev` → Developer, everything else incl. `Salesman` → Staff). Permission keys: `products, orders, customers, staffs, settings` (Dashboard and Core Team tabs were removed Aug 2026; old `dashboard`/`coreTeam` permission entries in Firestore are ignored); effective permissions = role defaults ∩ explicit `permissions` map, with `settings` always allowed. Tested in `test/access_control_test.dart`.
- **No approval flow (removed Aug 2026):** sign-ups are immediately approved/active on both apps; there are no approve/deactivate/ban controls. `approvalStatus`/`isActive` are still written as `'approved'`/`true` for old-build compatibility but nothing reads them.
- **Numbers stored as strings:** bulk-uploaded product docs store numeric fields as strings (`"conversionToBaseUnit": "5"`, `"manualPriceQar": "22"`). Always parse with the tolerant `_toDouble` pattern (`num` or `double.tryParse`), never bare `as num?` casts.
- **Price model:** `pricing.markets.{hyper_market|local_market}.prices.{unitKey}` with `manualPriceQar`/`autoPriceQar` (+ offer variants) and `overrideEnabled`. Resolution order used by the orders screen (`_PriceForUnit.resolvedPrice`): `manualOffer ?? autoOffer ?? manual ?? auto`. The staff app was made to match this exactly — keep them in sync.
- **Images:** product images upload to Cloudinary (`core/constants/cloudinary_constants.dart`), not Firebase Storage.
- **Platform-conditional utils:** `core/utils/` uses stub/web pairs (`file_download_web.dart` etc.) for downloads/URL-launching; follow that pattern for any new web-only capability.

## Firestore (shared with the staff app)

Collections: `catalog_users` (doc id = Firebase Auth UID; roles/permissions/approval), `catalog_staff_salesmen` (admin-created docs use `SM-###` ids; staff-app sign-ups create UID-keyed docs — both shapes exist), `catalog_products`, `catalog_product_categories`, `catalog_orders`, `catalog_customers`, `_catalog_order_counters`, `catalog_app_config` (shared settings). Legacy collections (`Admin`, `staff`, `products`, `orders`, `customers`, `order_whatsapp`, `AppConfig`) belong to the retired SHA-256-auth apps and are world-read/write in the live rules — don't build new features on them.

**Order WhatsApp number:** a single shared setting. Settings tab saves it to `catalog_app_config/order_whatsapp` (`number`) and mirrors to legacy `order_whatsapp/main_number` plus the admin's own `catalog_users` doc; the staff app reads config-first, legacy-fallback. Keep all writes going through `_saveUserProfile` in `settings_tab_page.dart`.

## Gotchas

- The `catalog_app_config` rule (`read: signedIn, write: isAdmin`) exists in the staff-app repo's rules file but may not be deployed — the config write in Settings is wrapped best-effort for that reason.
- Auth sign-up here creates `catalog_users/{uid}` with `role: 'Staff'`, `approvalStatus: 'approved'`, `isActive: true` — usable immediately.
- Bans were removed from the staff app; the legacy `banCatalogUser`/`unbanCatalogUser` Cloud Functions may still be deployed but nothing calls them.
- Salesman ↔ user linkage is by lowercased email, not UID. A salesman doc whose email differs from the login email won't be activated by the Staffs-tab toggle.
