import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cifra_santa/core/catalog.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:cifra_santa/core/api_client.dart';
import 'package:cifra_santa/core/moments.dart';
import 'package:cifra_santa/main.dart';
import 'package:cifra_santa/ui/screens/library_screens.dart';
import 'package:cifra_santa/ui/screens/reader_screen.dart';
import 'package:cifra_santa/ui/responsive_chart.dart';
import 'remote_library_test.dart' show MemoryApi;
import 'test_support.dart';

Map<String, dynamic> sampleCatalog() => {
  'songs': [
    for (var i = 0; i < 12; i++)
      {
        'id': '$i',
        'title': 'Canção $i',
        'artist': 'Autor',
        'category': i == 0 ? 'Oferta' : 'Entrada',
        'originalKey': 'C',
        'chart': '[C]Exemplo de cifra',
      },
  ],
  'repertoires': [],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Catalog.replace(sampleCatalog());
  });

  test(
    'histórico persiste dez músicas únicas, mais recente primeiro',
    () async {
      final library = LibraryStore();
      await library.initializeHistory();
      for (final song in Catalog.songs) {
        await library.rememberSearch(song);
      }
      await library.rememberSearch(Catalog.songs[5]);
      final restored = LibraryStore();
      await restored.initializeHistory();
      expect(restored.recentSearches.map((s) => s.id), [
        '5',
        '11',
        '10',
        '9',
        '8',
        '7',
        '6',
        '4',
        '3',
        '2',
      ]);
      Catalog.songs = Catalog.songs.where((s) => s.id != '5').toList();
      expect(restored.recentSearches.length, 9);
      library.dispose();
      restored.dispose();
    },
  );

  testWidgets('busca vazia mostra histórico e pesquisa filtra catálogo', (
    tester,
  ) async {
    final library = LibraryStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            initialCategory: '',
            library: library,
            onSong: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Nenhuma busca recente'), findsOneWidget);
    expect(find.text('Canção 0'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Cancao 0');
    await tester.pumpAndSettle();
    expect(find.text('Canção 0'), findsOneWidget);
    expect(find.text('Canção 1'), findsNothing);
    await tester.tap(find.text('Canção 0'));
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Últimas músicas buscadas'), findsOneWidget);
    expect(find.text('Canção 0'), findsOneWidget);
    expect(find.text('Canção 1'), findsNothing);
  });

  testWidgets('Ofertório encontra Oferta já cadastrada', (tester) async {
    expect(Moments.matches('Envio', 'Final'), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            initialCategory: 'Ofertório',
            library: LibraryStore(),
            onSong: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Canção 0'), findsOneWidget);
    expect(find.text('Canção 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('puxar busca atualiza e preserva consulta, inclusive em falha', (
    tester,
  ) async {
    final api = MemoryApi()..catalog = sampleCatalog();
    final library = LibraryStore(api: api);
    await tester.pumpWidget(
      CifraSantaApp(library: library, services: testServices()),
    );
    await tester.pumpAndSettle();
    await goToDestination(tester, 'Cifras');
    expect(find.byTooltip('Atualizar catálogo'), findsNothing);
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'inédita');
    await tester.pumpAndSettle();
    final first = (api.catalog['songs'] as List).first as Map<String, dynamic>;
    first['title'] = 'Canção inédita';
    await tester.drag(find.byType(ListView).first, const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Canção inédita'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'inédita',
    );
    api.failure = const ApiException('Sem conexão');
    await tester.drag(find.byType(ListView).first, const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Canção inédita'), findsOneWidget);
    expect(find.text('Sem conexão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('texto inicia em 12 e respeita mínimo 8 e máximo 28', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderScreen(song: Catalog.songs.first, library: LibraryStore()),
      ),
    );
    await tester.pumpAndSettle();
    double size() =>
        tester.widget<ResponsiveChart>(find.byType(ResponsiveChart)).fontSize;
    expect(size(), 12);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('−').last);
      await tester.pump();
    }
    expect(size(), 8);
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.text('+').last);
      await tester.pump();
    }
    expect(size(), 28);
    expect(tester.takeException(), isNull);
  });

  test(
    'preferência de tamanho do texto persiste no armazenamento local',
    () async {
      final library = LibraryStore();
      await library.initializeHistory();
      expect(library.fontSize, 12.0);

      await library.setFontSize(16.0);
      expect(library.fontSize, 16.0);

      final restored = LibraryStore();
      await restored.initializeHistory();
      expect(restored.fontSize, 16.0);

      await restored.setFontSize(35.0);
      expect(restored.fontSize, 28.0);

      await restored.setFontSize(4.0);
      expect(restored.fontSize, 8.0);

      library.dispose();
      restored.dispose();
    },
  );
}
