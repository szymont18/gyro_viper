import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'WallBlock.dart';

class Board extends PositionComponent {
  final int cols;
  final int rows;
  final double cellSize;

  Board({
    required this.cols,
    required this.rows,
    required this.cellSize,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final bg = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(cols * cellSize, rows * cellSize),
      paint: Paint()..color = Colors.white,
    );
    add(bg);
    _createWalls();
  }

  void _createWalls() {
    final double width = cols * cellSize;
    final double height = rows * cellSize;

    for (int x = 0; x < cols; x++) {
      add(WallBlock(
        position: Vector2(x * cellSize, 0),
        size: Vector2(cellSize, cellSize),
      ));
      add(WallBlock(
        position: Vector2(x * cellSize, height - cellSize),
        size: Vector2(cellSize, cellSize),
      ));
    }

    for (int y = 0; y < rows; y++) {
      add(WallBlock(
        position: Vector2(0, y * cellSize),
        size: Vector2(cellSize, cellSize),
      ));
      add(WallBlock(
        position: Vector2(width - cellSize, y * cellSize),
        size: Vector2(cellSize, cellSize),
      ));
    }
  }
}
