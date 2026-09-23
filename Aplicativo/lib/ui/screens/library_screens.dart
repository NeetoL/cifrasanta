import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/library_store.dart';
import '../components.dart';
import '../identity.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.initialCategory, required this.library, required this.onSong});
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
  void dispose() { query.dispose(); super.dispose(); }

  String normalize(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = value.toLowerCase();
    return lower.split('').map((c) {
      final index = from.indexOf(c);
      return index < 0 ? c : to[index];
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final term = normalize(query.text.trim());
    final filtered = Catalog.songs.where((song) {
      final matchesCategory = category.isEmpty || song.category == category;
      final matchesText = term.isEmpty || [song.title, song.artist, song.category].any((value) => normalize(value).contains(term));
      return matchesCategory && matchesText;
    }).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 35), children: [
      const PageHeading(kicker: 'ENCONTRE SUA PRÓXIMA CANÇÃO', title: 'Explorar cifras.', subtitle: 'Escolha pelo nome ou pelo momento da celebração.'),
      TextField(
        controller: query,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Música, artista ou momento',
          hintStyle: const TextStyle(color: SaintColors.muted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: SaintColors.blue),
          filled: true,
          fillColor: SaintColors.surface,
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: SaintColors.line), borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: SaintColors.blue), borderRadius: BorderRadius.circular(8)),
        ),
      ),
      const SizedBox(height: 17),
      SizedBox(height: 43, child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final value in ['', 'Entrada', 'Comunhão', 'Louvor', 'Envio'])
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: Text(value.isEmpty ? 'Todas' : value),
            selected: category == value,
            onSelected: (_) => setState(() => category = value),
            showCheckmark: false,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            selectedColor: SaintColors.gold,
            backgroundColor: SaintColors.surface,
            labelStyle: TextStyle(color: category == value ? SaintColors.background : SaintColors.muted, fontWeight: FontWeight.w700, fontSize: 11),
            side: BorderSide(color: category == value ? SaintColors.gold : SaintColors.line),
          )),
      ])),
      const SizedBox(height: 19),
      Text('${filtered.length} ${filtered.length == 1 ? 'música encontrada' : 'músicas encontradas'}', style: const TextStyle(color: SaintColors.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(height: 9),
      if (filtered.isEmpty)
        const EmptyState(title: 'Nenhuma música por aqui', message: 'Experimente outro nome ou momento.')
      else
        for (var i = 0; i < filtered.length; i++) SongRow(
          song: filtered[i],
          index: i,
          favorite: widget.library.isFavorite(filtered[i].id),
          onTap: () => widget.onSong(filtered[i]),
          onFavorite: () => widget.library.toggleFavorite(filtered[i].id),
        ),
    ]);
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.library, required this.onSong, required this.onSearch});
  final LibraryStore library;
  final ValueChanged<Song> onSong;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final selected = Catalog.songs.where((song) => library.isFavorite(song.id)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 35), children: [
      const PageHeading(kicker: 'SEU ACERVO', title: 'Favoritos.', subtitle: 'As músicas que você quer ter sempre por perto.'),
      if (selected.isEmpty)
        EmptyState(title: 'Seu espaço está esperando', message: 'Toque no coração de uma música para encontrá-la aqui.', action: 'Explorar cifras', onAction: onSearch)
      else
        for (var i = 0; i < selected.length; i++) SongRow(
          song: selected[i],
          index: i,
          favorite: true,
          onTap: () => onSong(selected[i]),
          onFavorite: () => library.toggleFavorite(selected[i].id),
        ),
      const SizedBox(height: 22),
      const Text('Favoritos ficam salvos neste aparelho.', style: TextStyle(color: Color(0xFF71848C), fontSize: 11)),
    ]);
  }
}

class RepertoiresScreen extends StatelessWidget {
  const RepertoiresScreen({super.key, required this.onOpen});
  final ValueChanged<Repertoire> onOpen;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 35), children: [
    const PageHeading(kicker: 'TUDO NO MESMO LUGAR', title: 'Repertórios.', subtitle: 'Uma sequência pronta para cada encontro.'),
    for (var i = 0; i < Catalog.repertoires.length; i++) Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(color: SaintColors.surface, borderRadius: BorderRadius.circular(9), child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => onOpen(Catalog.repertoires[i]),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: SaintColors.line)),
          child: Row(children: [
            SacredGlyph([SacredSymbol.church, SacredSymbol.dove, SacredSymbol.chalice][i], size: 36),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow(Catalog.repertoires[i].subtitle.toUpperCase()),
              const SizedBox(height: 7),
              Text(Catalog.repertoires[i].title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${Catalog.repertoires[i].songIds.length} músicas', style: const TextStyle(color: SaintColors.muted, fontSize: 11)),
            ])),
            const Icon(Icons.arrow_forward_rounded, color: SaintColors.gold, size: 19),
          ]),
        ),
      )),
    ),
    const SizedBox(height: 15),
    const Text('Repertórios de exemplo. Edição colaborativa virá em uma próxima etapa.', style: TextStyle(color: Color(0xFF71848C), fontSize: 11, height: 1.5)),
  ]);
}

class RepertoireDetailScreen extends StatelessWidget {
  const RepertoireDetailScreen({super.key, required this.repertoire, required this.library, required this.onSong});
  final Repertoire repertoire;
  final LibraryStore library;
  final ValueChanged<Song> onSong;

  @override
  Widget build(BuildContext context) {
    final songs = repertoire.songIds.map(Catalog.song).whereType<Song>().toList();
    return AnimatedBuilder(animation: library, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const AppBrand()),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 29, 24, 35),
        children: [
          Container(width: 60, height: 60, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF263C43), borderRadius: BorderRadius.circular(10)), child: const SacredGlyph(SacredSymbol.book, size: 36)),
          const SizedBox(height: 20),
          Eyebrow(repertoire.subtitle.toUpperCase()),
          const SizedBox(height: 10),
          Text(repertoire.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1.2)),
          const SizedBox(height: 5),
          Text('${songs.length} músicas na sequência', style: const TextStyle(color: SaintColors.muted, fontSize: 13)),
          const SizedBox(height: 31),
          const Eyebrow('SEQUÊNCIA MUSICAL'),
          const SizedBox(height: 10),
          for (var i = 0; i < songs.length; i++) SongRow(song: songs[i], index: i, favorite: library.isFavorite(songs[i].id), onTap: () => onSong(songs[i]), onFavorite: () => library.toggleFavorite(songs[i].id)),
        ],
      ))),
    ));
  }
}
