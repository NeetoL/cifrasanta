import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/moments.dart';
import '../../core/library_store.dart';
import '../components.dart';
import '../identity.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.initialCategory,
    required this.library,
    required this.onSong,
  });
  final String initialCategory;
  final LibraryStore library;
  final ValueChanged<Song> onSong;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController query = TextEditingController();
  late String category = widget.initialCategory;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  List<Song> _results = const [];
  String _resultsKey = '\u0000';
  List<Song>? _resultsCatalog;

  /// Filtra somente quando a consulta, a categoria ou o catálogo mudam.
  List<Song> _filter(String term, bool showHistory) {
    if (showHistory) return widget.library.recentSearches;
    final key = '$term\u0001$category';
    if (key != _resultsKey || !identical(_resultsCatalog, Catalog.songs)) {
      _resultsKey = key;
      _resultsCatalog = Catalog.songs;
      _results = [
        for (final song in Catalog.songs)
          if ((category.isEmpty || Moments.matches(song.category, category)) &&
              (term.isEmpty || song.searchKey.contains(term)))
            song,
      ];
    }
    return _results;
  }

  @override
  Widget build(BuildContext context) {
    final term = Moments.normalize(query.text.trim());
    final showHistory = term.isEmpty && category.isEmpty;
    final filtered = _filter(term, showHistory);
    // Lista preguiçosa: só as linhas visíveis são construídas.
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 35),
      itemCount: 2 + filtered.length,
      itemBuilder: (context, index) {
        if (index == 0) return _header(showHistory, filtered.length);
        if (index == 1) {
          return filtered.isEmpty
              ? EmptyState(
                  title: showHistory
                      ? 'Nenhuma busca recente'
                      : 'Nenhuma música por aqui',
                  message: showHistory
                      ? 'Busque uma música e abra a cifra. Suas últimas 10 músicas aparecerão aqui.'
                      : 'Experimente outro nome ou momento.',
                )
              : const SizedBox.shrink();
        }
        final i = index - 2;
        final song = filtered[i];
        return SongRow(
          song: song,
          index: i,
          favorite: widget.library.isFavorite(song.id),
          onTap: () {
            widget.library.rememberSearch(song);
            widget.onSong(song);
          },
          onFavorite: () => widget.library.toggleFavorite(song.id),
        );
      },
    );
  }

  Widget _header(bool showHistory, int count) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        kicker: 'ENCONTRE SUA PRÓXIMA CANÇÃO',
        title: 'Explorar cifras.',
        subtitle: 'Escolha pelo nome ou pelo momento da celebração.',
      ),
      TextField(
        controller: query,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Música, artista ou momento',
          hintStyle: TextStyle(color: SaintColors.muted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: SaintColors.blue),
          filled: true,
          fillColor: SaintColors.surface,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: SaintColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: SaintColors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      const SizedBox(height: 17),
      SizedBox(
        height: 43,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
            for (final value in [
              '',
              ...Moments.all,
              ...Catalog.extraCategories,
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(value.isEmpty ? 'Todas' : value),
                  selected: category == value,
                  onSelected: (_) => setState(() => category = value),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  selectedColor: SaintColors.gold,
                  backgroundColor: SaintColors.surface,
                  labelStyle: TextStyle(
                    color: category == value
                        ? SaintColors.background
                        : SaintColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  side: BorderSide(
                    color: category == value
                        ? SaintColors.gold
                        : SaintColors.line,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 19),
      Text(
        showHistory
            ? 'Últimas músicas buscadas'
            : '$count ${count == 1 ? 'música encontrada' : 'músicas encontradas'}',
        style: TextStyle(
          color: SaintColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 9),
    ],
  );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.library,
    required this.onSong,
    required this.onSearch,
  });
  final LibraryStore library;
  final ValueChanged<Song> onSong;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final selected = Catalog.songs
        .where((song) => library.isFavorite(song.id))
        .toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 35),
      children: [
        const PageHeading(
          kicker: 'SEU ACERVO',
          title: 'Favoritos.',
          subtitle: 'As músicas que você quer ter sempre por perto.',
        ),
        if (selected.isEmpty)
          EmptyState(
            title: 'Seu espaço está esperando',
            message: 'Toque no coração de uma música para encontrá-la aqui.',
            action: 'Explorar cifras',
            onAction: onSearch,
          )
        else
          for (var i = 0; i < selected.length; i++)
            SongRow(
              song: selected[i],
              index: i,
              favorite: true,
              onTap: () => onSong(selected[i]),
              onFavorite: () => library.toggleFavorite(selected[i].id),
            ),
        const SizedBox(height: 22),
        Text(
          library.signedIn
              ? 'Favoritos salvos na sua conta.'
              : 'Entre em Minha conta para salvar seus favoritos.',
          style: TextStyle(color: SaintColors.subtle, fontSize: 11),
        ),
      ],
    );
  }
}

class RepertoiresScreen extends StatelessWidget {
  const RepertoiresScreen({super.key, required this.onOpen});
  final ValueChanged<Repertoire> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 35),
    children: [
      const PageHeading(
        kicker: 'TUDO NO MESMO LUGAR',
        title: 'Repertórios.',
        subtitle: 'Uma sequência pronta para cada encontro.',
      ),
      if (Catalog.repertoires.isEmpty)
        const EmptyState(
          title: 'Nenhum repertório publicado',
          message: 'Novos repertórios aparecerão aqui.',
        ),
      for (var i = 0; i < Catalog.repertoires.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Material(
            color: SaintColors.surface,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onOpen(Catalog.repertoires[i]),
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: SaintColors.line),
                ),
                child: Row(
                  children: [
                    SacredGlyph(
                      [
                        SacredSymbol.church,
                        SacredSymbol.dove,
                        SacredSymbol.chalice,
                      ][i % 3],
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(
                            Catalog.repertoires[i].subtitle.toUpperCase(),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            Catalog.repertoires[i].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Catalog.repertoires[i].songIds.length} músicas',
                            style: TextStyle(
                              color: SaintColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: SaintColors.gold,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      const SizedBox(height: 15),
      Text(
        'Repertórios publicados pelo administrador. As atualizações aparecem ao atualizar o catálogo.',
        style: TextStyle(color: SaintColors.subtle, fontSize: 11, height: 1.5),
      ),
    ],
  );
}

class RepertoireDetailScreen extends StatelessWidget {
  const RepertoireDetailScreen({
    super.key,
    required this.repertoire,
    required this.library,
    required this.onSong,
  });
  final Repertoire repertoire;
  final LibraryStore library;
  final ValueChanged<Song> onSong;

  @override
  Widget build(BuildContext context) {
    final songs = repertoire.songIds
        .map(Catalog.song)
        .whereType<Song>()
        .toList();
    return AnimatedBuilder(
      animation: library,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const AppBrand()),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 29, 24, 35),
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SaintColors.accentSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SacredGlyph(SacredSymbol.book, size: 36),
                ),
                const SizedBox(height: 20),
                Eyebrow(repertoire.subtitle.toUpperCase()),
                const SizedBox(height: 10),
                Text(
                  repertoire.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${songs.length} músicas na sequência',
                  style: TextStyle(color: SaintColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 31),
                const Eyebrow('SEQUÊNCIA MUSICAL'),
                const SizedBox(height: 10),
                for (var i = 0; i < songs.length; i++)
                  SongRow(
                    song: songs[i],
                    index: i,
                    favorite: library.isFavorite(songs[i].id),
                    onTap: () => onSong(songs[i]),
                    onFavorite: () => library.toggleFavorite(songs[i].id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
