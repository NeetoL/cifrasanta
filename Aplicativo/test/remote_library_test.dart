import 'package:flutter_test/flutter_test.dart';
import 'package:cifra_santa/core/api_client.dart';
import 'package:cifra_santa/core/bible.dart';
import 'package:cifra_santa/core/catalog.dart';
import 'package:cifra_santa/core/chart_parser.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryApi extends ApiClient {
  Map<String, dynamic> catalog = {'songs': [], 'repertoires': []};
  final favorites = <String>[];
  ApiException? failure;
  String role = 'usuario';

  @override
  Future<Map<String, dynamic>> request(
    String route, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, String> query = const {},
  }) async {
    if (failure != null) throw failure!;
    return switch (route) {
      'catalog' => catalog,
      'login' || 'register' => {
        'token': 'test-session',
        'usuario': {'nome': 'Pessoa', 'papel': role},
      },
      'me' => {
        'usuario': {'nome': 'Pessoa salva', 'papel': role},
      },
      'logout' => {'ok': true},
      'favorites' => _favoriteResponse(method, data),
      'bible' when query['capitulo'] == null => {
        'capitulos': [1, 2],
      },
      'bible' => {
        'versiculos': [
          {'numero': 1, 'texto': 'No princípio...'},
        ],
      },
      _ => throw const ApiException('Rota desconhecida', 404),
    };
  }

  Map<String, dynamic> _favoriteResponse(
    String method,
    Map<String, dynamic>? data,
  ) {
    if (method == 'PUT') {
      if (data!['favorite'] == true) {
        favorites.add(data['songId'] as String);
      } else {
        favorites.remove(data['songId']);
      }
    }
    return {'favorites': List<String>.from(favorites)};
  }
}

void main() {
  setUp(() => Catalog.replace({'songs': [], 'repertoires': []}));

  test('catálogo vazio não injeta conteúdo demonstrativo', () async {
    final store = LibraryStore(api: MemoryApi());
    await store.load();
    expect(Catalog.songs, isEmpty);
    expect(Catalog.repertoires, isEmpty);
    expect(store.catalogError, isNull);
  });

  test('carrega conteúdo remoto e conserva a cifra cadastrada', () async {
    final api = MemoryApi()
      ..catalog = {
        'songs': [
          {
            'id': '12',
            'title': 'Canção de teste',
            'artist': 'Autor',
            'category': 'Entrada',
            'originalKey': 'C',
            'chart': '[C]Texto [G]original',
          },
        ],
        'repertoires': [
          {
            'id': '3',
            'title': 'Encontro',
            'subtitle': 'Hoje',
            'songIds': ['12'],
          },
        ],
      };
    await LibraryStore(api: api).load();
    expect(Catalog.song('12')!.chart, '[C]Texto [G]original');
    expect(Catalog.repertoires.single.songIds, ['12']);
  });

  test('falha de rede aparece e uma nova tentativa recupera', () async {
    final api = MemoryApi()..failure = const ApiException('Sem conexão');
    final store = LibraryStore(api: api);
    await store.load();
    expect(store.catalogError, 'Sem conexão');
    expect(store.loading, false);
    api.failure = null;
    await store.load();
    expect(store.catalogError, isNull);
  });

  test('favoritos exigem conta, sincronizam e são limpos ao sair', () async {
    final store = LibraryStore(api: MemoryApi());
    await store.toggleFavorite('12');
    expect(store.favorites, isEmpty);
    expect(store.message, contains('Minha conta'));
    expect(await store.signIn('pessoa@example.com', 'uma-senha-longa'), isNull);
    await store.toggleFavorite('12');
    expect(store.favorites, {'12'});
    await store.toggleFavorite('12');
    expect(store.favorites, isEmpty);
    await store.toggleFavorite('12');
    expect(await store.signOut(), isNull);
    expect(store.favorites, isEmpty);
    expect(store.signedIn, false);
  });

  test(
    'erro ao salvar não marca favorito e token expirado encerra sessão',
    () async {
      final api = MemoryApi();
      final store = LibraryStore(api: api);
      await store.signIn('pessoa@example.com', 'uma-senha-longa');
      api.failure = const ApiException('Sem conexão');
      await store.toggleFavorite('12');
      expect(store.favorites, isEmpty);
      expect(store.message, 'Sem conexão');
      api.failure = const ApiException('Sessão expirada', 401);
      await store.toggleFavorite('12');
      expect(store.signedIn, false);
    },
  );

  test('cifra mantém letra, baixo e estrofes na transposição', () {
    final lines = ChartParser.parse('[C]Uma [G/B]voz\n\n[Am]Outra linha', 2);
    expect(lines[0].lyric, 'Uma voz');
    expect(lines[0].chords, 'D   A/C#');
    expect(lines[1].lyric, '');
    expect(lines[2].chords, 'Bm');
    expect(lines[2].lyric, 'Outra linha');
  });

  test('seções entre colchetes não viram acordes', () {
    final line = ChartParser.parse('[Chorus]', 2).single;
    expect(line.lyric, '[Chorus]');
    expect(line.chords, isEmpty);
  });

  const genesis = BibleBook(
    id: 'gn',
    name: 'Gênesis',
    abbreviation: 'Gn',
    testamentId: 'antigo',
  );

  test('Bíblia exige conta de administrador', () async {
    final api = MemoryApi();
    final store = LibraryStore(api: api);
    final bible = RemoteBibleTextSource(store);
    expect(bible.unavailableReason, contains('Entre em Minha conta'));
    await store.signIn('pessoa@example.com', 'uma-senha-longa');
    expect(bible.unavailableReason, contains('contas autorizadas'));
    await store.signOut();
    api.role = 'admin';
    await store.signIn('admin@example.com', 'uma-senha-longa');
    expect(bible.isAvailable, isTrue);
    expect(await bible.chapters(genesis), [1, 2]);
    final verses = await bible.verses(genesis, 1);
    expect(verses.single.number, 1);
    expect(verses.single.text, 'No princípio...');
  });

  test('sessão salva é recuperada ao abrir e apagada ao sair', () async {
    SharedPreferences.setMockInitialValues({
      'session_token': 'saved',
      'session_name': 'Pessoa',
      'session_role': 'usuario',
    });
    final api = MemoryApi()..role = 'admin';
    final store = LibraryStore(api: api);
    await store.restoreSession();
    expect(store.signedIn, isTrue);
    expect(store.userName, 'Pessoa salva');
    expect(store.canReadBible, isTrue);
    await store.signOut();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('session_token'), isNull);
  });

  test('sessão salva expirada volta para o login', () async {
    SharedPreferences.setMockInitialValues({'session_token': 'expired'});
    final api = MemoryApi()
      ..failure = const ApiException('Entre na sua conta.', 401);
    final store = LibraryStore(api: api);
    await store.restoreSession();
    expect(store.signedIn, isFalse);
  });
}
