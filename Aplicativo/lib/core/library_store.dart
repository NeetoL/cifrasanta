import 'dart:async';

import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryStore extends ChangeNotifier {
  LibraryStore({ApiClient? api}) : api = api ?? ApiClient();
  final ApiClient api;
  final Set<String> _favorites = <String>{};
  bool loading = false;
  bool hasLoaded = false;
  SharedPreferences? _preferences;
  final List<String> _recentSearches = [];
  double _fontSize = 12.0;

  List<Song> get recentSearches =>
      _recentSearches.map(Catalog.song).whereType<Song>().take(10).toList();

  double get fontSize => _fontSize;

  bool _historyReady = false;

  Future<void> initializeHistory() async {
    if (_historyReady) return;
    _historyReady = true;
    try {
      _preferences = await SharedPreferences.getInstance();
      _recentSearches
        ..clear()
        ..addAll(
          (_preferences!.getStringList('recent_search_songs') ?? [])
              .toSet()
              .take(10),
        );
      _fontSize = (_preferences!.getDouble('chord_font_size') ?? 12.0).clamp(
        8.0,
        28.0,
      );
    } catch (_) {
      // A busca continua disponível se o armazenamento local falhar.
    }
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(8.0, 28.0);
    notifyListeners();
    try {
      await _preferences?.setDouble('chord_font_size', _fontSize);
    } catch (_) {
      // A preferência em memória permanece durante a sessão.
    }
  }

  Future<void> rememberSearch(Song song) async {
    _recentSearches.remove(song.id);
    _recentSearches.insert(0, song.id);
    if (_recentSearches.length > 10) {
      _recentSearches.removeRange(10, _recentSearches.length);
    }
    notifyListeners();
    try {
      await _preferences?.setStringList(
        'recent_search_songs',
        List.of(_recentSearches),
      );
    } catch (_) {
      // O histórico em memória permanece disponível durante esta sessão.
    }
  }

  bool _savingFavorite = false;
  String? catalogError;
  String? message;
  String? userName;
  String? userRole;
  int _sessionVersion = 0;

  bool get signedIn => api.token != null;

  /// Leitura da Bíblia é restrita às contas de administrador na API.
  bool get canReadBible => signedIn && userRole == 'admin';

  static const _tokenKey = 'session_token';
  static const _nameKey = 'session_name';
  static const _roleKey = 'session_role';

  /// Recupera a sessão salva, para não exigir login a cada abertura.
  Future<void> restoreSession() async {
    await initializeHistory();
    final saved = _preferences?.getString(_tokenKey);
    if (saved == null || api.token != null) return;
    final version = ++_sessionVersion;
    api.token = saved;
    userName = _preferences?.getString(_nameKey);
    userRole = _preferences?.getString(_roleKey);
    notifyListeners();
    try {
      final me = await api.request('me');
      if (version != _sessionVersion) return;
      _applyUser(me['usuario'] as Map<String, dynamic>);
      final favorites = await api.request('favorites');
      if (version != _sessionVersion) return;
      _favorites
        ..clear()
        ..addAll(List<String>.from(favorites['favorites'] as List));
      notifyListeners();
    } catch (error) {
      // Sem conexão, a sessão salva continua valendo; só um 401 a encerra.
      if (version == _sessionVersion &&
          error is ApiException &&
          error.status == 401) {
        await _clearSession();
      }
    }
  }

  void _applyUser(Map<String, dynamic> user) {
    userName = user['nome'] as String?;
    userRole = user['papel'] as String?;
    unawaited(_saveSession());
  }

  Future<void> _saveSession() async {
    final token = api.token;
    if (token == null) return;
    try {
      await _preferences?.setString(_tokenKey, token);
      await _preferences?.setString(_nameKey, userName ?? '');
      await _preferences?.setString(_roleKey, userRole ?? 'usuario');
    } catch (_) {
      // Sem armazenamento local, a sessão vale até o aplicativo ser fechado.
    }
  }

  Future<void> _clearSession() async {
    _sessionVersion++;
    api.token = null;
    userName = null;
    userRole = null;
    _favorites.clear();
    notifyListeners();
    try {
      await _preferences?.remove(_tokenKey);
      await _preferences?.remove(_nameKey);
      await _preferences?.remove(_roleKey);
    } catch (_) {
      // Nada a limpar se o armazenamento local não estiver disponível.
    }
  }

  Set<String> get favorites => Set.unmodifiable(_favorites);
  bool isFavorite(String songId) => _favorites.contains(songId);

  Future<void> load() async {
    if (loading) return;
    loading = true;
    catalogError = null;
    notifyListeners();
    try {
      Catalog.replace(await api.request('catalog'));
      hasLoaded = true;
    } catch (error) {
      catalogError = error is ApiException
          ? error.message
          : 'Não foi possível carregar o catálogo.';
      if (hasLoaded) message = catalogError;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password, {String? name}) async {
    final version = ++_sessionVersion;
    try {
      final result = await api.request(
        name == null ? 'login' : 'register',
        method: 'POST',
        data: {'email': email, 'senha': password, 'nome': ?name},
      );
      if (version != _sessionVersion) {
        return 'A sessão foi alterada. Tente novamente.';
      }
      api.token = result['token'] as String;
      _applyUser(result['usuario'] as Map<String, dynamic>);
      _favorites.clear();
      try {
        final favorites = await api.request('favorites');
        if (version != _sessionVersion) return 'A sessão foi alterada.';
        _favorites.addAll(List<String>.from(favorites['favorites'] as List));
      } catch (error) {
        if (error is ApiException && error.status == 401) rethrow;
        if (version != _sessionVersion) return 'A sessão foi alterada.';
        message = 'Você entrou. Não foi possível carregar os favoritos agora.';
      }
      notifyListeners();
      return null;
    } catch (error) {
      if (version == _sessionVersion) await _clearSession();
      return error is ApiException
          ? error.message
          : 'Não foi possível entrar. Tente novamente.';
    }
  }

  Future<String?> signOut() async {
    try {
      await api.request('logout', method: 'POST', data: {});
    } catch (error) {
      if (error is! ApiException || error.status != 401) {
        return error is ApiException
            ? error.message
            : 'Não foi possível sair. Tente novamente.';
      }
    }
    await _clearSession();
    return null;
  }

  Future<void> toggleFavorite(String songId) async {
    message = null;
    if (!signedIn) {
      message = 'Entre em Minha conta para salvar seus favoritos.';
      notifyListeners();
      return;
    }
    if (_savingFavorite) return;
    _savingFavorite = true;
    final version = _sessionVersion;
    try {
      final result = await api.request(
        'favorites',
        method: 'PUT',
        data: {'songId': songId, 'favorite': !_favorites.contains(songId)},
      );
      if (version == _sessionVersion) {
        _favorites
          ..clear()
          ..addAll(List<String>.from(result['favorites'] as List));
      }
    } catch (error) {
      if (version == _sessionVersion) {
        if (error is ApiException && error.status == 401) {
          await _clearSession();
        }
        message = error is ApiException
            ? error.message
            : 'Não foi possível salvar o favorito.';
      }
    } finally {
      _savingFavorite = false;
      notifyListeners();
    }
  }
}
