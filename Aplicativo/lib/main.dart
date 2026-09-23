import 'package:flutter/material.dart';

import 'core/catalog.dart';
import 'core/library_store.dart';
import 'ui/components.dart';
import 'ui/identity.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/library_screens.dart';
import 'ui/screens/reader_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final library = LibraryStore();
  await library.load();
  runApp(CifraSantaApp(library: library));
}

class CifraSantaApp extends StatelessWidget {
  const CifraSantaApp({super.key, required this.library});
  final LibraryStore library;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cifra Santa',
    theme: cifraTheme(),
    debugShowCheckedModeBanner: false,
    home: AppShell(library: library),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.library});
  final LibraryStore library;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  String searchCategory = '';

  void goSearch([String category = '']) => setState(() {
    searchCategory = category;
    selected = 1;
  });

  void openSong(Song song) => Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ReaderScreen(song: song, library: widget.library),
  ));

  void openRepertoire(Repertoire repertoire) => Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => RepertoireDetailScreen(
      repertoire: repertoire,
      library: widget.library,
      onSong: openSong,
    ),
  ));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.library,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        titleSpacing: 24,
        title: const AppBrand(),
        actions: MediaQuery.sizeOf(context).width >= 600
          ? const [Padding(
              padding: EdgeInsets.only(right: 24),
              child: Center(child: Eyebrow('MÚSICA PARA SERVIR')),
            )]
          : null,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: Color(0xFF293439))),
      ),
      body: SafeArea(
        top: false,
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: switch (selected) {
            0 => HomeScreen(library: widget.library, onSearch: goSearch, onSong: openSong, onRepertoire: openRepertoire),
            1 => SearchScreen(key: ValueKey(searchCategory), initialCategory: searchCategory, library: widget.library, onSong: openSong),
            2 => FavoritesScreen(library: widget.library, onSong: openSong, onSearch: () => goSearch()),
            _ => RepertoiresScreen(onOpen: openRepertoire),
          },
        )),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(color: Color(0xFF191F22), border: Border(top: BorderSide(color: SaintColors.line))),
          child: Row(children: [
            _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Início'),
            _navItem(1, Icons.search_rounded, Icons.search_rounded, 'Buscar'),
            _navItem(2, Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favoritos'),
            _navItem(3, Icons.format_list_bulleted_rounded, Icons.format_list_bulleted_rounded, 'Repertórios'),
          ]),
        ),
      ),
    ),
  );

  Widget _navItem(int index, IconData normal, IconData active, String label) => Expanded(
    child: InkWell(
      onTap: () => setState(() {
        selected = index;
        if (index == 1) searchCategory = '';
      }),
      child: SizedBox(height: 64, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(selected == index ? active : normal, size: 21, color: selected == index ? SaintColors.gold : SaintColors.muted),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected == index ? SaintColors.text : SaintColors.muted)),
      ])),
    ),
  );
}
