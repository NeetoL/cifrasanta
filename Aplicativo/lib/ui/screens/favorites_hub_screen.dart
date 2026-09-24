import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/library_store.dart';
import '../../core/local_favorites.dart';
import '../../core/prayers.dart';
import '../components.dart';
import '../identity.dart';
import '../widgets/cards.dart';
import 'library_screens.dart';
import 'prayers_screen.dart';

/// Central de favoritos. As cifras continuam vindo da conta; orações ficam no
/// aparelho; versículos e leituras aparecem quando forem favoritados.
class FavoritesHubScreen extends StatelessWidget {
  const FavoritesHubScreen({
    super.key,
    required this.library,
    required this.favorites,
    required this.prayers,
    required this.onSong,
    required this.onSearch,
  });

  final LibraryStore library;
  final LocalFavoritesStore favorites;
  final PrayerRepository prayers;
  final ValueChanged<Song> onSong;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: SaintColors.gold,
          labelColor: SaintColors.text,
          unselectedLabelColor: SaintColors.muted,
          tabs: [
            Tab(text: 'Cifras'),
            Tab(text: 'Orações'),
            Tab(text: 'Versículos e leituras'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              FavoritesScreen(
                library: library,
                onSong: onSong,
                onSearch: onSearch,
              ),
              _PrayerFavorites(favorites: favorites, prayers: prayers),
              _OtherFavorites(favorites: favorites),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PrayerFavorites extends StatelessWidget {
  const _PrayerFavorites({required this.favorites, required this.prayers});

  final LocalFavoritesStore favorites;
  final PrayerRepository prayers;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: favorites,
    builder: (context, _) {
      final ids = favorites.ids(FavoriteKind.prayer);
      return FutureBuilder<List<Prayer>>(
        future: _load(ids),
        builder: (context, snapshot) {
          final items = snapshot.data;
          if (items == null && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items == null || items.isEmpty) {
            return const ContentPage(
              children: [
                EmptyState(
                  title: 'Nenhuma oração favorita',
                  message:
                      'Toque no coração dentro de uma oração para guardá-la aqui.',
                ),
              ],
            );
          }
          return ContentPage(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 35),
            children: [
              for (final prayer in items)
                PrayerRow(
                  prayer: prayer,
                  favorite: true,
                  onTap: () => openPrayer(context, prayer, favorites),
                ),
            ],
          );
        },
      );
    },
  );

  Future<List<Prayer>> _load(Set<String> ids) async {
    final result = <Prayer>[];
    for (final id in ids) {
      final prayer = await prayers.byId(id);
      if (prayer != null) result.add(prayer);
    }
    return result;
  }
}

class _OtherFavorites extends StatelessWidget {
  const _OtherFavorites({required this.favorites});
  final LocalFavoritesStore favorites;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: favorites,
    builder: (context, _) {
      final verses = favorites.ids(FavoriteKind.verse);
      final readings = favorites.ids(FavoriteKind.reading);
      if (verses.isEmpty && readings.isEmpty) {
        return const ContentPage(
          children: [
            EmptyState(
              title: 'Nada por aqui ainda',
              message:
                  'Versículos e leituras favoritados aparecerão nesta área.',
            ),
          ],
        );
      }
      return ContentPage(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 35),
        children: [
          if (verses.isNotEmpty) ...[
            const Eyebrow('VERSÍCULOS'),
            const SizedBox(height: 9),
            for (final id in verses)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SaintCard(child: Text(id)),
              ),
          ],
          if (readings.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Eyebrow('LEITURAS'),
            const SizedBox(height: 9),
            for (final id in readings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SaintCard(child: Text(id)),
              ),
          ],
        ],
      );
    },
  );
}
