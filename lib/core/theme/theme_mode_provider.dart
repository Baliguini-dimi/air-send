import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(const FlutterSecureStorage()),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._storage) : super(ThemeMode.system) {
    _restore();
  }

  static const _storageKey = 'app_theme_mode';
  final FlutterSecureStorage _storage;

  Future<void> _restore() async {
    try {
      final value = await _storage.read(key: _storageKey);
      if (value == 'light') state = ThemeMode.light;
      if (value == 'dark') state = ThemeMode.dark;
    } catch (_) {
      // Keep system theme if the preference cannot be read.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: _storageKey,
      value: switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      },
    );
  }
}
