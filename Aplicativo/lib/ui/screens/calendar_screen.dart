import 'package:flutter/material.dart';

import '../../core/pt_dates.dart';
import '../components.dart';
import '../identity.dart';

/// Calendário mensal. Ao escolher um dia, a liturgia daquela data é aberta.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.onSelectDate, this.now});

  final ValueChanged<DateTime> onSelectDate;
  final DateTime? now;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  DateTime get _today => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _month = DateTime(_today.year, _today.month);
  }

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month);
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final offset = first.weekday % 7; // domingo na primeira coluna
    const headers = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 35),
      children: [
        const PageHeading(
          kicker: 'VIDA DE ORAÇÃO',
          title: 'Calendário Litúrgico.',
          subtitle: 'Escolha um dia para ver a liturgia daquela data.',
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Mês anterior',
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        PtDates.monthAndYear(_month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Próximo mês',
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final header in headers)
                      Expanded(
                        child: Center(
                          child: Text(
                            header,
                            style: TextStyle(
                              color: SaintColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: offset + days,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    if (index < offset) return const SizedBox.shrink();
                    final date = DateTime(
                      _month.year,
                      _month.month,
                      index - offset + 1,
                    );
                    final isToday = PtDates.sameDay(date, _today);
                    return Semantics(
                      button: true,
                      label: PtDates.dayAndMonth(date),
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => widget.onSelectDate(date),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: isToday
                                ? SaintColors.gold.withValues(alpha: .16)
                                : SaintColors.surface,
                            border: Border.all(
                              color: isToday
                                  ? SaintColors.gold
                                  : SaintColors.line,
                            ),
                          ),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isToday
                                  ? SaintColors.gold
                                  : SaintColors.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => widget.onSelectDate(_today),
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: const Text('Liturgia de hoje'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
