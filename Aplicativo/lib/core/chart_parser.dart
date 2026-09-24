import 'chords.dart';

class ChartLine {
  const ChartLine(this.chords, this.lyric);
  final String chords;
  final String lyric;
}

/// Acordes entre colchetes são posicionados sobre a sílaba seguinte.
abstract final class ChartParser {
  static List<ChartLine> parse(String text, int semitones) => text
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) => _line(line, semitones))
      .toList();

  static ChartLine _line(String line, int semitones) {
    final pattern = RegExp(
      r'\[([A-G](?:#|b)?(?:(?:maj|min|dim|aug|sus|add|m|M)|[0-9#b()+°º-])*(?:/[A-G](?:#|b)?)?)\]',
    );
    var lyric = '';
    var chords = '';
    var cursor = 0;
    for (final match in pattern.allMatches(line)) {
      lyric += line.substring(cursor, match.start);
      final position = lyric.runes.length;
      if (chords.length < position) chords = chords.padRight(position);
      if (chords.isNotEmpty && !chords.endsWith(' ')) chords += ' ';
      chords += Chords.transpose(match.group(1)!, semitones);
      cursor = match.end;
    }
    lyric += line.substring(cursor);
    return ChartLine(chords, lyric);
  }
}
