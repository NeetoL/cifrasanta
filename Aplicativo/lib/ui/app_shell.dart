import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/catalog.dart';
import '../core/library_store.dart';
import '../core/personal_lists.dart';
import 'screens/personal_lists_screen.dart';
import '../core/prayers.dart';
import 'components.dart';
import 'identity.dart';
import 'navigation/app_destination.dart';
import 'navigation/app_drawer.dart';
import 'screens/about_screen.dart';
import 'screens/account_screen.dart';
import 'screens/bible_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/churches_screen.dart';
import 'screens/cifras_home_screen.dart';
import 'screens/favorites_hub_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/library_screens.dart';
import 'screens/liturgia_screen.dart';
import 'screens/prayers_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/rosary_screen.dart';
import 'screens/saint_screen.dart';
import 'screens/settings_screen.dart';

/// Casca do aplicativo: barra superior, menu lateral e a área atual.
/// A navegação entre áreas principais troca o destino, sem empilhar telas.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.library, required this.services});

  final LibraryStore library;
  final AppServices services;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppDestination current = AppDestination.inicio;
  int cifrasTab = 0;
  String searchCategory = '';

  LibraryStore get library => widget.library;
  late final AppServices services = widget.services;
  late final PersonalLists personalLists = PersonalLists(library);

  @override
  void initState() {
    super.initState();
    library.addListener(showMessage);
    library.restoreSession();
    personalLists.initialize();
    library.load();
    services.favorites.initialize();
    services.liturgia.ensureToday();
  }

  void showMessage() {
    final message = library.message;
    if (message == null || !mounted) return;
    library.message = null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    personalLists.dispose();
    library.removeListener(showMessage);
    super.dispose();
  }

  void goTo(AppDestination destination) {
    if (destination == AppDestination.cifras && current != destination) {
      cifrasTab = 0;
    }
    if (destination == AppDestination.liturgia && !services.liturgia.isToday) {
      // Vindo do menu ou da Home, a Liturgia abre no dia de hoje.
      services.liturgia.goToToday();
    }
    setState(() => current = destination);
  }

  void goSearch([String category = '']) => setState(() {
    searchCategory = category;
    current = AppDestination.cifras;
    cifrasTab = 1;
  });

  void openLiturgiaOn(DateTime date) {
    services.liturgia.loadDate(date);
    setState(() => current = AppDestination.liturgia);
  }

  void openSong(Song song) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReaderScreen(song: song, library: library),
    ),
  );

  void openRepertoire(Repertoire repertoire) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RepertoireDetailScreen(
        repertoire: repertoire,
        library: library,
        onSong: openSong,
      ),
    ),
  );

  void openPrayerDetail(Prayer prayer) =>
      openPrayer(context, prayer, services.favorites);

  void handleBack() {
    if (current == AppDestination.cifras && cifrasTab != 0) {
      setState(() => cifrasTab = 0);
    } else {
      setState(() => current = AppDestination.inicio);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: current == AppDestination.inicio,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) handleBack();
    },
    child: AnimatedBuilder(
      animation: library,
      builder: (context, _) => Scaffold(
        drawer: AppDrawer(current: current, onSelect: goTo),
        appBar: AppBar(
          toolbarHeight: 66,
          titleSpacing: 0,
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: current == AppDestination.inicio
              ? const AppBrand()
              : Text(
                  current.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
          actions: [
            IconButton(
              tooltip: 'Minha conta',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AccountScreen(library: library),
                ),
              ),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: SaintColors.divider),
          ),
        ),
        body: SafeArea(top: false, child: _body()),
        bottomNavigationBar: current == AppDestination.cifras
            ? _cifrasNav()
            : null,
      ),
    ),
  );

  Widget _body() => switch (current) {
    AppDestination.inicio => InicioScreen(
      services: services,
      library: library,
      onNavigate: goTo,
      onSong: openSong,
      onPrayer: openPrayerDetail,
    ),
    AppDestination.cifras => _cifras(),
    AppDestination.liturgia => LiturgiaScreen(
      store: services.liturgia,
      embedded: true,
    ),
    AppDestination.biblia => BibleScreen(
      canon: services.bibleCanon,
      text: services.bibleText,
      favorites: services.favorites,
    ),
    AppDestination.oracoes => PrayersScreen(
      repository: services.prayers,
      favorites: services.favorites,
    ),
    AppDestination.santoDoDia => SaintScreen(repository: services.saints),
    AppDestination.terco => RosaryScreen(
      rosary: services.rosary,
      prayers: services.prayers,
    ),
    AppDestination.calendario => CalendarScreen(onSelectDate: openLiturgiaOn),
    AppDestination.favoritos => FavoritesHubScreen(
      library: library,
      favorites: services.favorites,
      prayers: services.prayers,
      onSong: openSong,
      onSearch: goSearch,
    ),
    AppDestination.igrejas => ChurchesScreen(repository: services.churches),
    AppDestination.sobre => const AboutScreen(),
    AppDestination.configuracoes => SettingsScreen(
      library: library,
      theme: services.theme,
    ),
  };

  Widget _cifras() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: library.loading && !library.hasLoaded && cifrasTab != 3
          ? const Center(child: CircularProgressIndicator())
          : library.catalogError != null && !library.hasLoaded && cifrasTab != 3
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyState(
                title: 'Não foi possível carregar as cifras',
                message: library.catalogError!,
                action: 'Tentar novamente',
                onAction: library.load,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await library.load();
                await personalLists.refresh();
              },
              child: switch (cifrasTab) {
                0 => CifrasHomeScreen(
                  library: library,
                  onSearch: goSearch,
                  onSong: openSong,
                  onRepertoire: openRepertoire,
                ),
                1 => SearchScreen(
                  key: ValueKey(searchCategory),
                  initialCategory: searchCategory,
                  library: library,
                  onSong: openSong,
                ),
                2 => FavoritesScreen(
                  library: library,
                  onSong: openSong,
                  onSearch: () => goSearch(),
                ),
                _ => PersonalListsScreen(
                  store: personalLists,
                  onSong: openSong,
                  onRepertoire: openRepertoire,
                ),
              },
            ),
    ),
  );

  Widget _cifrasNav() => SafeArea(
    top: false,
    child: Container(
      decoration: BoxDecoration(
        color: SaintColors.panel,
        border: Border(top: BorderSide(color: SaintColors.line)),
      ),
      child: Row(
        children: [
          _navItem(
            0,
            Icons.queue_music_outlined,
            Icons.queue_music_rounded,
            'Cifras',
          ),
          _navItem(1, Icons.search_rounded, Icons.search_rounded, 'Buscar'),
          _navItem(
            2,
            Icons.favorite_border_rounded,
            Icons.favorite_rounded,
            'Favoritos',
          ),
          _navItem(
            3,
            Icons.format_list_bulleted_rounded,
            Icons.format_list_bulleted_rounded,
            'Listas',
          ),
        ],
      ),
    ),
  );

  Widget _navItem(int index, IconData normal, IconData active, String label) =>
      Expanded(
        child: InkWell(
          onTap: () => setState(() {
            cifrasTab = index;
            if (index == 1) searchCategory = '';
          }),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cifrasTab == index ? active : normal,
                  size: 21,
                  color: cifrasTab == index
                      ? SaintColors.gold
                      : SaintColors.muted,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cifrasTab == index
                        ? SaintColors.text
                        : SaintColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
