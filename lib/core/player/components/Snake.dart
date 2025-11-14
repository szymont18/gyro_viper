import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:gyro_viper/core/player/components/SnakeHead.dart';
import 'SnakeSegment.dart';


class Snake extends PositionComponent {
  static const double movementTickTimerBoundary = 0.2;

  final List<SnakeSegment> _segments = [];
  final int initialLength;
  final double cellSize;

  double _movementTickTimer = 0;

  Vector2 direction = Vector2(1, 0);
  bool isAlive = true;
  SnakeSegment? segmentToAdd;

  Snake({
    required Vector2 startPosition,
    this.initialLength = 6,
    this.cellSize = 20,
  }) {
    _createBody(startPosition);
  }

  void _createBody(Vector2 startPosition) {
    _segments.clear();
    // Create head
    final head = SnakeHead(
        position: startPosition,
        size: Vector2.all(cellSize),
        color: Colors.greenAccent,
        snake: this);

    _segments.add(head);

    // Create rest of the body
    for (int i = 1; i < initialLength; i++) {
      final segmentPosition = Vector2(
          startPosition.x - i * cellSize, startPosition.y);

      final segment = SnakeSegment(
        position: segmentPosition,
        size: Vector2.all(cellSize),
        color: Colors.green,
      );

      _segments.add(segment);
    }
  }

  @override
  Future<void> onLoad() async {
    for (final segment in _segments) {
      add(segment);
    }
  }

  void move() {
    if (!isAlive) return;
    final head = _segments.first;
    final newHeadPosition = head.position + direction * cellSize;
    var previousPosition = head.position.clone();

    head.position = newHeadPosition;

    for (int i = 1; i < _segments.length; i++) {
      var tmp = _segments[i].position.clone();
      _segments[i].position = previousPosition;
      previousPosition = tmp;
    }
  }

  void turnLeft() {
    direction = Vector2(-direction.y, direction.x);
  }

  void turnRight() {
    direction = Vector2(direction.y, -direction.x);
  }

  @override
  void update(double dt) {
    if (!isAlive) {
      return;
    }

    super.update(dt);
    _movementTickTimer += dt;

    if (_movementTickTimer > movementTickTimerBoundary) {
      _movementTickTimer = 0;
      move();
      actualizeBody();
    }
  }

  void actualizeBody()
  {
    print("ActualizeBody");
    if (segmentToAdd != null) {
      add(segmentToAdd!);
      _segments.add(segmentToAdd!);
      segmentToAdd = null;
    }
  }

  void grow()
  {
    print("Grow");
    var newSegment = SnakeSegment(
        position: _segments.last.position,
        size: Vector2.all(cellSize),
        color: Colors.green);

    segmentToAdd = newSegment;
  }

  Vector2 get headPosition => _segments.first.position;
  SnakeSegment get head => _segments.first;
}
