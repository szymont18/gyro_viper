

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:gyro_viper/core/board/Fruit.dart';

class FruitGrover extends TimerComponent {

  final int rows;
  final int cols;
  final double cellSize;
  final World world;

  final random = Random();

  FruitGrover({
    required period,
    required this.world,
    required this.rows,
    required this.cols,
    required this.cellSize}): super(period: period, repeat: true);

  @override
  void onTick() {
    super.onTick();
    spawnFruit();
  }

  void spawnFruit()
  {
    var fruit = Fruit(
        position: getRandomPosition(),
        size: Vector2.all(cellSize),
        paint: Paint()..color = Colors.red);

    if (!isCollideWithSth(fruit)){
      world.add(fruit);
    }
  }

  bool isCollideWithSth(Fruit fruit)
  {
    return world.children.whereType<PositionComponent>().any((other) {
      return fruit.toRect().overlaps(other.toRect());
    });
  }

  Vector2 getRandomPosition()
  {
    var col = random.nextInt(cols - 2) + 1;
    var row = random.nextInt(rows - 2) + 1;

    return Vector2(cellSize * col, cellSize * row);
  }

}