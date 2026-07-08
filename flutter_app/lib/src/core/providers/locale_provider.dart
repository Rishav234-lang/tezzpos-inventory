import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/providers.dart';

const _localeKey = 'app_locale';

final supportedLocales = const [
  Locale('en'),
  Locale('hi'),
  Locale('mr'),
];

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(_loadLocale(_prefs));

  static Locale _loadLocale(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey);
    if (code != null) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    await _prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }

  Future<void> setLanguageCode(String code) async {
    await setLocale(Locale(code));
  }
}
