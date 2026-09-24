import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cifra_santa/core/bible.dart';
import 'package:cifra_santa/core/churches.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:cifra_santa/core/local_favorites.dart';
import 'package:cifra_santa/core/prayers.dart';
import 'package:cifra_santa/core/rosary.dart';
import 'package:cifra_santa/main.dart';
import 'package:cifra_santa/ui/identity.dart';

import 'remote_library_test.dart' show MemoryApi;
import 'test_support.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  FakeLiturgiaService? liturgia,
}) async {
  final services = testServices(liturgiaService: liturgia);
  await tester.pumpWidget(
    CifraSantaApp(
      library: LibraryStore(api: MemoryApi()),
      services: services,
    ),
  );
  await settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dados', () {
    test('o cânon tem 73 livros: 46 do AT e 27 do NT', () async {
      final testaments = await BibleCanonRepository().testaments();
      expect(testaments.length, 2);
      expect(testaments[0].books.length, 46);
      expect(testaments[1].books.length, 27);
    });

    test('orações têm as seis categorias e ids únicos', () async {
      final categories = await PrayerRepository().categories();
      expect(categories.length, 6);
      final ids = [for (final c in categories) ...c.prayers.map((p) => p.id)];
      expect(ids.toSet().length, ids.length);
      expect(await PrayerRepository().byId('pai-nosso'), isNotNull);
    });

    test('terço: todo dia tem um conjunto e o plano é completo', () async {
      final repository = RosaryRepository();
      for (var weekday = 1; weekday <= 7; weekday++) {
        final set = await repository.forDay(DateTime(2026, 9, 20 + weekday));
        expect(set.mysteries.length, 5);
        expect(set.days, contains(DateTime(2026, 9, 20 + weekday).weekday));
      }
      final plan = RosaryPlan.build(
        await repository.forDay(DateTime(2026, 9, 21)),
      );
      expect(
        plan
            .where((s) => s.kind == RosaryStepKind.hailMary && s.total == 10)
            .length,
        50,
      );
      final prayers = PrayerRepository();
      for (final step in plan.where((s) => s.prayerId != null)) {
        expect(
          await prayers.byId(step.prayerId!),
          isNotNull,
          reason: step.prayerId,
        );
      }
    });

    test('igrejas: repositório vazio e leitura de JSON', () async {
      expect(await const EmptyChurchRepository().churches(), isEmpty);
      final church = SupportingChurch.fromJson({
        'id': 1,
        'name': 'Paróquia Teste',
        'city': 'Cidade',
        'state': 'UF',
        'massSchedules': [
          {
            'label': 'Domingo',
            'times': ['08h'],
          },
        ],
      });
      expect(church.location, 'Cidade - UF');
      expect(church.massSchedules.single.times, ['08h']);
    });

    test('favoritos locais alternam e persistem', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalFavoritesStore();
      await store.initialize();
      await store.toggle(FavoriteKind.prayer, 'ave-maria');
      expect(store.isFavorite(FavoriteKind.prayer, 'ave-maria'), isTrue);
      final reloaded = LocalFavoritesStore();
      await reloaded.initialize();
      expect(reloaded.isFavorite(FavoriteKind.prayer, 'ave-maria'), isTrue);
      await reloaded.toggle(FavoriteKind.prayer, 'ave-maria');
      expect(reloaded.isFavorite(FavoriteKind.prayer, 'ave-maria'), isFalse);
    });
  });

  group('navegação', () {
    testWidgets('Início mostra a liturgia de hoje sem duplicar chamadas', (
      tester,
    ) async {
      final service = FakeLiturgiaService();
      await pumpApp(tester, liturgia: service);
      expect(find.text('LITURGIA DE HOJE'), findsOneWidget);
      expect(
        find.text('Quinta-feira da 25ª Semana do Tempo Comum'),
        findsOneWidget,
      );
      expect(find.text('Ver Liturgia Completa'), findsOneWidget);
      final before = service.calls;
      await tester.tap(find.text('Ver Liturgia Completa'));
      await tester.pumpAndSettle();
      expect(find.text('Liturgia Diária'), findsWidgets);
      expect(service.calls, before);
    });

    testWidgets('Início informa falha da liturgia e permite tentar de novo', (
      tester,
    ) async {
      await pumpApp(tester, liturgia: FakeLiturgiaService(fail: true));
      expect(
        find.text('Não foi possível carregar a liturgia de hoje.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('menu lateral lista destinos e fecha ao escolher', (
      tester,
    ) async {
      await pumpApp(tester);
      await openDrawer(tester);
      for (final label in [
        'Início',
        'Cifras',
        'Liturgia Diária',
        'Bíblia Católica',
        'Orações',
        'Santo do Dia',
        'Santo Terço',
        'Calendário Litúrgico',
        'Favoritos',
        'Igrejas Apoiadoras',
        'Sobre o Cifra Santa',
        'Configurações',
      ]) {
        expect(
          find.descendant(of: find.byType(Drawer), matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Orações'),
        ),
      );
      await settle(tester);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Orações.'), findsOneWidget);
    });

    testWidgets('voltar retorna ao Início antes de sair', (tester) async {
      await pumpApp(tester);
      await goToDestination(tester, 'Santo Terço');
      expect(find.text('Santo Terço.'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('LITURGIA DE HOJE'), findsOneWidget);
    });

    testWidgets('oração abre e pode ser favoritada', (tester) async {
      await pumpApp(tester);
      await goToDestination(tester, 'Orações');
      await tester.tap(find.text('Pai Nosso').first);
      await settle(tester);
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets(
      'Bíblia lista o cânon e avisa que o texto não está disponível',
      (tester) async {
        await pumpApp(tester);
        await goToDestination(tester, 'Bíblia Católica');
        expect(find.text('Leitura indisponível'), findsOneWidget);
        expect(find.text('Gênesis'), findsOneWidget);
        await tester.tap(find.text('Gênesis'));
        await tester.pumpAndSettle();
        expect(find.text('Leitura indisponível'), findsOneWidget);
      },
    );

    testWidgets('Santo do Dia e Igrejas mostram estados vazios honestos', (
      tester,
    ) async {
      await pumpApp(tester);
      await goToDestination(tester, 'Santo do Dia');
      expect(find.text('Em breve'), findsOneWidget);
      await goToDestination(tester, 'Igrejas Apoiadoras');
      expect(find.text('Em breve, comunidades parceiras'), findsOneWidget);
    });

    testWidgets('Configurações trocam entre tema claro e escuro', (
      tester,
    ) async {
      await pumpApp(tester);
      await goToDestination(tester, 'Configurações');
      await tester.tap(find.text('Claro'));
      await settle(tester);
      expect(SaintColors.palette, same(SaintPalette.light));
      final shell = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(
        Theme.of(tester.element(find.byWidget(shell))).brightness,
        Brightness.light,
      );
      await tester.tap(find.text('Escuro'));
      await settle(tester);
      expect(SaintColors.palette, same(SaintPalette.dark));
    });

    testWidgets('Terço avança passo a passo com contador', (tester) async {
      await pumpApp(tester);
      await goToDestination(tester, 'Santo Terço');
      await tester.tap(find.text('Começar a rezar'));
      await settle(tester);
      expect(find.text('Sinal da Cruz'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('Calendário abre a liturgia da data escolhida', (tester) async {
      await pumpApp(tester);
      await goToDestination(tester, 'Calendário Litúrgico');
      await tester.ensureVisible(find.text('Liturgia de hoje'));
      await tester.tap(find.text('Liturgia de hoje'));
      await settle(tester);
      expect(find.text('Liturgia Diária'), findsWidgets);
    });

    testWidgets('telas cabem em tela pequena e grande sem estouro', (
      tester,
    ) async {
      for (final size in const [Size(320, 568), Size(1000, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        await pumpApp(tester);
        expect(tester.takeException(), isNull, reason: 'Início $size');
        for (final label in [
          'Orações',
          'Santo Terço',
          'Bíblia Católica',
          'Calendário Litúrgico',
          'Favoritos',
          'Igrejas Apoiadoras',
          'Sobre o Cifra Santa',
          'Configurações',
        ]) {
          await goToDestination(tester, label);
          final error = tester.takeException();
          expect(
            error,
            isNull,
            reason:
                '$label $size ${error is FlutterError ? error.toStringDeep() : ''}',
          );
        }
      }
    });
  });
}
