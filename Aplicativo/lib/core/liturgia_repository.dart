import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'liturgia.dart';
import 'liturgia_service.dart';

class LiturgiaRepository {
  LiturgiaRepository({LiturgiaService? service, SharedPreferences? preferences})
    : service = service ?? LiturgiaService(),
      _preferences = preferences;

  final LiturgiaService service;
  SharedPreferences? _preferences;

  Future<SharedPreferences> _getPrefs() async {
    if (_preferences != null) return _preferences!;
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }

  String _cacheKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'liturgia_cache_${y}_${m}_$d';
  }

  /// Tenta carregar do cache local primeiro, senão consulta a API e salva no cache.
  Future<Liturgia> getLiturgia(DateTime date) async {
    final key = _cacheKey(date);

    // 1. Tenta recuperar do cache local
    try {
      final prefs = await _getPrefs();
      final cachedJson = prefs.getString(key);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        return Liturgia.fromJson(decoded);
      }
    } catch (_) {
      // Falha ao ler cache, tenta a API
    }

    // 2. Consulta a API externa
    final rawJson = await service.fetchLiturgiaRaw(date);
    final liturgia = Liturgia.fromJson(rawJson);

    // 3. Salva no cache local
    try {
      final prefs = await _getPrefs();
      await prefs.setString(key, jsonEncode(rawJson));
    } catch (_) {
      // Ignora erro de escrita no cache
    }

    return liturgia;
  }
}
