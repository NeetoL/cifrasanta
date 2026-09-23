import 'package:flutter/material.dart';

abstract final class SaintColors {
  static const background = Color(0xFF111619);
  static const surface = Color(0xFF1B2529);
  static const line = Color(0xFF36484D);
  static const text = Color(0xFFF4F5F2);
  static const muted = Color(0xFF9CACB2);
  static const gold = Color(0xFFF1C76D);
  static const blue = Color(0xFF9BD5DF);
}

ThemeData cifraTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SaintColors.blue,
    brightness: Brightness.dark,
    surface: SaintColors.background,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SaintColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: SaintColors.background,
      foregroundColor: SaintColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: SaintColors.text,
      displayColor: SaintColors.text,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}

enum SacredSymbol { mark, church, chalice, dove, path, book }

class SacredGlyph extends StatelessWidget {
  const SacredGlyph(this.symbol, {super.key, this.size = 28, this.color = SaintColors.gold});

  final SacredSymbol symbol;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _SacredPainter(symbol, color),
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
    void line(double x1, double y1, double x2, double y2) => canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    void path(List<Offset> points, {bool close = false}) {
      final shape = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) { shape.lineTo(point.dx, point.dy); }
      if (close) shape.close();
      canvas.drawPath(shape, paint);
    }

    switch (symbol) {
      case SacredSymbol.mark:
        canvas.drawCircle(const Offset(24, 24), 19, paint);
        line(24, 11, 24, 36);
        line(15, 20, 33, 20);
        final curve = Path()..moveTo(14, 37)..quadraticBezierTo(24, 44, 34, 37);
        canvas.drawPath(curve, paint);
        break;
      case SacredSymbol.church:
        path([const Offset(8, 40), const Offset(8, 19), const Offset(24, 8), const Offset(40, 19), const Offset(40, 40)], close: true);
        final door = Path()..moveTo(17, 40)..lineTo(17, 29)..arcToPoint(const Offset(31, 29), radius: const Radius.circular(7))..lineTo(31, 40);
        canvas.drawPath(door, paint);
        line(24, 12, 24, 23); line(18.5, 17.5, 29.5, 17.5);
        break;
      case SacredSymbol.chalice:
        canvas.drawCircle(const Offset(24, 9), 4, paint);
        line(24, 5, 24, 13); line(20, 9, 28, 9);
        final cup = Path()..moveTo(11, 18)..lineTo(37, 18)..lineTo(34, 29)..arcToPoint(const Offset(14, 29), radius: const Radius.circular(10), clockwise: false)..close();
        canvas.drawPath(cup, paint);
        line(24, 39, 24, 44); line(17, 44, 31, 44);
        break;
      case SacredSymbol.dove:
        final bird = Path()
          ..moveTo(7, 30)..cubicTo(14, 29, 18, 24, 21, 17)
          ..lineTo(25, 24)..lineTo(37, 20)..lineTo(30, 29)
          ..lineTo(38, 35)..lineTo(24, 34)
          ..cubicTo(20, 41, 12, 42, 6, 39)
          ..cubicTo(12, 38, 15, 35, 16, 32)
          ..cubicTo(12, 32, 9, 32, 7, 30)..close();
        canvas.drawPath(bird, paint);
        canvas.drawCircle(const Offset(30, 23), 1, paint);
        break;
      case SacredSymbol.path:
        line(23, 7, 23, 29); line(14, 16, 32, 16);
        final road = Path()..moveTo(10, 41)..quadraticBezierTo(23, 30, 39, 34);
        canvas.drawPath(road, paint);
        line(33, 28, 39, 34); line(39, 34, 33, 40);
        break;
      case SacredSymbol.book:
        final book = Path()..moveTo(24, 12)..cubicTo(18, 8, 12, 8, 6, 10)..lineTo(6, 38)..cubicTo(12, 36, 18, 36, 24, 40)..cubicTo(30, 36, 36, 36, 42, 38)..lineTo(42, 10)..cubicTo(36, 8, 30, 8, 24, 12)..close();
        canvas.drawPath(book, paint);
        line(24, 12, 24, 40); line(24, 4, 24, 17); line(18, 10, 30, 10);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SacredPainter oldDelegate) => oldDelegate.symbol != symbol || oldDelegate.color != color;
}
