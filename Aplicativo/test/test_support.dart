import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cifra_santa/core/app_services.dart';
import 'package:cifra_santa/core/liturgia_repository.dart';
import 'package:cifra_santa/core/liturgia_service.dart';
import 'package:cifra_santa/core/liturgia_store.dart';

/// Serviço de liturgia de teste: devolve sempre o mesmo dia, sem rede.
class FakeLiturgiaService extends LiturgiaService {
  FakeLiturgiaService({this.fail = false});

  final bool fail;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchLiturgiaRaw(DateTime date) async {
    calls++;
    if (fail) throw Exception('Falha de conexão ao carregar liturgia.');
    return {
      'data': '24/09/2026',
      'diaSemana': 'Quinta-feira',
      'liturgia': 'Quinta-feira da 25ª Semana do Tempo Comum',
      'tempoLiturgico': 'Tempo Comum',
      'cor': 'Verde',
      'primeiraLeitura': {
        'referencia': 'Ecl 1,2-11',
        'titulo': 'Leitura',
        'texto': 'Texto da primeira leitura.',
      },
      'salmo': {
        'referencia': 'Sl 89',
        'refrao': 'Senhor, vós fostes o nosso refúgio.',
        'texto': 'Texto do salmo.',
      },
      'evangelho': {
        'referencia': 'Lc 9,7-9',
        'titulo': 'Evangelho',
        'texto': 'Texto do evangelho do dia.',
      },
    };
  }
}

AppServices testServices({FakeLiturgiaService? liturgiaService}) {
  SharedPreferences.setMockInitialValues({});
  return AppServices(
    liturgia: LiturgiaStore(
      repository: LiturgiaRepository(
        service: liturgiaService ?? FakeLiturgiaService(),
      ),
    ),
  );
}

Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

/// Abre o menu lateral e escolhe um item pelo nome.
Future<void> goToDestination(WidgetTester tester, String label) async {
  await openDrawer(tester);
  final item = find.descendant(
    of: find.byType(Drawer),
    matching: find.text(label),
  );
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await settle(tester);
}

/// Aguarda a leitura real dos assets (fora do relógio falso) e estabiliza a tela.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await tester.pumpAndSettle();
}
