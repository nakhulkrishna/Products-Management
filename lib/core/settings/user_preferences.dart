import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserPreferences {
  final String currency;
  final String language;
  final String timezone;

  const UserPreferences({
    required this.currency,
    required this.language,
    required this.timezone,
  });

  static const defaults = UserPreferences(
    currency: 'QAR',
    language: 'English',
    timezone: 'Asia/Qatar (GMT+3)',
  );

  bool get isArabic => language.trim().toLowerCase() == 'arabic';

  Locale get locale => isArabic ? const Locale('ar') : const Locale('en');

  String get numberLocale => isArabic ? 'ar_QA' : 'en_QA';

  NumberFormat currencyFormatter({int decimalDigits = 0}) {
    return NumberFormat.currency(
      locale: numberLocale,
      symbol: '$currency ',
      decimalDigits: decimalDigits,
    );
  }

  DateFormat dateFormatter([String pattern = 'yyyy-MM-dd']) {
    return DateFormat(pattern, isArabic ? 'ar' : 'en');
  }
}

UserPreferences userPreferencesFromProfile(Map<String, dynamic>? profile) {
  String readString(String key, String fallback) {
    final value = profile?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  return UserPreferences(
    currency: readString('currency', UserPreferences.defaults.currency),
    language: readString('language', UserPreferences.defaults.language),
    timezone: readString('timezone', UserPreferences.defaults.timezone),
  );
}
