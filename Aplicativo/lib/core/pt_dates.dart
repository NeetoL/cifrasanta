abstract final class PtDates {
  static const weekdays = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  static const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static String weekday(DateTime date) => weekdays[date.weekday - 1];

  static String weekdayCapitalized(DateTime date) {
    final name = weekday(date);
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  /// Ex.: "Quinta-feira, 24 de setembro".
  static String dayAndMonth(DateTime date) =>
      '${weekdayCapitalized(date)}, ${date.day} de ${months[date.month - 1]}';

  /// Ex.: "Setembro de 2026".
  static String monthAndYear(DateTime date) {
    final name = months[date.month - 1];
    return '${name[0].toUpperCase()}${name.substring(1)} de ${date.year}';
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
