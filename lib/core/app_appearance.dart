import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appAppearanceProvider =
    StateNotifierProvider<AppAppearanceController, Brightness>(
      (ref) => AppAppearanceController(),
    );

class AppAppearanceController extends StateNotifier<Brightness> {
  AppAppearanceController() : super(Brightness.dark) {
    _load();
  }

  bool _changed = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || _changed) return;
    state = prefs.getBool('light_mode') == true
        ? Brightness.light
        : Brightness.dark;
  }

  Future<void> setLightMode(bool enabled) async {
    _changed = true;
    state = enabled ? Brightness.light : Brightness.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('light_mode', enabled);
  }
}
