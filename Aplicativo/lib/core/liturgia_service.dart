import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_client.dart';
import 'liturgia.dart';

class LiturgiaService {
  LiturgiaService({this.baseUrl = 'https://liturgia.up.railway.app'});

  final String baseUrl;

  /// Busca a liturgia para uma data específica.
  /// Formato da URL: https://liturgia.up.railway.app/DD-MM-YYYY
  Future<Map<String, dynamic>> fetchLiturgiaRaw(DateTime date) async {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final datePath = '$day-$month-$year';

    final uri = Uri.parse('$baseUrl/$datePath');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final text = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(text);

        if (decoded is! Map<String, dynamic>) {
          throw const FormatException();
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            'Não foi possível obter a liturgia para a data selecionada.',
            response.statusCode,
          );
        }

        return decoded;
      })().timeout(const Duration(seconds: 20));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'O servidor da liturgia demorou para responder. Tente novamente.',
      );
    } on FormatException {
      throw const ApiException(
        'Formato de liturgia inválido retornado pelo servidor.',
      );
    } on IOException {
      throw const ApiException(
        'Não foi possível carregar a liturgia. Verifique sua conexão e tente novamente.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Liturgia> fetchLiturgia(DateTime date) async {
    final json = await fetchLiturgiaRaw(date);
    return Liturgia.fromJson(json);
  }
}
