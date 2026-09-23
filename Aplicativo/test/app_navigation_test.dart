import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:cifra_santa/main.dart';

void main() {
  testWidgets('navega da home para a busca sem usar a web', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final library = LibraryStore();
    await library.load();
    await tester.pumpWidget(CifraSantaApp(library: library));
    expect(find.text('Músicas para você'), findsOneWidget);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Explorar cifras.'), findsOneWidget);
  });
}
