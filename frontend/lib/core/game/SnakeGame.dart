import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:gyro_viper/core/services/SignalRService.dart';
import 'package:gyro_viper/core/player/SnakePlayerComponent.dart';

class SnakeGame extends FlameGame {
  final SignalRService _service = SignalRService();
  final double cellSize = 20.0;
  
  late final World worldComponent;
  late final CameraComponent cameraComponent;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Vector2 _currentDirection = Vector2(1, 0);
  bool _canTurn = true;
  final double _tiltThreshold = 3.0; 

  @override
  Future<void> onLoad() async {
    worldComponent = World();
    cameraComponent = CameraComponent(world: worldComponent);
    cameraComponent.viewfinder.anchor = Anchor.center;
    
    addAll([worldComponent, cameraComponent]);

    _service.addListener(_onServerUpdate);
    _startSensorListener();
  }

  @override
  void onRemove() {
    _service.removeListener(_onServerUpdate);
    _accelSubscription?.cancel();
    super.onRemove();
  }

  void _startSensorListener() {
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (!_canTurn) return;
      double y = event.y;

      if (y > _tiltThreshold) {
        _turnRight();
      } else if (y < -_tiltThreshold) {
        _turnLeft();
      }
    });
  }

  void _turnLeft() {
    int newDx = 0;
    int newDy = 0;

    if (_currentDirection.y == -1) { newDx = -1; newDy = 0; }
    else if (_currentDirection.y == 1) { newDx = 1; newDy = 0; }
    else if (_currentDirection.x == -1) { newDx = 0; newDy = 1; }
    else if (_currentDirection.x == 1) { newDx = 0; newDy = -1; }

    _sendMove(newDx, newDy);
  }

  void _turnRight() {
    int newDx = 0;
    int newDy = 0;

    if (_currentDirection.y == -1) { newDx = 1; newDy = 0; }
    else if (_currentDirection.y == 1) { newDx = -1; newDy = 0; }
    else if (_currentDirection.x == -1) { newDx = 0; newDy = -1; }
    else if (_currentDirection.x == 1) { newDx = 0; newDy = 1; }

    _sendMove(newDx, newDy);
  }

  void _sendMove(int dx, int dy) {
    if (dx == 0 && dy == 0) return;
    if (dx == -_currentDirection.x && dy == -_currentDirection.y) return;

    _currentDirection = Vector2(dx.toDouble(), dy.toDouble());
    _service.sendInput(dx, dy);
    
    _canTurn = false;
    Future.delayed(const Duration(milliseconds: 300), () => _canTurn = true);
  }

  void _onServerUpdate() {
    final update = _service.currentGameUpdate;
    if (update == null) return;

    worldComponent.removeAll(worldComponent.children);

    final fruit = update['fruit'];
    if (fruit != null) {
      worldComponent.add(
        RectangleComponent(
          position: Vector2(fruit['x'] * cellSize, fruit['y'] * cellSize),
          size: Vector2.all(cellSize),
          paint: Paint()..color = Colors.redAccent,
        ),
      );
    }

    final players = update['players'] as List;
    for (var p in players) {
      final isMe = p['id'] == _service.socketId;
      final isAlive = p['isAlive'] as bool;
      final body = p['body'] as List;
      
      final snakeComp = SnakePlayerComponent(
        body: body, 
        isMe: isMe, 
        isAlive: isAlive, 
        cellSize: cellSize
      );
      
      snakeComp.render(worldComponent);

      if (isMe && body.isNotEmpty) {
        final head = body.first;
        final targetPos = Vector2(head['x'] * cellSize, head['y'] * cellSize);
        cameraComponent.viewfinder.position = targetPos;
      }
    }
  }
}