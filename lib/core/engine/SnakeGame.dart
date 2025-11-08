import 'package:flame/game.dart';
import 'package:gyro_viper/core/engine/predicates/PlayersAlive.dart';
import 'package:gyro_viper/core/player/LocalPlayer.dart';
import '../board/Board.dart';
import '../player/components/Snake.dart';

class SnakeGame extends FlameGame with HasCollisionDetection {
  late Board board;
  late Snake snake;

  final int cols = 20;
  final int rows = 15;
  final double cellSize = 32.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugMode = true;

    board = Board(cols: cols, rows: rows, cellSize: cellSize);
    add(board);

    final startPosition = Vector2(
      (cols ~/ 2) * cellSize,
      (rows ~/ 2) * cellSize,
    );

    snake = Snake(
      startPosition: startPosition,
      cellSize: cellSize,
      initialLength: 6,
    );
    add(snake);
    final localPlayer = LocalPlayer(snake: snake);

    add(PlayerAlive(
        players: [localPlayer],
        onPlayersNotAlive: () {
          pauseEngine();
          overlays.add('GameOverMenu');
        }));

    camera.viewfinder.visibleGameSize = Vector2(cols * cellSize, rows * cellSize);
    camera.viewfinder.position = Vector2(cols * cellSize / 2, rows * cellSize / 2);
  }
}
