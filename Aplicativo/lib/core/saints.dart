class SaintOfDay {
  const SaintOfDay({
    required this.name,
    required this.date,
    this.biography = '',
    this.history = '',
    this.prayer = '',
    this.imageUrl,
    this.sourceName = '',
  });

  final String name;
  final DateTime date;
  final String biography;
  final String history;
  final String prayer;

  /// Só preencher quando a imagem tiver licença de uso.
  final String? imageUrl;
  final String sourceName;
}

/// Fonte do Santo do Dia. Implementações precisam de origem confiável e licença.
abstract class SaintRepository {
  /// Motivo de indisponibilidade quando ainda não há fonte integrada.
  String? get unavailableReason;

  Future<SaintOfDay?> forDate(DateTime date);
}

class UnavailableSaintRepository implements SaintRepository {
  const UnavailableSaintRepository();

  @override
  String? get unavailableReason =>
      'Estamos escolhendo uma fonte confiável para apresentar a vida dos '
      'santos com fidelidade. Em breve o Santo do Dia estará aqui.';

  @override
  Future<SaintOfDay?> forDate(DateTime date) async => null;
}
