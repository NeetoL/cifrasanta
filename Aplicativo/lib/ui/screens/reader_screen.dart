import 'dart:async';
import 'fullscreen_chart_screen.dart';

import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/chords.dart';
import '../responsive_chart.dart';
import '../../core/library_store.dart';
import '../components.dart';
import '../identity.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.song, required this.library});
  final Song song;
  final LibraryStore library;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController scrollController = ScrollController();
  Timer? scrollTimer;
  int semitones = 0;
  late double fontSize;

  @override
  void initState() {
    super.initState();
    fontSize = widget.library.fontSize;
  }

  bool get scrolling => scrollTimer != null;
  String get currentKey => Chords.transpose(widget.song.originalKey, semitones);

  @override
  void dispose() {
    scrollTimer?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  void toggleScroll() {
    if (scrolling) {
      scrollTimer!.cancel();
      scrollTimer = null;
    } else {
      scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!scrollController.hasClients) return;
        final next = scrollController.offset + 1;
        if (next >= scrollController.position.maxScrollExtent) {
          scrollTimer?.cancel();
          scrollTimer = null;
          if (mounted) setState(() {});
        } else {
          scrollController.jumpTo(next);
        }
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.library,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const AppBrand(),
        actions: [
          IconButton(
            tooltip: 'Tela inteira',
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              if (scrolling) toggleScroll();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullscreenChartScreen(
                    content: widget.song.chart,
                    semitones: semitones,
                    fontSize: fontSize,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: widget.library.isFavorite(widget.song.id)
                ? 'Remover dos favoritos'
                : 'Adicionar aos favoritos',
            onPressed: () => widget.library.toggleFavorite(widget.song.id),
            icon: Icon(
              widget.library.isFavorite(widget.song.id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: widget.library.isFavorite(widget.song.id)
                  ? SaintColors.gold
                  : SaintColors.muted,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            children: [
              Eyebrow('${widget.song.category.toUpperCase()} · CIFRA SANTA'),
              const SizedBox(height: 10),
              Text(
                widget.song.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.3,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.song.artist,
                style: TextStyle(color: SaintColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _meta('Tom de referência', widget.song.originalKey),
                  _meta('Instrumento', 'Violão e guitarra'),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _stepper(
                    'Tom',
                    currentKey,
                    () => setState(() => semitones--),
                    () => setState(() => semitones++),
                  ),
                  _stepper(
                    'Texto',
                    '${fontSize.round()}',
                    () {
                      final newSize = (fontSize - 2).clamp(8.0, 28.0);
                      setState(() => fontSize = newSize);
                      widget.library.setFontSize(newSize);
                    },
                    () {
                      final newSize = (fontSize + 2).clamp(8.0, 28.0);
                      setState(() => fontSize = newSize);
                      widget.library.setFontSize(newSize);
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: toggleScroll,
                    icon: Icon(
                      scrolling
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 17,
                    ),
                    label: Text(scrolling ? 'Pausar' : 'Rolagem'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: SaintColors.highlight,
                      foregroundColor: SaintColors.text,
                      side: BorderSide(color: SaintColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      minimumSize: const Size(100, 42),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                decoration: BoxDecoration(
                  color: SaintColors.panel,
                  border: Border.all(color: SaintColors.line),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        SacredGlyph(SacredSymbol.mark, size: 17),
                        SizedBox(width: 7),
                        Eyebrow('CIFRA'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ResponsiveChart(
                      content: widget.song.chart,
                      semitones: semitones,
                      fontSize: fontSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'Conteúdo do catálogo Cifra Santa.',
                style: TextStyle(color: SaintColors.subtle, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _meta(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      border: Border.all(color: SaintColors.line),
      borderRadius: BorderRadius.circular(5),
    ),
    child: RichText(
      text: TextSpan(
        style: TextStyle(color: SaintColors.muted, fontSize: 10),
        children: [
          TextSpan(text: '$label  '),
          TextSpan(
            text: value,
            style: TextStyle(
              color: SaintColors.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _stepper(
    String label,
    String value,
    VoidCallback onDown,
    VoidCallback onUp,
  ) => Container(
    height: 42,
    padding: const EdgeInsets.only(left: 10, right: 4),
    decoration: BoxDecoration(
      color: SaintColors.highlight,
      border: Border.all(color: SaintColors.line),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 9),
        _smallButton('−', onDown),
        SizedBox(
          width: 32,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SaintColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _smallButton('+', onUp),
      ],
    ),
  );

  Widget _smallButton(String label, VoidCallback onPressed) => SizedBox(
    width: 29,
    height: 29,
    child: Material(
      color: SaintColors.highlightStrong,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(5),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ),
  );
}
