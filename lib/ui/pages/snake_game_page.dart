import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/engine/SnakeGame.dart';
import 'game_over.dart';

class SnakeGamePage extends StatelessWidget {
  const SnakeGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: SnakeGame(CameraComponent.withFixedResolution(width: 800, height: 450)),
        overlayBuilderMap: {
          'GameOverMenu': (_, SnakeGame game) => GameOverPage(
            onRestart: () => game.resumeEngine(),
            onExit: () => Navigator.pushNamed(context, '/'),
          ),
        },
      ),
    );
  }
}
