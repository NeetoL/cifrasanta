import 'chart_parser.dart';

/// Divide letra e acordes nas mesmas colunas, sem cortar um acorde ao meio.
abstract final class ChartLayout {
  static List<ChartLine> wrap(ChartLine line, int columns) {
    assert(columns > 0);
    final chords = line.chords.runes.map(String.fromCharCode).toList();
    final lyric = line.lyric.runes.map(String.fromCharCode).toList();
    final length = chords.length > lyric.length ? chords.length : lyric.length;
    if (length == 0) return [line];

    bool space(String value) => value.trim().isEmpty;
    bool boundary(List<String> text, int index) =>
        index >= text.length ||
        index == 0 ||
        space(text[index - 1]) ||
        space(text[index]);
    String slice(List<String> text, int start, int end) => start >= text.length
        ? ''
        : text.sublist(start, end < text.length ? end : text.length).join();

    final result = <ChartLine>[];
    var start = 0;
    while (start < length) {
      var end = (start + columns).clamp(0, length);
      if (end < length) {
        // Prefere terminar uma palavra, desde que isso também preserve o acorde.
        final minimum = start + (columns / 2).ceil();
        var wordEnd = end;
        while (wordEnd > minimum &&
            !(boundary(lyric, wordEnd) && boundary(chords, wordEnd))) {
          wordEnd--;
        }
        if (wordEnd > minimum) {
          end = wordEnd;
        } else if (!boundary(chords, end)) {
          var chordStart = end;
          while (chordStart > start && !boundary(chords, chordStart)) {
            chordStart--;
          }
          if (chordStart > start) {
            end = chordStart;
          } else {
            // Um único acorde maior que a largura é mantido inteiro; a UI o ajusta.
            while (end < length && !boundary(chords, end)) {
              end++;
            }
          }
        }
      }
      result.add(
        ChartLine(slice(chords, start, end), slice(lyric, start, end)),
      );
      start = end;
    }
    return result;
  }
}
