import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:cifra_santa/core/api_client.dart';
import 'package:cifra_santa/main.dart';
import 'remote_library_test.dart' show MemoryApi;
import 'test_support.dart';

void main() {
  testWidgets('catálogo vazio permite navegar sem falhar', (tester) async {
    final library = LibraryStore(api: MemoryApi());
    await tester.pumpWidget(
      CifraSantaApp(library: library, services: testServices()),
    );
    await tester.pumpAndSettle();
    await goToDestination(tester, 'Cifras');
    expect(find.text('Seu catálogo está começando'), findsOneWidget);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Explorar cifras.'), findsOneWidget);
    await tester.tap(find.text('Listas'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum repertório publicado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra erro de rede e permite tentar novamente', (tester) async {
    final api = MemoryApi()..failure = const ApiException('Sem conexão');
    final library = LibraryStore(api: api);
    await tester.pumpWidget(
      CifraSantaApp(library: library, services: testServices()),
    );
    await tester.pumpAndSettle();
    await goToDestination(tester, 'Cifras');
    api.failure = null;
    expect(find.text('Sem conexão'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Seu catálogo está começando'), findsOneWidget);
  });

  testWidgets('repertórios não dependem da quantidade de exemplos antiga', (
    tester,
  ) async {
    final api = MemoryApi()
      ..catalog = {
        'songs': [],
        'repertoires': [
          for (var i = 0; i < 6; i++)
            {
              'id': '$i',
              'title': 'Encontro $i',
              'subtitle': 'Comunidade',
              'songIds': <String>[],
            },
        ],
      };
    await tester.pumpWidget(
      CifraSantaApp(
        library: LibraryStore(api: api),
        services: testServices(),
      ),
    );
    await tester.pumpAndSettle();
    await goToDestination(tester, 'Cifras');
    await tester.tap(find.text('Listas'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
