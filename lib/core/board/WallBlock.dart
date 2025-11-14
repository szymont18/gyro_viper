import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class WallBlock extends RectangleComponent with CollisionCallbacks {
  WallBlock({
    required Vector2 position,
    required Vector2 size,
  }) : super(
    position: position,
    size: size,
    paint: Paint()..color = Colors.orange,
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
  }
}
