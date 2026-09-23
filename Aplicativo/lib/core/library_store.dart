import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryStore extends ChangeNotifier {
  static const _favoriteKey = 'cifra_santa_favorites_v1';
  final Set<String> _favorites = <String>{};
  SharedPreferences? _preferences;

  Set<String> get favorites => Set.unmodifiable(_favorites);
  bool isFavorite(String songId) => _favorites.contains(songId);

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    _favorites.addAll(_preferences!.getStringList(_favoriteKey) ?? const <String>[]);
    notifyListeners();
  }

  Future<void> toggleFavorite(String songId) async {
    if (!_favorites.add(songId)) _favorites.remove(songId);
    notifyListeners();
    await _preferences?.setStringList(_favoriteKey, _favorites.toList());
  }
}
