import 'package:flutter/material.dart';

import '../../core/liturgia_store.dart';
import '../../core/prayers.dart';
import '../../core/churches.dart';
import '../components.dart';
import '../identity.dart';
import '../navigation/app_destination.dart';
import '../widgets/cards.dart';

/// Card "Liturgia de Hoje", alimentado pela liturgia real do dia.
class LiturgiaTodayCard extends StatelessWidget {
  const LiturgiaTodayCard({
    super.key,
    required this.store,
    required this.onOpen,
  });

  final LiturgiaStore store;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final today = store.today;
      final Widget content;
      if (today == null && store.todayLoading) {
        content = const Padding(
          padding: EdgeInsets.symmetric(vertical: 26),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (today == null) {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Não foi possível carregar a liturgia de hoje.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: TextStyle(color: SaintColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => store.ensureToday(force: true),
              child: const Text('Tentar novamente'),
            ),
          ],
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              today.celebracao.isEmpty
                  ? today.tempoLiturgico
                  : today.celebracao,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                today.tempoLiturgico,
                if (today.corLiturgica.isNotEmpty)
                  'Cor ${today.corLiturgica.toLowerCase()}',
              ].where((part) => part.isNotEmpty).join('  ·  '),
              style: TextStyle(color: SaintColors.muted, fontSize: 12.5),
            ),
            if (today.evangelho.referencia.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Evangelho: ${today.evangelho.referencia}',
                style: const TextStyle(fontSize: 13.5),
              ),
            ],
          ],
        );
      }
      return SaintCard(
        borderColor: SaintColors.goldBorder,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('LITURGIA DE HOJE'),
            const SizedBox(height: 10),
            content,
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.auto_stories_rounded, size: 18),
              label: const Text('Ver Liturgia Completa'),
            ),
          ],
        ),
      );
    },
  );
}

/// Palavra do dia: trecho do Evangelho da liturgia real de hoje.
class WordOfTheDayCard extends StatelessWidget {
  const WordOfTheDayCard({
    super.key,
    required this.store,
    required this.onOpen,
  });

  final LiturgiaStore store;
  final VoidCallback onOpen;

  static String excerpt(String text, {int limit = 220}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= limit) return clean;
    final cut = clean.substring(0, limit);
    final space = cut.lastIndexOf(' ');
    return '${cut.substring(0, space > 0 ? space : limit)}…';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final gospel = store.today?.evangelho;
      if (gospel == null || gospel.texto.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(kicker: 'PALAVRA DO DIA', title: 'Evangelho'),
            SaintCard(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    excerpt(gospel.texto),
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (gospel.referencia.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      gospel.referencia,
                      style: TextStyle(
                        color: SaintColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Grade de acessos rápidos às áreas do aplicativo.
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key, required this.onSelect});

  static const destinations = [
    AppDestination.cifras,
    AppDestination.liturgia,
    AppDestination.biblia,
    AppDestination.oracoes,
    AppDestination.terco,
    AppDestination.calendario,
    AppDestination.santoDoDia,
    AppDestination.favoritos,
  ];

  final ValueChanged<AppDestination> onSelect;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: destinations.length,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 260,
      mainAxisExtent: 132,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
    ),
    itemBuilder: (context, index) {
      final destination = destinations[index];
      return SaintCard(
        padding: const EdgeInsets.all(13),
        onTap: () => onSelect(destination),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(destination.icon, size: 36),
            const Spacer(),
            Text(
              destination.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: SaintColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      );
    },
  );
}

/// Oração sugerida para o momento do dia.
class PrayerOfTheDayCard extends StatelessWidget {
  const PrayerOfTheDayCard({
    super.key,
    required this.repository,
    required this.onOpen,
  });

  final PrayerRepository repository;
  final ValueChanged<Prayer> onOpen;

  @override
  Widget build(BuildContext context) => CachedFutureBuilder<Prayer?>(
    load: () => repository.prayerOfTheMoment(DateTime.now()),
    builder: (context, snapshot) {
      final prayer = snapshot.data;
      if (prayer == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(kicker: 'ORAÇÃO', title: 'Oração do dia'),
            SaintCard(
              onTap: () => onOpen(prayer),
              child: Row(
                children: [
                  const IconBadge(Icons.volunteer_activism_outlined),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      prayer.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: SaintColors.muted),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Igrejas apoiadoras: só aparece quando existem igrejas cadastradas.
class SupportingChurchesSection extends StatelessWidget {
  const SupportingChurchesSection({
    super.key,
    required this.repository,
    required this.onOpenAll,
  });

  final ChurchRepository repository;
  final VoidCallback onOpenAll;

  @override
  Widget build(
    BuildContext context,
  ) => CachedFutureBuilder<List<SupportingChurch>>(
    load: () => repository.churches(),
    builder: (context, snapshot) {
      final churches = snapshot.data;
      if (churches == null || churches.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              kicker: 'COMUNIDADE',
              title: 'Igrejas apoiadoras',
              action: 'Ver todas',
              onAction: onOpenAll,
            ),
            for (final church in churches.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SaintCard(
                  onTap: onOpenAll,
                  child: Row(
                    children: [
                      const IconBadge(Icons.church_outlined, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          church.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
