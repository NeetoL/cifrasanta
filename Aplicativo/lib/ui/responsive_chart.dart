import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/chart_layout.dart';
import '../core/chart_parser.dart';
import 'identity.dart';

class ResponsiveChart extends StatefulWidget {
  const ResponsiveChart({
    super.key,
    required this.content,
    required this.semitones,
    required this.fontSize,
  });

  final String content;
  final int semitones;
  final double fontSize;

  @override
  State<ResponsiveChart> createState() => _ResponsiveChartState();
}

class _ResponsiveChartState extends State<ResponsiveChart> {
  // O processamento da cifra só é refeito quando algo que o afeta muda.
  late List<ChartLine> _lines = _parse();
  TextStyle? _lyricStyle;
  TextStyle? _chordStyle;
  double _cellWidth = 0;
  double? _measuredSize;
  TextScaler? _measuredScaler;
  int? _wrappedColumns;
  List<List<ChartLine>> _wrapped = const [];

  List<ChartLine> _parse() =>
      ChartParser.parse(widget.content, widget.semitones);

  @override
  void didUpdateWidget(ResponsiveChart old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content || old.semitones != widget.semitones) {
      _lines = _parse();
      _wrappedColumns = null;
    }
  }

  double _characterWidth(TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: 'MMMMMMMMMM', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width / 10;
    painter.dispose();
    return width;
  }

  void _measure(TextScaler scaler) {
    if (_measuredSize == widget.fontSize && _measuredScaler == scaler) return;
    final lyric = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: 1.45,
      color: SaintColors.text,
    );
    final chord = lyric.copyWith(
      color: SaintColors.gold,
      fontWeight: FontWeight.w800,
    );
    _lyricStyle = lyric;
    _chordStyle = chord;
    _cellWidth = math.max(
      _characterWidth(lyric, scaler),
      _characterWidth(chord, scaler),
    );
    _measuredSize = widget.fontSize;
    _measuredScaler = scaler;
    _wrappedColumns = null;
  }

  List<List<ChartLine>> _wrapFor(int columns) {
    if (_wrappedColumns != columns) {
      _wrappedColumns = columns;
      _wrapped = [
        for (final line in _lines)
          if (line.chords.isEmpty && line.lyric.isEmpty)
            const []
          else
            ChartLayout.wrap(line, columns),
      ];
    }
    return _wrapped;
  }

  @override
  Widget build(BuildContext context) {
    _measure(MediaQuery.textScalerOf(context));
    final lyricStyle = _lyricStyle!;
    final chordStyle = _chordStyle!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          1,
          ((constraints.maxWidth - 1) / _cellWidth).floor(),
        );
        final wrapped = _wrapFor(columns);
        return RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < _lines.length; index++)
                if (_lines[index].chords.isEmpty && _lines[index].lyric.isEmpty)
                  SizedBox(height: widget.fontSize * 0.8)
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final part in wrapped[index])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            // Preserva o par completo também com caracteres mais largos
                            // que a célula ou um acorde excepcionalmente comprido.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (part.chords.trim().isNotEmpty)
                                    Text(
                                      part.chords,
                                      style: chordStyle,
                                      softWrap: false,
                                    ),
                                  if (part.lyric.isNotEmpty)
                                    Text(
                                      part.lyric,
                                      style: lyricStyle,
                                      softWrap: false,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
