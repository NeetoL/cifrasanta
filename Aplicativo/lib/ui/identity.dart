import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cores de um tema (claro ou escuro).
class SaintPalette {
  const SaintPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.panel,
    required this.line,
    required this.divider,
    required this.text,
    required this.muted,
    required this.subtle,
    required this.gold,
    required this.goldSoft,
    required this.goldBorder,
    required this.blue,
    required this.accentSurface,
    required this.accentBorder,
    required this.highlight,
    required this.highlightStrong,
    required this.chip,
    required this.chipBorder,
    required this.drawerText,
    required this.field,
    required this.fieldText,
    required this.fieldHint,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;

  /// Fundo de blocos de leitura (liturgia, cifra).
  final Color panel;
  final Color line;
  final Color divider;
  final Color text;
  final Color muted;

  /// Texto de apoio menor (legendas, contadores).
  final Color subtle;
  final Color gold;
  final Color goldSoft;
  final Color goldBorder;
  final Color blue;
  final Color accentSurface;
  final Color accentBorder;
  final Color highlight;
  final Color highlightStrong;
  final Color chip;
  final Color chipBorder;
  final Color drawerText;

  /// Campo de busca claro, usado nos dois temas.
  final Color field;
  final Color fieldText;
  final Color fieldHint;

  static const dark = SaintPalette(
    brightness: Brightness.dark,
    background: Color(0xFF111619),
    surface: Color(0xFF1B2529),
    panel: Color(0xFF182023),
    line: Color(0xFF36484D),
    divider: Color(0xFF293439),
    text: Color(0xFFF4F5F2),
    muted: Color(0xFF9CACB2),
    subtle: Color(0xFF748890),
    gold: Color(0xFFF1C76D),
    goldSoft: Color(0xFFF2D796),
    goldBorder: Color(0xFF5A5547),
    blue: Color(0xFF9BD5DF),
    accentSurface: Color(0xFF263C43),
    accentBorder: Color(0xFF45575A),
    highlight: Color(0xFF203A45),
    highlightStrong: Color(0xFF355968),
    chip: Color(0xFF232D32),
    chipBorder: Color(0xFF384B50),
    drawerText: Color(0xFFC5D0D4),
    field: Color(0xFFF3F4F2),
    fieldText: Color(0xFF24343B),
    fieldHint: Color(0xFF657880),
  );

  static const light = SaintPalette(
    brightness: Brightness.light,
    background: Color(0xFFF6F4EE),
    surface: Color(0xFFFFFFFF),
    panel: Color(0xFFFCFBF7),
    line: Color(0xFFDAD5C8),
    divider: Color(0xFFE4DFD3),
    text: Color(0xFF1C2427),
    muted: Color(0xFF55656B),
    subtle: Color(0xFF75848A),
    gold: Color(0xFF946510),
    goldSoft: Color(0xFF7E5A14),
    goldBorder: Color(0xFFD9C38F),
    blue: Color(0xFF1D6A7A),
    accentSurface: Color(0xFFE3EEF0),
    accentBorder: Color(0xFFB6CDD1),
    highlight: Color(0xFFD5E8EC),
    highlightStrong: Color(0xFFA8CCD4),
    chip: Color(0xFFEFECE4),
    chipBorder: Color(0xFFD4CEC1),
    drawerText: Color(0xFF34424A),
    field: Color(0xFFFFFFFF),
    fieldText: Color(0xFF24343B),
    fieldHint: Color(0xFF6E7F86),
  );
}

/// Cores do tema em uso. O [CifraSantaApp] troca a paleta e reconstrói as telas
/// quando o tema muda, por isso as cores não podem ser usadas em `const`.
abstract final class SaintColors {
  static SaintPalette _palette = SaintPalette.dark;

  static SaintPalette get palette => _palette;
  static void use(SaintPalette palette) => _palette = palette;

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get panel => _palette.panel;
  static Color get line => _palette.line;
  static Color get divider => _palette.divider;
  static Color get text => _palette.text;
  static Color get muted => _palette.muted;
  static Color get subtle => _palette.subtle;
  static Color get gold => _palette.gold;
  static Color get goldSoft => _palette.goldSoft;
  static Color get goldBorder => _palette.goldBorder;
  static Color get blue => _palette.blue;
  static Color get accentSurface => _palette.accentSurface;
  static Color get accentBorder => _palette.accentBorder;
  static Color get highlight => _palette.highlight;
  static Color get highlightStrong => _palette.highlightStrong;
  static Color get chip => _palette.chip;
  static Color get chipBorder => _palette.chipBorder;
  static Color get drawerText => _palette.drawerText;
  static Color get field => _palette.field;
  static Color get fieldText => _palette.fieldText;
  static Color get fieldHint => _palette.fieldHint;
}

ThemeData cifraTheme([SaintPalette palette = SaintPalette.dark]) {
  final dark = palette.brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.blue,
    brightness: palette.brightness,
    surface: palette.background,
  );
  final base = dark ? ThemeData.dark() : ThemeData.light();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    drawerTheme: DrawerThemeData(backgroundColor: palette.background),
    dividerTheme: DividerThemeData(color: palette.divider),
    textTheme: base.textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}

enum SacredSymbol { mark, church, chalice, dove, path, book }

class SacredGlyph extends StatelessWidget {
  const SacredGlyph(this.symbol, {super.key, this.size = 28, this.color});

  final SacredSymbol symbol;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _SacredPainter(symbol, color ?? SaintColors.gold),
  );
}

class _SacredPainter extends CustomPainter {
  const _SacredPainter(this.symbol, this.color);
  final SacredSymbol symbol;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    void path(List<Offset> points, {bool close = false}) {
      final shape = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        shape.lineTo(point.dx, point.dy);
      }
      if (close) shape.close();
      canvas.drawPath(shape, paint);
    }

    switch (symbol) {
      case SacredSymbol.mark:
        canvas.drawCircle(const Offset(24, 24), 19, paint);
        line(24, 11, 24, 36);
        line(15, 20, 33, 20);
        final curve = Path()
          ..moveTo(14, 37)
          ..quadraticBezierTo(24, 44, 34, 37);
        canvas.drawPath(curve, paint);
        break;
      case SacredSymbol.church:
        path([
          const Offset(8, 40),
          const Offset(8, 19),
          const Offset(24, 8),
          const Offset(40, 19),
          const Offset(40, 40),
        ], close: true);
        final door = Path()
          ..moveTo(17, 40)
          ..lineTo(17, 29)
          ..arcToPoint(const Offset(31, 29), radius: const Radius.circular(7))
          ..lineTo(31, 40);
        canvas.drawPath(door, paint);
        line(24, 12, 24, 23);
        line(18.5, 17.5, 29.5, 17.5);
        break;
      case SacredSymbol.chalice:
        canvas.drawCircle(const Offset(24, 9), 4, paint);
        line(24, 5, 24, 13);
        line(20, 9, 28, 9);
        final cup = Path()
          ..moveTo(11, 18)
          ..lineTo(37, 18)
          ..lineTo(34, 29)
          ..arcToPoint(
            const Offset(14, 29),
            radius: const Radius.circular(10),
            clockwise: false,
          )
          ..close();
        canvas.drawPath(cup, paint);
        line(24, 39, 24, 44);
        line(17, 44, 31, 44);
        break;
      case SacredSymbol.dove:
        final bird = Path()
          ..moveTo(7, 30)
          ..cubicTo(14, 29, 18, 24, 21, 17)
          ..lineTo(25, 24)
          ..lineTo(37, 20)
          ..lineTo(30, 29)
          ..lineTo(38, 35)
          ..lineTo(24, 34)
          ..cubicTo(20, 41, 12, 42, 6, 39)
          ..cubicTo(12, 38, 15, 35, 16, 32)
          ..cubicTo(12, 32, 9, 32, 7, 30)
          ..close();
        canvas.drawPath(bird, paint);
        canvas.drawCircle(const Offset(30, 23), 1, paint);
        break;
      case SacredSymbol.path:
        line(23, 7, 23, 29);
        line(14, 16, 32, 16);
        final road = Path()
          ..moveTo(10, 41)
          ..quadraticBezierTo(23, 30, 39, 34);
        canvas.drawPath(road, paint);
        line(33, 28, 39, 34);
        line(39, 34, 33, 40);
        break;
      case SacredSymbol.book:
        final book = Path()
          ..moveTo(24, 12)
          ..cubicTo(18, 8, 12, 8, 6, 10)
          ..lineTo(6, 38)
          ..cubicTo(12, 36, 18, 36, 24, 40)
          ..cubicTo(30, 36, 36, 36, 42, 38)
          ..lineTo(42, 10)
          ..cubicTo(36, 8, 30, 8, 24, 12)
          ..close();
        canvas.drawPath(book, paint);
        line(24, 12, 24, 40);
        line(24, 4, 24, 17);
        line(18, 10, 30, 10);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SacredPainter oldDelegate) =>
      oldDelegate.symbol != symbol || oldDelegate.color != color;
}
