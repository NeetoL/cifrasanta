import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/catalog.dart';
import '../../core/library_store.dart';
import '../../core/prayers.dart';
import '../components.dart';
import '../identity.dart';
import '../navigation/app_destination.dart';
import '../widgets/cards.dart';
import 'inicio_sections.dart';

/// Página inicial: reúne liturgia, acessos rápidos e atalhos das demais áreas.
class InicioScreen extends StatelessWidget {
  const InicioScreen({
    super.key,
    required this.services,
    required this.library,
    required this.onNavigate,
    required this.onSong,
    required this.onPrayer,
  });

  final AppServices services;
  final LibraryStore library;
  final ValueChanged<AppDestination> onNavigate;
  final ValueChanged<Song> onSong;
  final ValueChanged<Prayer> onPrayer;

  @override
  Widget build(BuildContext context) {
    final recent = library.recentSearches;
    final featured = Catalog.songs.take(3).toList();
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          services.liturgia.ensureToday(force: true),
          library.load(),
        ]);
      },
      child: ContentPage(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 35),
        children: [
          const Row(
            children: [
              SacredGlyph(SacredSymbol.mark, size: 16),
              SizedBox(width: 7),
              Flexible(child: Eyebrow('MÚSICA  •  PALAVRA  •  FÉ')),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Servindo à Igreja através da música, da Palavra e da oração.',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 29,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          LiturgiaTodayCard(
            store: services.liturgia,
            onOpen: () => onNavigate(AppDestination.liturgia),
          ),
          const SizedBox(height: 30),
          const SectionHeading(kicker: 'EXPLORE', title: 'Acessos rápidos'),
          QuickAccessGrid(onSelect: onNavigate),
          WordOfTheDayCard(
            store: services.liturgia,
            onOpen: () => onNavigate(AppDestination.liturgia),
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 30),
            const SectionHeading(
              kicker: 'CIFRAS',
              title: 'Continue de onde parou',
            ),
            SongRow(
              song: recent.first,
              index: 0,
              favorite: library.isFavorite(recent.first.id),
              onTap: () => onSong(recent.first),
              onFavorite: () => library.toggleFavorite(recent.first.id),
            ),
          ],
          if (featured.isNotEmpty) ...[
            const SizedBox(height: 30),
            SectionHeading(
              kicker: 'CIFRAS',
              title: 'Cifras em destaque',
              action: 'Ver todas',
              onAction: () => onNavigate(AppDestination.cifras),
            ),
            for (var i = 0; i < featured.length; i++)
              SongRow(
                song: featured[i],
                index: i,
                favorite: library.isFavorite(featured[i].id),
                onTap: () => onSong(featured[i]),
                onFavorite: () => library.toggleFavorite(featured[i].id),
              ),
          ],
          PrayerOfTheDayCard(repository: services.prayers, onOpen: onPrayer),
          SupportingChurchesSection(
            repository: services.churches,
            onOpenAll: () => onNavigate(AppDestination.igrejas),
          ),
        ],
      ),
    );
  }
}
