import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cifra_santa/core/api_client.dart';
import 'package:cifra_santa/core/library_store.dart';
import 'remote_library_test.dart' show MemoryApi;

class FavoritesUnavailableApi extends MemoryApi {
  @override
  Future<Map<String, dynamic>> request(
    String route, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, String> query = const {},
  }) {
    if (route == 'favorites') throw const ApiException('Sem conexão', 503);
    return super.request(route, method: method, data: data, query: query);
  }
}

void main() {
  test('login permanece ativo se o carregamento de favoritos falhar', () async {
    final store = LibraryStore(api: FavoritesUnavailableApi());
    expect(await store.signIn('pessoa@example.com', 'senha-de-teste'), isNull);
    expect(store.signedIn, isTrue);
    expect(store.message, contains('Você entrou'));
  });
  test(
    'cliente envia JSON com tamanho explícito, sem transferência chunked',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final lengths = <int>[];
      final chunked = <bool>[];
      final bodies = <Map<String, dynamic>>[];
      server.listen((request) async {
        lengths.add(request.contentLength);
        chunked.add(request.headers.chunkedTransferEncoding);
        bodies.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ok': true}));
        await request.response.close();
      });
      final api = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}/api.php');
      for (final route in ['register', 'login']) {
        await api.request(
          route,
          method: 'POST',
          data: {
            'nome': 'João',
            'email': 'teste@example.com',
            'senha': 'senha-de-teste',
          },
        );
      }
      expect(lengths, everyElement(greaterThan(0)));
      expect(chunked, [false, false]);
      expect(bodies.first['nome'], 'João');
    },
  );
}
