import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Fruit extends RectangleComponent with CollisionCallbacks{

  Fruit({
    required super.position,
    required super.size,
    required super.paint})
  {
    const hitboxScale = 0.8;
    final hitboxSize = size * hitboxScale;
    final offset = Vector2(size.x - hitboxSize.x, 0);
    add(RectangleHitbox.relative(Vector2(0.8, 0.8), parentSize: size, position: offset));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // After collision with Snake
    removeFromParent();
  }

}