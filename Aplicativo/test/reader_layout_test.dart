import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cifra_santa/core/catalog.dart';
import 'package:cifra_santa/core/chart_layout.dart';
import 'package:cifra_santa/core/chart_parser.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:cifra_santa/ui/identity.dart';
import 'package:cifra_santa/ui/responsive_chart.dart';
import 'package:cifra_santa/ui/screens/reader_screen.dart';

const content =
    '[Intro]\n[D]  [G]  [A]\n\n'
    '[D]Esta é uma frase comprida para conferir a [G]leitura sem perder o [A7]alinhamento.\n'
    '[Bm]Outra linha tem [F#/Bb]acordes com baixo e mais palavras para acompanhar.';

void main() {
  test('quebras preservam a letra e todos os acordes, inclusive com baixo', () {
    for (final width in [1, 8, 17, 25, 40]) {
      for (final line in ChartParser.parse(content, 1)) {
        final parts = ChartLayout.wrap(line, width);
        expect(parts.map((p) => p.lyric).join(), line.lyric);
        expect(parts.map((p) => p.chords).join(), line.chords);
        final originalChords = RegExp(
          r'\S+',
        ).allMatches(line.chords).map((m) => m[0]).toList();
        final wrappedChords = parts
            .expand((p) => RegExp(r'\S+').allMatches(p.chords).map((m) => m[0]))
            .toList();
        expect(wrappedChords, originalChords);
      }
    }
  });

  for (final width in [280.0, 320.0, 390.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('cifra cabe em $width com escala de texto $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: cifraTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ResponsiveChart(
                    content: content,
                    semitones: 1,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final element in find.byType(Text).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.left, greaterThanOrEqualTo(15.9));
          expect(rect.right, lessThanOrEqualTo(width - 15.9));
        }
        for (final element in find.byType(Scrollable).evaluate()) {
          expect(
            (element.widget as Scrollable).axisDirection,
            AxisDirection.down,
          );
        }
      });
    }
  }

  testWidgets('leitor mantém rolagem vertical e não oferece arrasto lateral', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final library = LibraryStore();
    addTearDown(library.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: cifraTheme(),
        home: ReaderScreen(
          song: const Song(
            id: 'test',
            title: 'Canção de teste',
            artist: 'Autor',
            category: 'Louvor',
            originalKey: 'D',
            chart: content,
          ),
          library: library,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ResponsiveChart), findsOneWidget);
    expect(find.textContaining('Deslize a cifra'), findsNothing);
    for (final element in find.byType(Scrollable).evaluate()) {
      expect((element.widget as Scrollable).axisDirection, AxisDirection.down);
    }
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
