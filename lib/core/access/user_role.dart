enum AppUserRole { admin, developer, staff }

extension AppUserRoleX on AppUserRole {
  String get label {
    switch (this) {
      case AppUserRole.admin:
        return 'Admin';
      case AppUserRole.developer:
        return 'Developer';
      case AppUserRole.staff:
        return 'Staff';
    }
  }

  String get firestoreValue => label;
}

AppUserRole appUserRoleFromRaw(Object? rawRole) {
  final normalized = rawRole?.toString().trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return AppUserRole.staff;
  if (normalized.contains('admin') || normalized.contains('manager')) {
    return AppUserRole.admin;
  }
  if (normalized.contains('developer') || normalized == 'dev') {
    return AppUserRole.developer;
  }
  return AppUserRole.staff;
}
