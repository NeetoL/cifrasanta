import 'package:flutter/material.dart';

import '../../core/prayers.dart';
import '../../core/pt_dates.dart';
import '../../core/rosary.dart';
import '../components.dart';
import '../identity.dart';
import '../widgets/cards.dart';

class RosaryScreen extends StatefulWidget {
  const RosaryScreen({super.key, required this.rosary, required this.prayers});

  final RosaryRepository rosary;
  final PrayerRepository prayers;

  @override
  State<RosaryScreen> createState() => _RosaryScreenState();
}

class _RosaryScreenState extends State<RosaryScreen> {
  late final Future<List<MysterySet>> _sets = widget.rosary.mysterySets();
  MysterySet? _selected;
  int _step = 0;
  bool _started = false;

  void _select(MysterySet set) => setState(() {
    _selected = set;
    _step = 0;
    _started = false;
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<List<MysterySet>>(
    future: _sets,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const ContentPage(
          children: [
            EmptyState(
              title: 'Não foi possível abrir o terço',
              message: 'Feche o aplicativo e tente novamente.',
            ),
          ],
        );
      }
      final sets = snapshot.data;
      if (sets == null) return const Center(child: CircularProgressIndicator());
      final today = DateTime.now();
      final set =
          _selected ??
          sets.firstWhere(
            (item) => item.days.contains(today.weekday),
            orElse: () => sets.first,
          );
      if (_started) {
        return _Guide(
          set: set,
          step: _step,
          prayers: widget.prayers,
          onStep: (value) => setState(() => _step = value),
          onExit: () => setState(() => _started = false),
        );
      }
      return ContentPage(
        children: [
          PageHeading(
            kicker: 'VIDA DE ORAÇÃO',
            title: 'Santo Terço.',
            subtitle:
                'Hoje, ${PtDates.weekday(today)}: mistérios ${_lower(set.title)}.',
          ),
          const Eyebrow('MISTÉRIOS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in sets)
                ChoiceChip(
                  label: Text(item.title),
                  selected: item.id == set.id,
                  onSelected: (_) => _select(item),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => setState(() {
              _selected = set;
              _step = 0;
              _started = true;
            }),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Começar a rezar'),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < set.mysteries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SaintCard(
                child: Row(
                  children: [
                    IconBadge(Icons.circle_outlined, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}º mistério',
                            style: TextStyle(
                              color: SaintColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            set.mysteries[i].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          if (set.mysteries[i].reference.isNotEmpty)
                            Text(
                              set.mysteries[i].reference,
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

  String _lower(String value) => value.toLowerCase();
}

class _Guide extends StatelessWidget {
  const _Guide({
    required this.set,
    required this.step,
    required this.prayers,
    required this.onStep,
    required this.onExit,
  });

  final MysterySet set;
  final int step;
  final PrayerRepository prayers;
  final ValueChanged<int> onStep;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final plan = RosaryPlan.build(set);
    final current = plan[step];
    final last = step == plan.length - 1;
    return Column(
      children: [
        Expanded(
          child: ContentPage(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Eyebrow(
                      current.decade == null
                          ? 'PASSO ${step + 1} DE ${plan.length}'
                          : '${current.decade}ª DEZENA  ·  PASSO ${step + 1} DE ${plan.length}',
                    ),
                  ),
                  TextButton(onPressed: onExit, child: const Text('Sair')),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (step + 1) / plan.length,
                minHeight: 3,
                color: SaintColors.gold,
                backgroundColor: SaintColors.line,
              ),
              const SizedBox(height: 22),
              if (current.mystery != null) ...[
                Text(
                  '${current.decade}º mistério ${_lower(set.title)}',
                  style: TextStyle(color: SaintColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  current.mystery!.title,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    color: SaintColors.goldSoft,
                  ),
                ),
                if (current.mystery!.reference.isNotEmpty)
                  Text(
                    current.mystery!.reference,
                    style: TextStyle(color: SaintColors.muted, fontSize: 12),
                  ),
                const SizedBox(height: 22),
              ],
              if (current.kind != RosaryStepKind.mystery) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        current.title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 30,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (current.count != null)
                      Text(
                        '${current.count}/${current.total}',
                        style: TextStyle(
                          color: SaintColors.gold,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (current.prayerId != null)
                  FutureBuilder<Prayer?>(
                    future: prayers.byId(current.prayerId!),
                    builder: (context, snapshot) => Text(
                      snapshot.data?.text ?? '',
                      style: const TextStyle(fontSize: 17, height: 1.7),
                    ),
                  ),
              ] else
                const Text(
                  'Contemple este mistério e reze o Pai Nosso.',
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: step == 0 ? null : () => onStep(step - 1),
                    child: const Text('Anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: last ? onExit : () => onStep(step + 1),
                    child: Text(last ? 'Concluir' : 'Próximo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _lower(String value) => value.toLowerCase();
}
