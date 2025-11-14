import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class SnakeSegment extends RectangleComponent with CollisionCallbacks {
  final Color color;

  SnakeSegment({
    required Vector2 position,
    required Vector2 size,
    required this.color,
  }) : super(
    position: position,
    size: size,
    paint: Paint()..color = color,
  ) {

    const hitboxScale = 0.8;
    final hitboxSize = size * hitboxScale;
    final offset = Vector2(size.x - hitboxSize.x, 0);
    add(RectangleHitbox.relative(Vector2(0.8, 0.8), parentSize: size, position: offset));
  }
}