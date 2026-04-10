import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'connection_provider.dart';

enum AppThemeMode { system, dark, light }

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final storage = ref.read(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(_loadInitial(_storage));

  static AppThemeMode _loadInitial(StorageService storage) {
    final saved = storage.themeMode;
    return switch (saved) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  void setMode(AppThemeMode mode) {
    state = mode;
    _storage.themeMode = mode.name;
  }
}

ThemeMode toFlutterThemeMode(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
  };
}
