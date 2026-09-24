import 'moments.dart';

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.category,
    required this.originalKey,
    required this.chart,
  });
  final String id;
  final String title;
  final String artist;
  final String category;
  final String originalKey;
  final String chart;

  static final Expando<String> _searchKeys = Expando<String>();

  /// Título, artista e categoria já normalizados, calculados uma única vez.
  String get searchKey =>
      _searchKeys[this] ??= Moments.normalize('$title\n$artist\n$category');
  factory Song.fromJson(Map<String, dynamic> data) => Song(
    id: data['id'].toString(),
    title: data['title'] as String,
    artist: data['artist'] as String,
    category: data['category'] as String,
    originalKey: data['originalKey'] as String,
    chart: data['chart'] as String,
  );
}

class Repertoire {
  const Repertoire({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.songIds,
  });
  final String id;
  final String title;
  final String subtitle;
  final List<String> songIds;
  factory Repertoire.fromJson(Map<String, dynamic> data) => Repertoire(
    id: data['id'].toString(),
    title: data['title'] as String,
    subtitle: data['subtitle'] as String,
    songIds: List<String>.unmodifiable(
      (data['songIds'] as List).map((id) => id.toString()),
    ),
  );
}

abstract final class Catalog {
  static List<Song> songs = const [];
  static List<Repertoire> repertoires = const [];

  static List<String>? _extraCategories;

  /// Categorias que não são momentos da celebração, calculadas uma vez por catálogo.
  static List<String> get extraCategories => _extraCategories ??= {
    for (final song in songs)
      if (!Moments.all.any((moment) => Moments.matches(song.category, moment)))
        song.category,
  }.toList();

  static void replace(Map<String, dynamic> data) {
    _extraCategories = null;
    final nextSongs = (data['songs'] as List)
        .map((item) => Song.fromJson(item as Map<String, dynamic>))
        .toList();
    final nextRepertoires = (data['repertoires'] as List)
        .map((item) => Repertoire.fromJson(item as Map<String, dynamic>))
        .toList();
    songs = List.unmodifiable(nextSongs);
    repertoires = List.unmodifiable(nextRepertoires);
  }

  static Song? song(String id) {
    for (final item in songs) {
      if (item.id == id) return item;
    }
    return null;
  }
}
