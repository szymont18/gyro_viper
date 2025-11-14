import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:gyro_viper/core/engine/predicates/FruitGrower.dart';
import 'package:gyro_viper/core/engine/predicates/PlayersAlive.dart';
import 'package:gyro_viper/core/player/LocalPlayer.dart';
import '../board/Board.dart';
import '../player/components/Snake.dart';

class SnakeGame extends FlameGame with HasCollisionDetection {
  late Board board;
  late Snake snake;

  final int cols = 20;
  final int rows = 20;
  final double cellSize = 32.0;
  final double timeToRespawnNewFruit = 2.0;

  SnakeGame(CameraComponent camera): super(camera: camera);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // debugMode = true;

    board = Board(cols: cols, rows: rows, cellSize: cellSize);
    world.add(board);

    final startPosition = Vector2(
      cellSize * 10, cellSize * 5);

    snake = Snake(
      startPosition: startPosition,
      cellSize: cellSize,
      initialLength: 4,
    );

    world.add(snake);
    final localPlayer = LocalPlayer(snake: snake);

    add(PlayerAlive(
        players: [localPlayer],
        onPlayersNotAlive: () {
          pauseEngine();
          overlays.add('GameOverMenu');
        }));
    add(FruitGrover(period: timeToRespawnNewFruit, world: world, rows: rows, cols: cols, cellSize: cellSize));

    // Camera follow snake's head
    camera.follow(snake.head);
  }
}
