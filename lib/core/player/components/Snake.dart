import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'SnakeSegment.dart';


class Snake extends PositionComponent with HasGameReference {
  static const double movementTickTimerBoundary = 0.3;

  final List<SnakeSegment> _segments = [];
  final int initialLength;
  final double cellSize; // TODO: It should not be defined here

  double _movementTickTimer = 0;

  Vector2 direction = Vector2(1, 0);
  bool isAlive = true;

  Snake({
    required Vector2 startPosition,
    this.initialLength = 6,
    this.cellSize = 20,
  }) {
    _createBody(startPosition);
  }

  void _createBody(Vector2 startPosition) {
    _segments.clear();

    for (int i = 0; i < initialLength; i++) {
      final segmentPosition = Vector2(startPosition.x - i * cellSize, startPosition.y);
      final isHead = i == 0;

      final segment = SnakeSegment(
        position: segmentPosition,
        size: Vector2.all(cellSize),
        isHead: isHead,
        color: isHead ? Colors.greenAccent : Colors.green,
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

    if (_movementTickTimer > movementTickTimerBoundary){
      _movementTickTimer = 0;
      move();
    }
  }

  Vector2 get headPosition => _segments.first.position;
}
