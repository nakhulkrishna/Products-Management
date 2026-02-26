# Products Catalogs (Web Branch)

This branch is configured for web-first usage.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## Structure

- `lib/core/constants/`
  - `app_colors.dart`
  - `app_images.dart`
  - `app_strings.dart`
- `lib/authentication/`
  - Single auth screen (`sign in` / `sign up`) with in-place form switching
  - Web auth shell layout
