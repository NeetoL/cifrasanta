import 'package:flutter_test/flutter_test.dart';
import 'package:cifra_santa/core/chords.dart';

void main() {
  test('transpõe acordes com baixo sem perder a qualidade', () {
    expect(Chords.transpose('D/F#', 2), 'E/Ab');
    expect(Chords.transpose('Bm7', 2), 'C#m7');
    expect(Chords.transpose('A4', -2), 'G4');
  });

  test('mantém entradas que não são acordes', () {
    expect(Chords.transpose('Intro', 3), 'Intro');
  });
}
