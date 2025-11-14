import 'package:flame/components.dart';
import 'package:gyro_viper/core/player/components/SnakeSegment.dart';

import 'Snake.dart';

class SnakeHead extends SnakeSegment{

  final Snake snake;

  SnakeHead({
    required super.position,
    required super.size,
    required super.color,
    required this.snake});


  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    snake.isAlive = false;
  }
}