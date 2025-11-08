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
        game: SnakeGame(),
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
