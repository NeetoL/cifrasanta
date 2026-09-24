abstract final class Chords {
  static const notes = <String>[
    'C',
    'C#',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];
  static const _enharmonic = <String, String>{
    'Db': 'C#',
    'D#': 'Eb',
    'Gb': 'F#',
    'G#': 'Ab',
    'A#': 'Bb',
    'B#': 'C',
    'Cb': 'B',
    'E#': 'F',
    'Fb': 'E',
  };

  static String shiftNote(String note, int semitones) {
    final normalized = _enharmonic[note] ?? note;
    final index = notes.indexOf(normalized);
    if (index < 0) return note;
    return notes[(index + semitones) % notes.length];
  }

  static String transpose(String chord, int semitones) {
    if (semitones == 0) return chord;
    final match = RegExp(
      r'^([A-G](?:#|b)?)([^/]*)(?:/([A-G](?:#|b)?))?$',
    ).firstMatch(chord);
    if (match == null) return chord;
    final root = shiftNote(match.group(1)!, semitones);
    final quality = match.group(2) ?? '';
    final bass = match.group(3);
    return '$root$quality${bass == null ? '' : '/${shiftNote(bass, semitones)}'}';
  }
}
