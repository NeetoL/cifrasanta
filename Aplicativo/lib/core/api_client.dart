import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://www.englishsam.com.br/cifrasanta/api.php',
    ),
  });

  final String baseUrl;
  String? token;

  // Um único cliente reaproveita a conexão TLS entre as chamadas.
  HttpClient? _client;
  HttpClient get _http => _client ??= HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 20);

  Future<Map<String, dynamic>> request(
    String route, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, String> query = const {},
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'route': route, ...query});
    final local =
        !kReleaseMode && ['localhost', '127.0.0.1', '::1'].contains(uri.host);
    if (uri.scheme != 'https' && !(local && uri.scheme == 'http')) {
      throw const ApiException('O endereço do servidor precisa usar HTTPS.');
    }
    final client = _http;
    try {
      return await (() async {
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (token != null) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }
        if (data != null) {
          // O Mod_Security da hospedagem recusa corpo em "chunked" (HTTP 406
          // com página HTML); por isso o tamanho vai sempre informado.
          final body = utf8.encode(jsonEncode(data));
          request.headers.contentType = ContentType.json;
          request.contentLength = body.length;
          request.add(body);
        }
        final response = await request.close();
        final text = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(text);
        if (decoded is! Map<String, dynamic>) throw const FormatException();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            decoded['error'] is String
                ? decoded['error'] as String
                : 'Não foi possível concluir a solicitação.',
            response.statusCode,
          );
        }
        return decoded;
      })().timeout(const Duration(seconds: 25));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      _client?.close(force: true);
      _client = null;
      throw const ApiException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on FormatException {
      throw const ApiException(
        'O servidor não retornou os dados esperados. Tente novamente mais tarde.',
      );
    } on IOException {
      throw const ApiException(
        'Não foi possível acessar o servidor. Verifique sua conexão.',
      );
    }
  }
}
