import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/bible.dart';
import '../../core/local_favorites.dart';
import '../components.dart';
import '../identity.dart';
import '../widgets/cards.dart';

String _failure(Object? error) => error is ApiException
    ? error.message
    : 'Verifique a conexão e tente novamente.';

/// Aviso exibido enquanto a fonte não libera o texto (sem conta ou sem acesso).
class _Unavailable extends StatelessWidget {
  const _Unavailable(this.text);
  final BibleTextSource text;

  @override
  Widget build(BuildContext context) => InfoNotice(
    title: 'Leitura indisponível',
    message: text.unavailableReason!,
    icon: Icons.lock_outline_rounded,
  );
}

class BibleScreen extends StatelessWidget {
  const BibleScreen({
    super.key,
    required this.canon,
    required this.text,
    required this.favorites,
  });

  final BibleCanonRepository canon;
  final BibleTextSource text;
  final LocalFavoritesStore favorites;

  @override
  Widget build(BuildContext context) =>
      CachedFutureBuilder<List<BibleTestament>>(
        load: () => canon.testaments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ContentPage(
              children: [
                EmptyState(
                  title: 'Não foi possível abrir a Bíblia',
                  message: 'Feche o aplicativo e tente novamente.',
                ),
              ],
            );
          }
          final testaments = snapshot.data;
          if (testaments == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: text.changes,
            builder: (context, _) => ContentPage(
              children: [
                const PageHeading(
                  kicker: 'SAGRADA ESCRITURA',
                  title: 'Bíblia Católica.',
                  subtitle: 'Os 73 livros do cânon católico.',
                ),
                if (!text.isAvailable) ...[
                  _Unavailable(text),
                  const SizedBox(height: 22),
                ],
                for (final testament in testaments) ...[
                  Eyebrow(testament.title.toUpperCase()),
                  const SizedBox(height: 9),
                  for (final book in testament.books)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BookTile(
                        book: book,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BibleBookScreen(
                              book: book,
                              text: text,
                              favorites: favorites,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          );
        },
      );
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, required this.onTap});
  final BibleBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SaintCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    onTap: onTap,
    child: Row(
      children: [
        Expanded(
          child: Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
        ),
        Text(
          book.abbreviation,
          style: TextStyle(color: SaintColors.muted, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded, color: SaintColors.muted, size: 22),
      ],
    ),
  );
}

class BibleBookScreen extends StatefulWidget {
  const BibleBookScreen({
    super.key,
    required this.book,
    required this.text,
    required this.favorites,
  });

  final BibleBook book;
  final BibleTextSource text;
  final LocalFavoritesStore favorites;

  @override
  State<BibleBookScreen> createState() => _BibleBookScreenState();
}

class _BibleBookScreenState extends State<BibleBookScreen> {
  int attempt = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.book.name)),
    body: ListenableBuilder(
      listenable: widget.text.changes,
      builder: (context, _) => !widget.text.isAvailable
          ? ContentPage(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 35),
              children: [_Unavailable(widget.text)],
            )
          : CachedFutureBuilder<List<int>>(
              key: ValueKey(attempt),
              load: () => widget.text.chapters(widget.book),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ContentPage(
                    children: [
                      EmptyState(
                        title: 'Não foi possível carregar o livro',
                        message: _failure(snapshot.error),
                        action: 'Tentar novamente',
                        onAction: () => setState(() => attempt++),
                      ),
                    ],
                  );
                }
                final chapters = snapshot.data;
                if (chapters == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (chapters.isEmpty) {
                  return const ContentPage(
                    children: [
                      EmptyState(
                        title: 'Livro sem texto',
                        message:
                            'O texto deste livro ainda não foi incluído no banco.',
                      ),
                    ],
                  );
                }
                return ContentPage(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 35),
                  children: [
                    Eyebrow('${chapters.length} CAPÍTULOS'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final chapter in chapters)
                          SizedBox(
                            width: 56,
                            height: 48,
                            child: SaintCard(
                              padding: EdgeInsets.zero,
                              semanticLabel: 'Capítulo $chapter',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BibleChapterScreen(
                                    book: widget.book,
                                    chapters: chapters,
                                    chapter: chapter,
                                    text: widget.text,
                                    favorites: widget.favorites,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$chapter',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
    ),
  );
}

class BibleChapterScreen extends StatefulWidget {
  const BibleChapterScreen({
    super.key,
    required this.book,
    required this.chapters,
    required this.chapter,
    required this.text,
    required this.favorites,
  });

  final BibleBook book;
  final List<int> chapters;
  final int chapter;
  final BibleTextSource text;
  final LocalFavoritesStore favorites;

  @override
  State<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _BibleChapterScreenState extends State<BibleChapterScreen> {
  int attempt = 0;

  void _open(int chapter) => Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => BibleChapterScreen(
        book: widget.book,
        chapters: widget.chapters,
        chapter: chapter,
        text: widget.text,
        favorites: widget.favorites,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final index = widget.chapters.indexOf(widget.chapter);
    final previous = index > 0 ? widget.chapters[index - 1] : null;
    final next = index >= 0 && index < widget.chapters.length - 1
        ? widget.chapters[index + 1]
        : null;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.book.name} ${widget.chapter}')),
      body: CachedFutureBuilder<List<BibleVerse>>(
        key: ValueKey(attempt),
        load: () => widget.text.verses(widget.book, widget.chapter),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ContentPage(
              children: [
                EmptyState(
                  title: 'Não foi possível carregar o capítulo',
                  message: _failure(snapshot.error),
                  action: 'Tentar novamente',
                  onAction: () => setState(() => attempt++),
                ),
              ],
            );
          }
          final verses = snapshot.data;
          if (verses == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: widget.favorites,
            builder: (context, _) => ContentPage(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              children: [
                Eyebrow(widget.book.name.toUpperCase()),
                const SizedBox(height: 6),
                Text(
                  'Capítulo ${widget.chapter}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                for (final verse in verses)
                  _VerseTile(
                    verse: verse,
                    favorite: widget.favorites.isFavorite(
                      FavoriteKind.verse,
                      '${widget.book.id}:${widget.chapter}:${verse.number}',
                    ),
                    onFavorite: () => widget.favorites.toggle(
                      FavoriteKind.verse,
                      '${widget.book.id}:${widget.chapter}:${verse.number}',
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Toque e segure um versículo para favoritar.',
                  style: TextStyle(color: SaintColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (previous != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _open(previous),
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: Text('Capítulo $previous'),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 12),
                    if (next != null)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _open(next),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.chevron_right_rounded),
                          label: Text('Capítulo $next'),
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({
    required this.verse,
    required this.favorite,
    required this.onFavorite,
  });

  final BibleVerse verse;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => InkWell(
    onLongPress: onFavorite,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${verse.number}  ',
              style: TextStyle(
                color: SaintColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: verse.text),
            if (favorite)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: SaintColors.gold,
                  ),
                ),
              ),
          ],
        ),
        style: const TextStyle(fontSize: 16.5, height: 1.65),
      ),
    ),
  );
}
