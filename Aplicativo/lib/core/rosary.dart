import 'dart:convert';

import 'package:flutter/services.dart';

class Mystery {
  const Mystery({required this.title, this.reference = ''});

  final String title;
  final String reference;

  factory Mystery.fromJson(Map<String, dynamic> json) => Mystery(
    title: json['title'] as String,
    reference: (json['reference'] as String?) ?? '',
  );
}

class MysterySet {
  const MysterySet({
    required this.id,
    required this.title,
    required this.days,
    required this.mysteries,
  });

  final String id;
  final String title;

  /// Dias da semana em que o conjunto é rezado (DateTime.monday = 1 … sunday = 7).
  final List<int> days;
  final List<Mystery> mysteries;

  factory MysterySet.fromJson(Map<String, dynamic> json) => MysterySet(
    id: json['id'] as String,
    title: json['title'] as String,
    days: List.unmodifiable((json['days'] as List).cast<int>()),
    mysteries: List.unmodifiable(
      (json['mysteries'] as List).map(
        (item) => Mystery.fromJson(item as Map<String, dynamic>),
      ),
    ),
  );
}

enum RosaryStepKind {
  signOfTheCross,
  creed,
  ourFather,
  hailMary,
  glory,
  fatima,
  mystery,
  hailHolyQueen,
}

class RosaryStep {
  const RosaryStep({
    required this.kind,
    required this.title,
    this.prayerId,
    this.decade,
    this.mystery,
    this.count,
    this.total,
  });

  final RosaryStepKind kind;
  final String title;

  /// Oração exibida neste passo (id em oracoes.json). Nulo no anúncio do mistério.
  final String? prayerId;

  /// Dezena atual (1 a 5). Nulo na abertura e no encerramento.
  final int? decade;
  final Mystery? mystery;

  /// Contagem dentro da sequência, por exemplo Ave-Maria 3 de 10.
  final int? count;
  final int? total;
}

/// Monta o passo a passo do terço para um conjunto de mistérios.
abstract final class RosaryPlan {
  static List<RosaryStep> build(MysterySet set) {
    final steps = <RosaryStep>[
      const RosaryStep(
        kind: RosaryStepKind.signOfTheCross,
        title: 'Sinal da Cruz',
        prayerId: 'sinal-da-cruz',
      ),
      const RosaryStep(
        kind: RosaryStepKind.creed,
        title: 'Credo',
        prayerId: 'credo',
      ),
      const RosaryStep(
        kind: RosaryStepKind.ourFather,
        title: 'Pai Nosso',
        prayerId: 'pai-nosso',
      ),
      for (var i = 1; i <= 3; i++)
        RosaryStep(
          kind: RosaryStepKind.hailMary,
          title: 'Ave Maria',
          prayerId: 'ave-maria',
          count: i,
          total: 3,
        ),
      const RosaryStep(
        kind: RosaryStepKind.glory,
        title: 'Glória ao Pai',
        prayerId: 'gloria',
      ),
    ];
    for (var d = 0; d < set.mysteries.length; d++) {
      final decade = d + 1;
      steps
        ..add(
          RosaryStep(
            kind: RosaryStepKind.mystery,
            title: '$decadeº mistério',
            decade: decade,
            mystery: set.mysteries[d],
          ),
        )
        ..add(
          RosaryStep(
            kind: RosaryStepKind.ourFather,
            title: 'Pai Nosso',
            prayerId: 'pai-nosso',
            decade: decade,
            mystery: set.mysteries[d],
          ),
        );
      for (var i = 1; i <= 10; i++) {
        steps.add(
          RosaryStep(
            kind: RosaryStepKind.hailMary,
            title: 'Ave Maria',
            prayerId: 'ave-maria',
            decade: decade,
            mystery: set.mysteries[d],
            count: i,
            total: 10,
          ),
        );
      }
      steps
        ..add(
          RosaryStep(
            kind: RosaryStepKind.glory,
            title: 'Glória ao Pai',
            prayerId: 'gloria',
            decade: decade,
            mystery: set.mysteries[d],
          ),
        )
        ..add(
          RosaryStep(
            kind: RosaryStepKind.fatima,
            title: 'Ó meu Jesus',
            prayerId: 'o-meu-jesus',
            decade: decade,
            mystery: set.mysteries[d],
          ),
        );
    }
    steps.add(
      const RosaryStep(
        kind: RosaryStepKind.hailHolyQueen,
        title: 'Salve Rainha',
        prayerId: 'salve-rainha',
      ),
    );
    return List.unmodifiable(steps);
  }
}

class RosaryRepository {
  RosaryRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/terco.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;
  List<MysterySet>? _sets;

  Future<List<MysterySet>> mysterySets() async {
    final cached = _sets;
    if (cached != null) return cached;
    final decoded =
        jsonDecode(await _bundle.loadString(assetPath)) as Map<String, dynamic>;
    return _sets = List.unmodifiable(
      (decoded['mysterySets'] as List).map(
        (item) => MysterySet.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// Conjunto tradicionalmente rezado no dia informado.
  Future<MysterySet> forDay(DateTime date) async {
    final sets = await mysterySets();
    return sets.firstWhere(
      (set) => set.days.contains(date.weekday),
      orElse: () => sets.first,
    );
  }
}
