import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cifra_santa/core/catalog.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:cifra_santa/ui/components.dart';
import 'package:cifra_santa/ui/screens/library_screens.dart';

import 'remote_library_test.dart' show MemoryApi;

Map<String, dynamic> bigCatalog(int count) => {
  'songs': [
    for (var i = 0; i < count; i++)
      {
        'id': '$i',
        'title': 'Canção número $i',
        'artist': 'Autor $i',
        'category': i % 3 == 0 ? 'Oferta' : 'Comunhão',
        'originalKey': 'C',
        'chart': '[C]x',
      },
  ],
  'repertoires': [],
};

void main() {
  testWidgets('busca com 3000 cifras constrói só as linhas visíveis', (
    tester,
  ) async {
    Catalog.replace(bigCatalog(3000));
    addTearDown(() => Catalog.replace({'songs': [], 'repertoires': []}));
    final library = LibraryStore(api: MemoryApi());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            initialCategory: 'Comunhão',
            library: library,
            onSong: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(SongRow).evaluate().length, lessThan(30));
    await tester.enterText(find.byType(TextField), 'numero 2999');
    await tester.pump();
    expect(find.text('Canção número 2999'), findsOneWidget);
  });

  test('chave de busca é calculada uma vez e ignora acentos', () {
    Catalog.replace(bigCatalog(2));
    addTearDown(() => Catalog.replace({'songs': [], 'repertoires': []}));
    final song = Catalog.songs.first;
    expect(identical(song.searchKey, song.searchKey), isTrue);
    expect(song.searchKey.contains('cancao'), isTrue);
  });
}
