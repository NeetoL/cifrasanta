import 'package:flutter/material.dart';

import '../../core/churches.dart';
import '../components.dart';
import '../identity.dart';
import '../widgets/cards.dart';

class ChurchesScreen extends StatelessWidget {
  const ChurchesScreen({super.key, required this.repository});

  final ChurchRepository repository;

  @override
  Widget build(
    BuildContext context,
  ) => CachedFutureBuilder<List<SupportingChurch>>(
    load: () => repository.churches(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const ContentPage(
          children: [
            EmptyState(
              title: 'Não foi possível carregar as igrejas',
              message: 'Verifique a conexão e tente novamente.',
            ),
          ],
        );
      }
      final churches = snapshot.data;
      if (churches == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return ContentPage(
        children: [
          const PageHeading(
            kicker: 'COMUNIDADE',
            title: 'Igrejas Apoiadoras.',
            subtitle: 'Comunidades que caminham conosco.',
          ),
          if (churches.isEmpty)
            const EmptyState(
              title: 'Em breve, comunidades parceiras',
              message:
                  'Estamos construindo esta rede. Assim que as primeiras igrejas apoiadoras forem cadastradas, elas aparecerão aqui.',
            )
          else
            for (final church in churches)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SaintCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChurchDetailScreen(church: church),
                    ),
                  ),
                  child: Row(
                    children: [
                      const IconBadge(Icons.church_outlined),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              church.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            if (church.location.isNotEmpty)
                              Text(
                                church.location,
                                style: TextStyle(
                                  color: SaintColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      );
    },
  );
}

class ChurchDetailScreen extends StatelessWidget {
  const ChurchDetailScreen({super.key, required this.church});

  final SupportingChurch church;

  @override
  Widget build(BuildContext context) {
    final details = <(IconData, String)>[
      if (church.parish.isNotEmpty) (Icons.church_outlined, church.parish),
      if (church.diocese.isNotEmpty)
        (Icons.account_balance_outlined, church.diocese),
      if (church.address.isNotEmpty) (Icons.place_outlined, church.address),
      if (church.location.isNotEmpty)
        (Icons.location_city_outlined, church.location),
      if (church.phone.isNotEmpty) (Icons.phone_outlined, church.phone),
      if (church.website.isNotEmpty) (Icons.language_rounded, church.website),
      if (church.instagram.isNotEmpty)
        (Icons.alternate_email_rounded, church.instagram),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(church.name)),
      body: ContentPage(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 35),
        children: [
          if (church.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                church.imageUrl!,
                height: 180,
                cacheWidth: 1000,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Text(
            church.name,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              height: 1.1,
            ),
          ),
          if (church.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              church.description,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
          const SizedBox(height: 18),
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(detail.$1, size: 19, color: SaintColors.gold),
                  const SizedBox(width: 12),
                  Expanded(child: SelectableText(detail.$2)),
                ],
              ),
            ),
          if (church.massSchedules.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Eyebrow('HORÁRIOS DE MISSA'),
            const SizedBox(height: 9),
            for (final schedule in church.massSchedules)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${schedule.label}: ${schedule.times.join(', ')}'),
              ),
          ],
        ],
      ),
    );
  }
}
