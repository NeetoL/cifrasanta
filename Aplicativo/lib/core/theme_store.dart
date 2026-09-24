import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema escolhido em Configurações: automático (segue o celular), claro ou escuro.
class ThemeStore extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  SharedPreferences? _preferences;

  ThemeMode get mode => _mode;

  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final saved = _preferences!.getString(_key);
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (mode != null && mode != _mode) {
        _mode = mode;
        notifyListeners();
      }
    } catch (_) {
      // Sem armazenamento local, o tema segue o celular.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _preferences?.setString(_key, mode.name);
    } catch (_) {
      // A escolha continua valendo até o aplicativo ser fechado.
    }
  }
}
