import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'library_store.dart';

class BibleBook {
  const BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.testamentId,
    this.deuterocanonical = false,
  });

  final String id;
  final String name;
  final String abbreviation;
  final String testamentId;
  final bool deuterocanonical;
}

class BibleTestament {
  const BibleTestament({
    required this.id,
    required this.title,
    required this.books,
  });

  final String id;
  final String title;
  final List<BibleBook> books;
}

class BibleVerse {
  const BibleVerse({required this.number, required this.text});
  final int number;
  final String text;
}

/// Lista dos 73 livros do cânon católico (estrutura, sem o texto bíblico).
class BibleCanonRepository {
  BibleCanonRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/biblia_catolica_canone.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;
  List<BibleTestament>? _testaments;

  Future<List<BibleTestament>> testaments() async {
    final cached = _testaments;
    if (cached != null) return cached;
    final decoded =
        jsonDecode(await _bundle.loadString(assetPath)) as Map<String, dynamic>;
    return _testaments = List.unmodifiable(
      (decoded['testaments'] as List).map((item) {
        final json = item as Map<String, dynamic>;
        final id = json['id'] as String;
        return BibleTestament(
          id: id,
          title: json['title'] as String,
          books: List.unmodifiable(
            (json['books'] as List).map((book) {
              final data = book as Map<String, dynamic>;
              return BibleBook(
                id: data['id'] as String,
                name: data['name'] as String,
                abbreviation: data['abbreviation'] as String,
                testamentId: id,
                deuterocanonical: (data['deuterocanonical'] as bool?) ?? false,
              );
            }),
          ),
        );
      }),
    );
  }
}

/// Fonte do texto bíblico.
abstract class BibleTextSource {
  /// Explica ao usuário por que o texto não está disponível, quando for o caso.
  String? get unavailableReason;

  bool get isAvailable => unavailableReason == null;

  /// Avisa quando [unavailableReason] pode ter mudado (entrada ou saída da conta).
  Listenable get changes => Listenable.merge(const []);

  /// Capítulos que existem no texto do livro, em ordem.
  Future<List<int>> chapters(BibleBook book);

  Future<List<BibleVerse>> verses(BibleBook book, int chapter);
}

/// Usada quando não há fonte configurada (por exemplo, nos testes).
class UnavailableBibleTextSource extends BibleTextSource {
  @override
  String? get unavailableReason =>
      'O texto da Bíblia Católica ainda não está disponível.';

  @override
  Future<List<int>> chapters(BibleBook book) =>
      Future.error(StateError(unavailableReason!));

  @override
  Future<List<BibleVerse>> verses(BibleBook book, int chapter) =>
      Future.error(StateError(unavailableReason!));
}

/// Texto servido pela API (`route=bible`). A tradução não tem licença de
/// distribuição, então a API só atende contas de administrador.
class RemoteBibleTextSource extends BibleTextSource {
  RemoteBibleTextSource(this.library);

  final LibraryStore library;
  final _chapters = <String, Future<List<int>>>{};
  final _verses = <String, Future<List<BibleVerse>>>{};

  @override
  Listenable get changes => library;

  @override
  String? get unavailableReason {
    if (!library.signedIn) {
      return 'Entre em Minha conta para ler a Bíblia.';
    }
    if (!library.canReadBible) {
      return 'A leitura da Bíblia está liberada apenas para contas autorizadas.';
    }
    return null;
  }

  @override
  Future<List<int>> chapters(BibleBook book) =>
      _cached(_chapters, book.id, () async {
        final data = await library.api.request(
          'bible',
          query: {'livro': book.id},
        );
        return List<int>.unmodifiable(data['capitulos'] as List);
      });

  @override
  Future<List<BibleVerse>> verses(BibleBook book, int chapter) =>
      _cached(_verses, '${book.id}:$chapter', () async {
        final data = await library.api.request(
          'bible',
          query: {'livro': book.id, 'capitulo': '$chapter'},
        );
        return List<BibleVerse>.unmodifiable(
          (data['versiculos'] as List).map((item) {
            final json = item as Map<String, dynamic>;
            return BibleVerse(
              number: json['numero'] as int,
              text: json['texto'] as String,
            );
          }),
        );
      });

  /// Guarda o resultado para não repetir a chamada; uma falha não fica em cache.
  Future<T> _cached<T>(
    Map<String, Future<T>> cache,
    String key,
    Future<T> Function() load,
  ) {
    final cached = cache[key];
    if (cached != null) return cached;
    final future = cache[key] = load();
    future.then<void>((_) {}, onError: (Object _) => cache.remove(key));
    return future;
  }
}
