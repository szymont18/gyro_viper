import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SnakePlayerComponent {
  final List<dynamic> body;
  final bool isMe;
  final bool isAlive;
  final double cellSize;

  SnakePlayerComponent({
    required this.body,
    required this.isMe,
    required this.isAlive,
    required this.cellSize,
  });

  void render(World world) {
    Color color = isAlive 
        ? (isMe ? Colors.green : Colors.blue) 
        : Colors.grey.shade700;

    for (var i = 0; i < body.length; i++) {
      final segment = body[i];
      world.add(
        RectangleComponent(
          position: Vector2(segment['x'] * cellSize, segment['y'] * cellSize),
          size: Vector2.all(cellSize - 1),
          paint: Paint()..color = (i == 0 && isAlive) ? Colors.white : color,
        ),
      );
    }
  }
}