import 'Direction.dart';

class GridPoint {
  final int x;
  final int y;
  const GridPoint(this.x, this.y);

  GridPoint translate(Direction d, int step) {
    switch (d) {
      case Direction.up:
        return GridPoint(x, y - step);
      case Direction.down:
        return GridPoint(x, y + step);
      case Direction.left:
        return GridPoint(x - step, y);
      case Direction.right:
        return GridPoint(x + step, y);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.x == x && other.y == y;
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}