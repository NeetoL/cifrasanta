import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'library_store.dart';

class PersonalList {
  PersonalList({
    required this.id,
    required this.title,
    required List<String> songIds,
    required this.local,
    this.version = 1,
  }) : songIds = List.unmodifiable(songIds);
  final String id;
  final String title;
  final List<String> songIds;
  final bool local;
  final int version;
  factory PersonalList.fromJson(
    Map<String, dynamic> json, {
    required bool local,
  }) => PersonalList(
    id: json['id'].toString(),
    title: json['title'] as String,
    songIds: List<String>.from(json['songIds'] as List),
    local: local,
    version: (json['version'] as num?)?.toInt() ?? 1,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'songIds': songIds,
    'version': version,
  };
}

class PersonalLists extends ChangeNotifier {
  PersonalLists(this.library) {
    library.addListener(_sessionChanged);
  }
  final LibraryStore library;
  SharedPreferences? _preferences;
  List<PersonalList> _local = [];
  List<PersonalList> _remote = [];
  String? _token;
  bool _ready = false;
  bool _disposed = false;
  int _requestVersion = 0;
  bool loading = false;
  bool saving = false;
  String? error;
  Future<void>? _initialization;
  List<PersonalList> get items => List.unmodifiable([..._remote, ..._local]);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final raw = _preferences!.getString('personal_lists_local');
      if (raw != null) {
        _local = (jsonDecode(raw) as List)
            .map(
              (v) => PersonalList.fromJson(
                Map<String, dynamic>.from(v as Map),
                local: true,
              ),
            )
            .toList();
      }
      _ready = true;
    } catch (_) {
      error =
          'Não foi possível ler as listas deste celular. Tente novamente antes de salvar.';
    }
    _sessionChanged();
    _notify();
  }

  void _sessionChanged() {
    final token = library.api.token;
    if (_token == token) return;
    _token = token;
    _requestVersion++;
    _remote = [];
    loading = false;
    error = null;
    _notify();
    if (token != null) unawaited(refresh());
  }

  Future<void> refresh() async {
    final token = library.api.token;
    if (token == null) return;
    final requestVersion = ++_requestVersion;
    loading = true;
    error = null;
    _notify();
    try {
      final result = await library.api.request('playlists');
      if (_disposed ||
          token != library.api.token ||
          requestVersion != _requestVersion) {
        return;
      }
      _remote = _decode(result);
    } catch (e) {
      if (token == library.api.token && requestVersion == _requestVersion) {
        error = _message(e);
      }
    } finally {
      if (token == library.api.token && requestVersion == _requestVersion) {
        loading = false;
        _notify();
      }
    }
  }

  List<PersonalList> _decode(Map<String, dynamic> result) =>
      (result['playlists'] as List)
          .map(
            (v) => PersonalList.fromJson(
              Map<String, dynamic>.from(v as Map),
              local: false,
            ),
          )
          .toList();
  String _message(Object e) => e is ApiException
      ? (e.status == 404
            ? 'As listas na conta precisam da atualização do servidor.'
            : e.message)
      : 'Não foi possível salvar ou carregar as listas. Tente novamente.';

  Future<String?> save({
    PersonalList? original,
    required String title,
    required List<String> songIds,
    required bool local,
    required String? session,
  }) async {
    if (saving) return 'Aguarde a gravação em andamento.';
    if (title.trim().isEmpty || title.trim().runes.length > 120) {
      return 'Informe um nome de até 120 caracteres.';
    }
    if (songIds.length > 100 || songIds.toSet().length != songIds.length) {
      return 'Escolha até 100 músicas, sem repetir.';
    }
    if (original != null && original.local != local) {
      return 'O destino da lista não pode mudar durante a edição.';
    }
    return _mutate(
      original: original,
      title: title.trim(),
      ids: songIds,
      local: local,
      session: session,
      delete: false,
    );
  }

  Future<String?> delete(PersonalList list, String? session) => _mutate(
    original: list,
    title: list.title,
    ids: list.songIds,
    local: list.local,
    session: session,
    delete: true,
  );
  Future<String?> _mutate({
    PersonalList? original,
    required String title,
    required List<String> ids,
    required bool local,
    required String? session,
    required bool delete,
  }) async {
    if (saving) return 'Aguarde a gravação em andamento.';
    if (!local && (session == null || session != library.api.token)) {
      return 'A conta mudou. Volte e abra a lista novamente.';
    }
    _requestVersion++;
    loading = false;
    saving = true;
    _notify();
    try {
      if (local) {
        await initialize();
        if (!_ready || _preferences == null) {
          return 'Não foi possível acessar o armazenamento deste celular.';
        }
        final next = List<PersonalList>.of(_local);
        final index = original == null
            ? -1
            : next.indexWhere((p) => p.id == original.id);
        if (original != null &&
            (index < 0 || next[index].version != original.version)) {
          return 'A lista mudou. Volte e abra novamente.';
        }
        if (delete) {
          next.removeAt(index);
        } else {
          if (original == null && next.length >= 100) {
            return 'Limite de 100 listas neste celular.';
          }
          final item = PersonalList(
            id:
                original?.id ??
                'local-${DateTime.now().microsecondsSinceEpoch}',
            title: title,
            songIds: ids,
            local: true,
            version: (original?.version ?? 0) + 1,
          );
          if (index < 0) {
            next.insert(0, item);
          } else {
            next[index] = item;
          }
        }
        final saved = await _preferences!.setString(
          'personal_lists_local',
          jsonEncode(next.map((p) => p.toJson()).toList()),
        );
        if (!saved) return 'Não foi possível gravar a lista no celular.';
        _local = next;
      } else {
        final result = await library.api.request(
          'playlists',
          method: 'POST',
          data: {
            'action': delete ? 'delete' : 'save',
            if (original != null) 'id': original.id,
            if (original != null) 'version': original.version,
            'title': title,
            'songIds': ids,
          },
        );
        if (_disposed || session != library.api.token) {
          return 'A conta mudou. Volte para consultar suas listas.';
        }
        _remote = _decode(result);
      }
      error = null;
      return null;
    } catch (e) {
      return _message(e);
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    library.removeListener(_sessionChanged);
    super.dispose();
  }
}
