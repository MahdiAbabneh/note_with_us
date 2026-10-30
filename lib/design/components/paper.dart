import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// The line height of [style], for lining paper up with the text on it.
double lineHeightOf(TextStyle style) =>
    (style.fontSize ?? 14) * (style.height ?? 1.2);

/// Draws the chosen note paper (lines, squares or dots) behind [child],
/// spaced to the text's [lineHeight]. Plain and warm paper draw nothing
/// here; warm only tints the note.
class PaperBackdrop extends StatelessWidget {
  const PaperBackdrop({
    super.key,
    required this.lineHeight,
    required this.child,
  });

  final double lineHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final paper = context.paper.paper;
    if (paper == NotePaper.plain || paper == NotePaper.warm) return child;
    return CustomPaint(
      painter: PaperPainter(
        paper: paper,
        lineHeight: lineHeight,
        color: context.colors.ink.withValues(alpha: 0.13),
      ),
      child: child,
    );
  }
}

class PaperPainter extends CustomPainter {
  PaperPainter({
    required this.paper,
    required this.lineHeight,
    required this.color,
  });

  final NotePaper paper;
  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (lineHeight < 6) return;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    final dot = Paint()..color = color.withValues(alpha: color.a * 2.2);
    // Baselines sit a little above the bottom of each line box.
    double y(int i) => lineHeight * (i + 1) - lineHeight * 0.22;
    final rows = (size.height / lineHeight).ceil() + 1;
    final cols = (size.width / lineHeight).ceil() + 1;
    switch (paper) {
      case NotePaper.ruled:
        for (var i = 0; i < rows; i++) {
          canvas.drawLine(Offset(0, y(i)), Offset(size.width, y(i)), line);
        }
      case NotePaper.grid:
        for (var i = 0; i < rows; i++) {
          canvas.drawLine(Offset(0, y(i)), Offset(size.width, y(i)), line);
        }
        for (var j = 0; j <= cols; j++) {
          final x = j * lineHeight;
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
      case NotePaper.dots:
        for (var i = 0; i < rows; i++) {
          for (var j = 0; j <= cols; j++) {
            canvas.drawCircle(Offset(j * lineHeight, y(i)), 1.2, dot);
          }
        }
      case NotePaper.plain:
      case NotePaper.warm:
        break;
    }
  }

  @override
  bool shouldRepaint(PaperPainter old) =>
      old.paper != paper || old.lineHeight != lineHeight || old.color != color;
}
