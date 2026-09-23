import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/library_store.dart';
import '../components.dart';
import '../identity.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.library, required this.onSearch, required this.onSong, required this.onRepertoire});
  final LibraryStore library;
  final ValueChanged<String> onSearch;
  final ValueChanged<Song> onSong;
  final ValueChanged<Repertoire> onRepertoire;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 29, 24, 35),
    children: [
      const Row(children: [SacredGlyph(SacredSymbol.mark, size: 16), SizedBox(width: 7), Eyebrow('MÚSICA CATÓLICA')]),
      const SizedBox(height: 15),
      const Text.rich(TextSpan(children: [
        TextSpan(text: 'O que vamos\n'),
        TextSpan(text: 'tocar hoje?', style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFFF2D796))),
      ]), style: TextStyle(fontFamily: 'serif', fontSize: 42, height: 1.05, letterSpacing: -2)),
      const SizedBox(height: 26),
      Material(
        color: const Color(0xFFF3F4F2),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSearch(''),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            child: Row(children: [
              Icon(Icons.search_rounded, color: Color(0xFF33444A), size: 21),
              SizedBox(width: 11),
              Expanded(child: Text('Busque uma música ou artista', style: TextStyle(color: Color(0xFF24343B), fontWeight: FontWeight.w700, fontSize: 13))),
              Icon(Icons.arrow_forward_rounded, color: Color(0xFF657880), size: 19),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 34),
      const SectionHeading(kicker: 'ACESSO RÁPIDO', title: 'Continue tocando'),
      _featured(context),
      const SizedBox(height: 33),
      SectionHeading(kicker: 'BIBLIOTECA', title: 'Músicas para você', action: 'Ver tudo', onAction: () => onSearch('')),
      for (var i = 0; i < 5; i++) SongRow(
        song: Catalog.songs[i],
        index: i,
        favorite: library.isFavorite(Catalog.songs[i].id),
        onTap: () => onSong(Catalog.songs[i]),
        onFavorite: () => library.toggleFavorite(Catalog.songs[i].id),
      ),
      const SizedBox(height: 31),
      const SectionHeading(kicker: 'EXPLORE', title: 'Por momento'),
      SizedBox(height: 98, child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _moment('Entrada', SacredSymbol.church),
          _moment('Comunhão', SacredSymbol.chalice),
          _moment('Louvor', SacredSymbol.dove),
          _moment('Envio', SacredSymbol.path),
        ],
      )),
      const SizedBox(height: 24),
      Material(
        color: SaintColors.surface,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => onRepertoire(Catalog.repertoires.first),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(border: Border.all(color: SaintColors.line), borderRadius: BorderRadius.circular(9)),
            child: const Row(children: [
              SacredGlyph(SacredSymbol.book, size: 33),
              SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Eyebrow('REPERTÓRIO'),
                SizedBox(height: 4),
                Text('Missa de domingo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                SizedBox(height: 2),
                Text('4 músicas na sequência', style: TextStyle(color: SaintColors.muted, fontSize: 11)),
              ])),
              Icon(Icons.arrow_forward_rounded, color: SaintColors.gold, size: 19),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Text('Catálogo de demonstração. Letras e cifras das músicas conhecidas não estão incluídas.', style: TextStyle(color: Color(0xFF71848C), fontSize: 11, height: 1.5)),
    ],
  );

  Widget _featured(BuildContext context) {
    final song = Catalog.songs.first;
    return Material(
      color: SaintColors.surface,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => onSong(song),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFF5A5547))),
          padding: const EdgeInsets.all(11),
          child: const Row(children: [
            _FeatureIcon(),
            SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow('COMUNHÃO · TOM D'),
              SizedBox(height: 5),
              Text('Sacramento da Comunhão', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              SizedBox(height: 3),
              Text('Nelsinho Corrêa', style: TextStyle(color: SaintColors.muted, fontSize: 11)),
            ])),
            Icon(Icons.arrow_forward_rounded, color: SaintColors.blue, size: 19),
          ]),
        ),
      ),
    );
  }

  Widget _moment(String name, SacredSymbol symbol) => Padding(
    padding: const EdgeInsets.only(right: 9),
    child: Material(
      color: SaintColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onSearch(name),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 139,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: SaintColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SacredGlyph(symbol, size: 29),
            const Spacer(),
            Row(children: [Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))), const Icon(Icons.arrow_forward_rounded, color: SaintColors.gold, size: 16)]),
          ]),
        ),
      ),
    ),
  );
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(color: const Color(0xFF263C43), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF45575A))),
    child: const Center(child: SacredGlyph(SacredSymbol.chalice, size: 35)),
  );
}
