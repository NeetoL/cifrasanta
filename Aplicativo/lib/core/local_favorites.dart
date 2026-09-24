import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de conteúdo favoritável. As cifras continuam sendo salvas na conta
/// (LibraryStore); estes tipos são guardados no aparelho.
enum FavoriteKind { prayer, verse, reading }

class LocalFavoritesStore extends ChangeNotifier {
  LocalFavoritesStore();

  final Map<FavoriteKind, Set<String>> _ids = {
    for (final kind in FavoriteKind.values) kind: <String>{},
  };
  SharedPreferences? _preferences;

  String _key(FavoriteKind kind) => 'favorites_${kind.name}';

  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      for (final kind in FavoriteKind.values) {
        _ids[kind]!
          ..clear()
          ..addAll(_preferences!.getStringList(_key(kind)) ?? const []);
      }
      notifyListeners();
    } catch (_) {
      // Sem armazenamento local os favoritos valem apenas durante a sessão.
    }
  }

  Set<String> ids(FavoriteKind kind) => Set.unmodifiable(_ids[kind]!);

  bool isFavorite(FavoriteKind kind, String id) => _ids[kind]!.contains(id);

  Future<void> toggle(FavoriteKind kind, String id) async {
    final ids = _ids[kind]!;
    if (!ids.remove(id)) ids.add(id);
    notifyListeners();
    try {
      await _preferences?.setStringList(_key(kind), ids.toList());
    } catch (_) {
      // A alteração permanece em memória durante a sessão.
    }
  }
}
