import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

class AppLocaleController extends Notifier<Locale> {
  static const _preferenceKey = 'interface_language';
  bool _changedByUser = false;

  @override
  Locale build() {
    Future<void>.microtask(_restore);
    return const Locale('fr');
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    if (_changedByUser) return;
    final languageCode = preferences.getString(_preferenceKey);
    if (languageCode == 'fr' || languageCode == 'en') {
      state = Locale(languageCode!);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'fr' && languageCode != 'en') return;
    _changedByUser = true;
    state = Locale(languageCode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, languageCode);
  }
}
