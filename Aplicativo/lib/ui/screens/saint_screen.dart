import 'package:flutter/material.dart';

import '../../core/pt_dates.dart';
import '../../core/saints.dart';
import '../components.dart';
import '../identity.dart';
import '../widgets/cards.dart';

class SaintScreen extends StatelessWidget {
  const SaintScreen({super.key, required this.repository});

  final SaintRepository repository;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final unavailable = repository.unavailableReason;
    return ContentPage(
      children: [
        PageHeading(
          kicker: 'VIDA DE ORAÇÃO',
          title: 'Santo do Dia.',
          subtitle: PtDates.dayAndMonth(today),
        ),
        if (unavailable != null)
          InfoNotice(
            title: 'Em breve',
            message: unavailable,
            icon: Icons.wb_twilight_outlined,
          )
        else
          CachedFutureBuilder<SaintOfDay?>(
            load: () => repository.forDate(today),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyState(
                  title: 'Não foi possível carregar o santo do dia',
                  message: 'Verifique a conexão e tente novamente.',
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final saint = snapshot.data;
              if (saint == null) {
                return const EmptyState(
                  title: 'Nenhum santo para hoje',
                  message: 'Volte amanhã para conhecer o próximo santo.',
                );
              }
              return _SaintBody(saint: saint);
            },
          ),
      ],
    );
  }
}

class _SaintBody extends StatelessWidget {
  const _SaintBody({required this.saint});
  final SaintOfDay saint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        saint.name,
        style: const TextStyle(fontFamily: 'serif', fontSize: 30, height: 1.1),
      ),
      if (saint.biography.isNotEmpty) ...[
        const SizedBox(height: 18),
        const Eyebrow('BIOGRAFIA'),
        const SizedBox(height: 8),
        Text(
          saint.biography,
          style: const TextStyle(fontSize: 15, height: 1.6),
        ),
      ],
      if (saint.history.isNotEmpty) ...[
        const SizedBox(height: 18),
        const Eyebrow('HISTÓRIA'),
        const SizedBox(height: 8),
        Text(saint.history, style: const TextStyle(fontSize: 15, height: 1.6)),
      ],
      if (saint.prayer.isNotEmpty) ...[
        const SizedBox(height: 18),
        const Eyebrow('ORAÇÃO'),
        const SizedBox(height: 8),
        Text(saint.prayer, style: const TextStyle(fontSize: 15, height: 1.6)),
      ],
      if (saint.sourceName.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(
          'Fonte: ${saint.sourceName}',
          style: TextStyle(color: SaintColors.muted, fontSize: 11),
        ),
      ],
    ],
  );
}
