import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'dart:developer' as developer;

import 'package:gyro_viper/core/board/WallBlock.dart';

class SnakeSegment extends RectangleComponent with CollisionCallbacks {
  final bool isHead;
  final Color color;

  SnakeSegment({
    required Vector2 position,
    required Vector2 size,
    required this.isHead,
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

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    developer.log("Collision!!!!"); // TODO: Implement that isAlive is changing to false
    if (_isCollisionFatal(other) && other is SnakeSegment) {}

  }

  bool _isCollisionFatal(PositionComponent other)
  {
    return isHead;
  }
}