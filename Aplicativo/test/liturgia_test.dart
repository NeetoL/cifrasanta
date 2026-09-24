import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cifra_santa/core/liturgia.dart';
import 'package:cifra_santa/core/liturgia_repository.dart';
import 'package:cifra_santa/core/liturgia_service.dart';
import 'package:cifra_santa/core/liturgia_store.dart';
import 'package:cifra_santa/ui/screens/liturgia_screen.dart';

class MockLiturgiaService extends LiturgiaService {
  MockLiturgiaService({this.mockData, this.shouldFail = false});

  Map<String, dynamic>? mockData;
  bool shouldFail;

  @override
  Future<Map<String, dynamic>> fetchLiturgiaRaw(DateTime date) async {
    if (shouldFail) {
      throw Exception('Falha de conexão ao carregar liturgia.');
    }
    return mockData ??
        {
          'data': '23/09/2026',
          'diaSemana': 'Quarta-feira',
          'liturgia': 'São Pio de Pietrelcina, presbítero, Memória',
          'tempoLiturgico': 'Tempo Comum',
          'cor': 'Verde',
          'primeiraLeitura': {
            'referencia': 'Pr 30,5-9',
            'titulo': 'Leitura do Livro dos Provérbios',
            'texto': 'Toda palavra de Deus é provada no fogo...',
          },
          'salmo': {
            'referencia': 'Sl 118(119)',
            'refrao': 'Tua palavra é lâmpada para os meus pés.',
            'texto': 'Afastai de mim o caminho da mentira...',
          },
          'segundaLeitura': 'Não há segunda leitura hoje!',
          'aclamacao': {
            'referencia': 'Mc 1,15',
            'refrao': 'Aleluia, Aleluia, Aleluia.',
            'texto': 'O Reino de Deus está próximo...',
          },
          'evangelho': {
            'referencia': 'Lc 9,1-6',
            'titulo': 'Proclamação do Evangelho de Jesus Cristo segundo Lucas',
            'texto': 'Naquele tempo, Jesus convocou os doze...',
          },
        };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Liturgia Model Parsing', () {
    test('converte JSON de dia sem segunda leitura corretamente', () {
      final json = {
        'data': '23/09/2026',
        'diaSemana': 'Quarta-feira',
        'liturgia': 'São Pio de Pietrelcina',
        'tempoLiturgico': 'Tempo Comum',
        'cor': 'Verde',
        'primeiraLeitura': {
          'referencia': 'Pr 30,5-9',
          'titulo': 'Provérbios',
          'texto': 'Texto da primeira leitura',
        },
        'salmo': {
          'referencia': 'Sl 118',
          'refrao': 'Refrão do salmo',
          'texto': 'Texto do salmo',
        },
        'segundaLeitura': 'Não há segunda leitura hoje!',
        'evangelho': {
          'referencia': 'Lc 9,1-6',
          'titulo': 'Evangelho de Lucas',
          'texto': 'Texto do evangelho',
        },
      };

      final liturgia = Liturgia.fromJson(json);

      expect(liturgia.data, '23/09/2026');
      expect(liturgia.primeiraLeitura.referencia, 'Pr 30,5-9');
      expect(liturgia.salmo.refrao, 'Refrão do salmo');
      expect(liturgia.hasSegundaLeitura, isFalse);
      expect(liturgia.evangelho.referencia, 'Lc 9,1-6');
    });

    test(
      'converte JSON de dia com segunda leitura e aclamação corretamente',
      () {
        final json = {
          'data': '25/12/2025',
          'diaSemana': 'Quinta-feira',
          'liturgia': 'Natal do Senhor',
          'tempoLiturgico': 'Tempo do Natal',
          'cor': 'Branco',
          'primeiraLeitura': {
            'referencia': 'Is 52,7-10',
            'titulo': 'Isaías',
            'texto': 'Texto Isaias',
          },
          'salmo': {
            'referencia': 'Sl 97',
            'refrao': 'Refrão Natal',
            'texto': 'Texto Salmo',
          },
          'segundaLeitura': {
            'referencia': 'Hb 1,1-6',
            'titulo': 'Hebreus',
            'texto': 'Texto Hebreus',
          },
          'aclamacao': {
            'referencia': '',
            'refrao': 'Aleluia',
            'texto': 'Aclamação do Natal',
          },
          'evangelho': {
            'referencia': 'Jo 1,1-18',
            'titulo': 'São João',
            'texto': 'Texto João',
          },
        };

        final liturgia = Liturgia.fromJson(json);

        expect(liturgia.hasSegundaLeitura, isTrue);
        expect(liturgia.segundaLeitura!.referencia, 'Hb 1,1-6');
        expect(liturgia.hasAclamacao, isTrue);
        expect(liturgia.aclamacao!.refrao, 'Aleluia');
      },
    );
  });

  group('LiturgiaRepository e Cache', () {
    test(
      'salva no cache e recupera sem consultar o serviço na segunda vez',
      () async {
        final mockService = MockLiturgiaService();
        final repo = LiturgiaRepository(service: mockService);
        final date = DateTime(2026, 9, 23);

        final result1 = await repo.getLiturgia(date);
        expect(result1.primeiraLeitura.referencia, 'Pr 30,5-9');

        // Altera o mock para falhar. Se o cache funcionar, não atinge o mock.
        mockService.shouldFail = true;
        final result2 = await repo.getLiturgia(date);
        expect(result2.primeiraLeitura.referencia, 'Pr 30,5-9');
      },
    );
  });

  group('LiturgiaScreen Widget', () {
    testWidgets('exibe leituras, salmo e evangelho corretamente', (
      tester,
    ) async {
      final mockService = MockLiturgiaService();
      final repo = LiturgiaRepository(service: mockService);
      final store = LiturgiaStore(repository: repo);

      await tester.pumpWidget(MaterialApp(home: LiturgiaScreen(store: store)));

      await tester.pumpAndSettle();

      expect(find.text('PRIMEIRA LEITURA'), findsOneWidget);
      expect(find.text('SALMO RESPONSORIAL'), findsOneWidget);
      expect(find.text('ACLAMAÇÃO AO EVANGELHO'), findsOneWidget);
      expect(find.text('EVANGELHO'), findsOneWidget);
      expect(
        find.text('SEGUNDA LEITURA'),
        findsNothing,
      ); // Não há segunda leitura neste mock
      expect(find.textContaining('Pr 30,5-9'), findsOneWidget);
      expect(find.textContaining('Lc 9,1-6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exibe estado de erro e permite tentar novamente', (
      tester,
    ) async {
      final mockService = MockLiturgiaService(shouldFail: true);
      final repo = LiturgiaRepository(service: mockService);
      final store = LiturgiaStore(repository: repo);

      await tester.pumpWidget(MaterialApp(home: LiturgiaScreen(store: store)));

      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar a liturgia'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Desativa falha do mock e tenta novamente
      mockService.shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('PRIMEIRA LEITURA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
