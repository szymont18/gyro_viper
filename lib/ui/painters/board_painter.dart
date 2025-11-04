import 'package:flutter/material.dart';
import '../../core/board/Board.dart';

class BoardPainter extends CustomPainter {
  final Board board;
  final double cellSize;

  BoardPainter({required this.board, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black12;

    // draw background
    final bg = Paint()
      ..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    // optional: draw grid lines (light)
    for (int c = 0; c <= board.cols; c++) {
      final dx = c * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paintGrid);
    }
    for (int r = 0; r <= board.rows; r++) {
      final dy = r * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paintGrid);
    }

    // draw players
    for (final p in board.players) {
      if (p.body.isEmpty) continue;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = p.alive ? p.color : p.color.withOpacity(0.4);

      for (int i = 0; i < p.body.length; i++) {
        final cell = p.body[i];
        final rect = Rect.fromLTWH(
          cell.x * cellSize + 1,
          cell.y * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
      }

      // draw head highlight
      final head = p.body.first;
      final headRect = Rect.fromLTWH(
        head.x * cellSize + 1,
        head.y * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      );
      final headPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black;
      canvas.drawRRect(
          RRect.fromRectAndRadius(headRect, const Radius.circular(3)),
          headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}