import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/local_favorites.dart';
import '../../core/prayers.dart';
import '../components.dart';
import '../identity.dart';
import '../widgets/cards.dart';

void openPrayer(
  BuildContext context,
  Prayer prayer,
  LocalFavoritesStore favorites,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => PrayerDetailScreen(prayer: prayer, favorites: favorites),
  ),
);

class PrayersScreen extends StatelessWidget {
  const PrayersScreen({
    super.key,
    required this.repository,
    required this.favorites,
  });

  final PrayerRepository repository;
  final LocalFavoritesStore favorites;

  @override
  Widget build(BuildContext context) =>
      CachedFutureBuilder<List<PrayerCategory>>(
        load: () => repository.categories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ContentPage(
              children: [
                EmptyState(
                  title: 'Não foi possível abrir as orações',
                  message: 'Feche o aplicativo e tente novamente.',
                ),
              ],
            );
          }
          final categories = snapshot.data;
          if (categories == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: favorites,
            builder: (context, _) => ContentPage(
              children: [
                const PageHeading(
                  kicker: 'REZE CONOSCO',
                  title: 'Orações.',
                  subtitle: 'Orações da tradição católica para cada momento.',
                ),
                for (final category in categories) ...[
                  _CategorySection(category: category, favorites: favorites),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          );
        },
      );
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.favorites});

  final PrayerCategory category;
  final LocalFavoritesStore favorites;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(category.title.toUpperCase()),
      if (category.description.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(
          category.description,
          style: TextStyle(color: SaintColors.muted, fontSize: 12),
        ),
      ],
      const SizedBox(height: 9),
      for (final prayer in category.prayers)
        PrayerRow(
          prayer: prayer,
          favorite: favorites.isFavorite(FavoriteKind.prayer, prayer.id),
          onTap: () => openPrayer(context, prayer, favorites),
        ),
    ],
  );
}

class PrayerRow extends StatelessWidget {
  const PrayerRow({
    super.key,
    required this.prayer,
    required this.onTap,
    this.favorite = false,
  });

  final Prayer prayer;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SaintCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                if (prayer.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    prayer.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: SaintColors.muted, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          if (favorite)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.favorite_rounded,
                size: 16,
                color: SaintColors.gold,
              ),
            ),
          Icon(Icons.chevron_right_rounded, color: SaintColors.muted, size: 22),
        ],
      ),
    ),
  );
}

class PrayerDetailScreen extends StatelessWidget {
  const PrayerDetailScreen({
    super.key,
    required this.prayer,
    required this.favorites,
  });

  final Prayer prayer;
  final LocalFavoritesStore favorites;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: favorites,
    builder: (context, _) {
      final favorite = favorites.isFavorite(FavoriteKind.prayer, prayer.id);
      return Scaffold(
        appBar: AppBar(
          title: Text(
            prayer.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Copiar oração',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(
                  ClipboardData(text: '${prayer.title}\n\n${prayer.text}'),
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Oração copiada.')),
                );
              },
            ),
            IconButton(
              tooltip: favorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorite ? SaintColors.gold : null,
              ),
              onPressed: () => favorites.toggle(FavoriteKind.prayer, prayer.id),
            ),
          ],
        ),
        body: ContentPage(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
          children: [
            Text(
              prayer.title,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 30,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
            if (prayer.subtitle.isNotEmpty || prayer.reference.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                [
                  prayer.subtitle,
                  prayer.reference,
                ].where((part) => part.isNotEmpty).join('  ·  '),
                style: TextStyle(color: SaintColors.gold, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 22),
            SelectableText(
              prayer.text,
              style: const TextStyle(fontSize: 17, height: 1.75),
            ),
          ],
        ),
      );
    },
  );
}
