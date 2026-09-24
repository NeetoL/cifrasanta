import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cifra_santa/core/catalog.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:cifra_santa/core/personal_lists.dart';
import 'package:cifra_santa/ui/screens/personal_lists_screen.dart';
import 'package:cifra_santa/ui/screens/reader_screen.dart';
import 'package:cifra_santa/ui/screens/fullscreen_chart_screen.dart';
import 'package:cifra_santa/ui/responsive_chart.dart';
import 'remote_library_test.dart' show MemoryApi;

class ListsApi extends MemoryApi {
  Completer<Map<String, dynamic>>? pending;
  int writes = 0;
  @override
  Future<Map<String, dynamic>> request(
    String route, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, String> query = const {},
  }) async {
    if (route != 'playlists') {
      return super.request(route, method: method, data: data, query: query);
    }
    if (method == 'POST') writes++;
    if (pending != null) return pending!.future;
    return {'playlists': []};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Catalog.songs = [
      const Song(
        id: '1',
        title: 'Canção A',
        artist: 'Autor',
        category: 'Entrada',
        originalKey: 'C',
        chart: '[C]Letra de exemplo',
      ),
      const Song(
        id: '2',
        title: 'Canção B',
        artist: 'Autor',
        category: 'Comunhão',
        originalKey: 'D',
        chart: '[D]Outra letra',
      ),
    ];
  });
  test(
    'listas locais persistem nome, ordem, edição e exclusão sem login',
    () async {
      final library = LibraryStore(api: ListsApi());
      final store = PersonalLists(library);
      await store.initialize();
      expect(
        await store.save(
          title: 'Missa',
          songIds: ['2', '1'],
          local: true,
          session: null,
        ),
        isNull,
      );
      final restored = PersonalLists(library);
      await restored.initialize();
      expect(restored.items.single.title, 'Missa');
      expect(restored.items.single.songIds, ['2', '1']);
      expect(
        await restored.save(
          original: restored.items.single,
          title: 'Domingo',
          songIds: ['1'],
          local: true,
          session: null,
        ),
        isNull,
      );
      expect(restored.items.single.title, 'Domingo');
      expect(await restored.delete(restored.items.single, null), isNull);
      expect(restored.items, isEmpty);
      store.dispose();
      restored.dispose();
      library.dispose();
    },
  );
  test(
    'trocar de conta bloqueia edição e descarta resposta atrasada',
    () async {
      final api = ListsApi();
      final library = LibraryStore(api: api);
      final store = PersonalLists(library);
      await store.initialize();
      await store.save(
        title: 'Local',
        songIds: ['1'],
        local: true,
        session: null,
      );
      api.pending = Completer();
      api.token = 'first';
      library.notifyListeners();
      api.token = 'second';
      library.notifyListeners();
      expect(
        await store.save(
          title: 'Privada',
          songIds: ['1'],
          local: false,
          session: 'first',
        ),
        isNotNull,
      );
      expect(api.writes, 0);
      api.token = null;
      library.notifyListeners();
      api.pending!.complete({
        'playlists': [
          {
            'id': '99',
            'title': 'Primeira conta',
            'songIds': ['1'],
            'version': 1,
          },
        ],
      });
      await Future<void>.delayed(Duration.zero);
      expect(store.items.map((p) => p.title), ['Local']);
      store.dispose();
      library.dispose();
    },
  );
  testWidgets('criar lista local escolhe músicas e salva', (tester) async {
    final library = LibraryStore(api: ListsApi());
    final store = PersonalLists(library);
    await store.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonalListsScreen(
            store: store,
            onSong: (_) {},
            onRepertoire: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Criar lista'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Minha missa');
    await tester.tap(find.text('Escolher músicas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canção B'));
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar lista'));
    await tester.pumpAndSettle();
    expect(find.text('Minhas listas'), findsOneWidget);
    expect(store.items.single.title, 'Minha missa');
    expect(store.items.single.songIds, ['2']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('tela inteira mostra só cifra e voltar, preserva tom e tamanho', (
    tester,
  ) async {
    final calls = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('cifrasanta/fullscreen'),
      (call) async {
        calls.add(call.arguments as bool);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('cifrasanta/fullscreen'),
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderScreen(song: Catalog.songs.first, library: LibraryStore()),
      ),
    );
    await tester.tap(find.text('+').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Tela inteira'));
    await tester.pumpAndSettle();
    expect(find.byType(FullscreenChartScreen), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Canção A'), findsNothing);
    expect(find.byType(IconButton), findsOneWidget);
    final chart = tester.widget<ResponsiveChart>(find.byType(ResponsiveChart));
    expect(chart.fontSize, 12);
    expect(chart.semitones, 1);
    await tester.tap(find.byTooltip('Voltar à cifra'));
    await tester.pumpAndSettle();
    expect(find.byType(FullscreenChartScreen), findsNothing);
    expect(find.text('Canção A'), findsOneWidget);
    expect(calls, [true, false]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('editor cabe com teclado aberto em celular pequeno', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final store = PersonalLists(LibraryStore(api: ListsApi()));
    await store.initialize();
    await tester.pumpWidget(MaterialApp(home: EditPersonalListScreen(store: store, onSong: (_) {})));
    await tester.enterText(find.byType(TextField), 'Celebração');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Salvar lista'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

}
